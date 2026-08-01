import { writeSync } from "node:fs";
import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import { SessionManager } from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

type TimeRange = "all" | "30d" | "7d" | "1d";

const RANGES: readonly { key: TimeRange; label: string; days?: number }[] = [
	{ key: "all", label: "All time" },
	{ key: "30d", label: "30 days", days: 30 },
	{ key: "7d", label: "7 days", days: 7 },
	{ key: "1d", label: "1 day", days: 1 },
];

type UsageLike = {
	input?: number;
	output?: number;
	cacheRead?: number;
	cacheWrite?: number;
	cost?: { total?: number };
};

type EntryLike = {
	type: string;
	timestamp?: string;
	usage?: UsageLike;
	message?: {
		role?: string;
		timestamp?: number;
		usage?: UsageLike;
	};
};

interface PiStats {
	sessions: number;
	messages: number;
	daysActive: number;
	cost: number;
	tokens: number;
}

function startOfLocalDay(now: Date): Date {
	return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

function rangeStart(range: (typeof RANGES)[number], now: Date): number | undefined {
	if (!range.days) return undefined;
	const start = startOfLocalDay(now);
	start.setDate(start.getDate() - range.days + 1);
	return start.getTime();
}

function timestampOf(entry: EntryLike): number | undefined {
	if (entry.timestamp) {
		const parsed = Date.parse(entry.timestamp);
		if (Number.isFinite(parsed)) return parsed;
	}
	if (typeof entry.message?.timestamp === "number" && Number.isFinite(entry.message.timestamp)) {
		return entry.message.timestamp;
	}
	return undefined;
}

function isInRange(timestamp: number | undefined, start: number | undefined, end: number): boolean {
	return start === undefined || (timestamp !== undefined && timestamp >= start && timestamp <= end);
}

function addUsage(stats: { cost: number; tokens: number }, usage: UsageLike | undefined): void {
	if (!usage) return;
	const tokenParts = [usage.input, usage.output, usage.cacheRead, usage.cacheWrite];
	stats.tokens += tokenParts.reduce((total, value) => total + (typeof value === "number" && Number.isFinite(value) ? value : 0), 0);
	if (typeof usage.cost?.total === "number" && Number.isFinite(usage.cost.total)) {
		stats.cost += usage.cost.total;
	}
}

function calculateStats(sessions: Array<{ path: string }>, range: (typeof RANGES)[number], now: Date): PiStats {
	const start = rangeStart(range, now);
	const end = now.getTime();
	let sessionCount = 0;
	let messages = 0;
	const totals = { cost: 0, tokens: 0 };
	const activeDays = new Set<string>();

	for (const session of sessions) {
		let entries: EntryLike[];
		try {
			entries = SessionManager.open(session.path).getEntries() as EntryLike[];
		} catch {
			// A session can be deleted or still being written while the stats pane opens.
			continue;
		}

		let hasMessageInRange = false;
		for (const entry of entries) {
			const timestamp = timestampOf(entry);
			const inRange = isInRange(timestamp, start, end);

			if (entry.type === "message" && entry.message) {
				if (inRange) {
					messages++;
					hasMessageInRange = true;
					if (timestamp !== undefined) {
						activeDays.add(new Date(timestamp).toLocaleDateString());
					}
				}

				if (inRange && entry.message.role === "assistant") addUsage(totals, entry.message.usage);
				if (inRange && entry.message.role === "toolResult") addUsage(totals, entry.message.usage);
			} else if (inRange && (entry.type === "compaction" || entry.type === "branch_summary")) {
				addUsage(totals, entry.usage);
			}
		}

		if (hasMessageInRange) sessionCount++;
	}

	return {
		sessions: sessionCount,
		messages,
		daysActive: activeDays.size,
		cost: totals.cost,
		tokens: totals.tokens,
	};
}

function formatCount(value: number): string {
	return Math.round(value).toLocaleString();
}

function formatCost(value: number): string {
	return `$${value.toFixed(3)}`;
}

function formatCliStats(stats: ReadonlyMap<TimeRange, PiStats>): string {
	const lines = ["PI Stats", ""];

	for (const range of RANGES) {
		const values = stats.get(range.key) ?? { sessions: 0, messages: 0, daysActive: 0, cost: 0, tokens: 0 };
		const averageCostPerDay = values.daysActive > 0 ? values.cost / values.daysActive : 0;
		const averageTokensPerSession = values.sessions > 0 ? values.tokens / values.sessions : 0;

		lines.push(
			range.label,
			`  Sessions: ${formatCount(values.sessions)}`,
			`  Messages: ${formatCount(values.messages)}`,
			`  Days active: ${formatCount(values.daysActive)}`,
			`  Cost: ${formatCost(values.cost)} total · ${formatCost(averageCostPerDay)}/day`,
			`  Tokens: ${formatCount(values.tokens)} total · ${formatCount(averageTokensPerSession)}/session`,
			"",
		);
	}

	return lines.join("\n");
}

function formatTab(label: string, selected: boolean, theme: Theme): string {
	return selected ? theme.bold(theme.fg("accent", `[ ${label} ]`)) : theme.fg("muted", `  ${label}  `);
}

class StatsPanel {
	private selectedRange = 0;

	constructor(
		private readonly stats: ReadonlyMap<TimeRange, PiStats>,
		private readonly theme: Theme,
		private readonly requestRender: () => void,
		private readonly done: () => void,
	) {}

	handleInput(data: string): void {
		if (matchesKey(data, Key.escape) || matchesKey(data, Key.ctrl("c"))) {
			this.done();
			return;
		}

		if (matchesKey(data, Key.left) || matchesKey(data, Key.up)) {
			this.selectedRange = Math.max(0, this.selectedRange - 1);
			this.requestRender();
			return;
		}
		if (matchesKey(data, Key.right) || matchesKey(data, Key.down)) {
			this.selectedRange = Math.min(RANGES.length - 1, this.selectedRange + 1);
			this.requestRender();
			return;
		}

		const number = Number(data);
		if (number >= 1 && number <= RANGES.length && Number.isInteger(number)) {
			this.selectedRange = number - 1;
			this.requestRender();
		}
	}

	render(width: number): string[] {
		const theme = this.theme;
		const innerWidth = Math.max(24, width - 2);
		const currentRange = RANGES[this.selectedRange]!;
		const stats = this.stats.get(currentRange.key) ?? { sessions: 0, messages: 0, daysActive: 0, cost: 0, tokens: 0 };
		const averageCostPerDay = stats.daysActive > 0 ? stats.cost / stats.daysActive : 0;
		const averageTokensPerSession = stats.sessions > 0 ? stats.tokens / stats.sessions : 0;

		const fit = (text: string): string => {
			const fitted = truncateToWidth(text, innerWidth, "");
			return fitted + " ".repeat(Math.max(0, innerWidth - visibleWidth(fitted)));
		};
		const row = (text = ""): string => theme.fg("border", "│") + fit(text) + theme.fg("border", "│");
		const border = (left: string, right: string): string => theme.fg("border", `${left}${"─".repeat(innerWidth)}${right}`);
		const metric = (label: string, value: string): string =>
			row(`  ${theme.fg("muted", label.padEnd(18))}${theme.fg("text", value)}`);

		const tabs = RANGES.map((range, index) => formatTab(range.label, index === this.selectedRange, theme)).join("");
		return [
			border("╭", "╮"),
			row(`  ${theme.bold(theme.fg("accent", "PI Stats"))}`),
			row(`  ${theme.fg("dim", "Time range")}  ${tabs}`),
			row(),
			metric("Sessions", formatCount(stats.sessions)),
			metric("Messages", formatCount(stats.messages)),
			metric("Days active", formatCount(stats.daysActive)),
			row(),
			metric("Cost", `${formatCost(stats.cost)} total  ·  ${formatCost(averageCostPerDay)}/day`),
			metric("Tokens", `${formatCount(stats.tokens)} total  ·  ${formatCount(averageTokensPerSession)}/session`),
			row(),
			row(`  ${theme.fg("dim", "←/→ choose range · 1–4 jump · Esc close")}`),
			border("╰", "╯"),
		];
	}

	invalidate(): void {}
}

async function loadSessions(currentSessionPath?: string): Promise<Array<{ path: string }>> {
	const listed = await SessionManager.listAll();
	const paths = new Set(listed.map((session) => session.path));
	if (currentSessionPath) paths.add(currentSessionPath);
	return [...paths].map((path) => ({ path }));
}

function calculateAllStats(sessions: Array<{ path: string }>, now: Date): Map<TimeRange, PiStats> {
	return new Map(RANGES.map((range) => [range.key, calculateStats(sessions, range, now)]));
}

function isCliStatsInvocation(): boolean {
	const args = process.argv.slice(2);
	return args.some((arg) => arg === "--stats" || arg.startsWith("--stats=")) || args[0] === "stats";
}

function writeCliOutput(stream: 1 | 2, text: string): void {
	writeSync(stream, `${text}\n`);
}

async function runCliStats(): Promise<never> {
	try {
		const stats = calculateAllStats(await loadSessions(), new Date());
		writeCliOutput(1, formatCliStats(stats));
		process.exit(0);
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		writeCliOutput(2, `Could not load Pi stats: ${message}`);
		process.exit(1);
	}
}

export default async function piStatsExtension(pi: ExtensionAPI): Promise<void> {
	pi.registerFlag("stats", {
		description: "Print aggregate Pi usage statistics and exit without opening the UI",
		type: "boolean",
	});

	// Pi's extension API currently exposes CLI flags, but not top-level subcommands.
	// Support both the conventional --stats flag and the requested `pi stats` form.
	if (isCliStatsInvocation()) await runCliStats();

	pi.registerCommand("stats", {
		description: "Show aggregate Pi usage statistics",
		handler: async (_args, ctx) => {
			if (ctx.mode !== "tui") {
				ctx.ui.notify("The stats pane requires TUI mode", "error");
				return;
			}

			try {
				const sessions = await loadSessions(ctx.sessionManager.getSessionFile());
				const stats = calculateAllStats(sessions, new Date());

				await ctx.ui.custom<void>((tui, theme, _keybindings, done) =>
					new StatsPanel(stats, theme, () => tui.requestRender(), () => done()),
					{
						overlay: true,
						overlayOptions: {
							anchor: "center",
							width: "70%",
							minWidth: 58,
							maxHeight: "80%",
							margin: 1,
						},
					},
				);
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				ctx.ui.notify(`Could not load Pi stats: ${message}`, "error");
			}
		},
	});
}
