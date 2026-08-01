/**
 * Model footer and git context
 *
 * Shows the active model, thinking level, context/cost information, current
 * directory, and git status in Pi's footer. The prompt editor is also given a
 * wider layout with a bold border.
 */

import { basename } from "node:path";
import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
	type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import type { EditorTheme, TUI } from "@earendil-works/pi-tui";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const GIT_STATUS_ID = "git-context";
const GIT_REFRESH_INTERVAL_MS = 2_000;

type GitContext = {
	branch: string;
	worktree: string;
};

async function gitOutput(pi: ExtensionAPI, cwd: string, args: string[]): Promise<string | undefined> {
	try {
		const result = await pi.exec("git", args, { cwd, timeout: 3_000 });
		if (result.code !== 0) return undefined;

		const output = result.stdout.trim();
		return output || undefined;
	} catch {
		return undefined;
	}
}

async function readGitContext(pi: ExtensionAPI, cwd: string): Promise<GitContext | undefined> {
	const [root, branch, commit] = await Promise.all([
		gitOutput(pi, cwd, ["rev-parse", "--show-toplevel"]),
		gitOutput(pi, cwd, ["symbolic-ref", "--quiet", "--short", "HEAD"]),
		gitOutput(pi, cwd, ["rev-parse", "--short", "HEAD"]),
	]);

	if (!root) return undefined;

	return {
		branch: branch ?? (commit ? `detached @ ${commit}` : "detached HEAD"),
		worktree: basename(root) || root,
	};
}

function renderGitStatus(ctx: ExtensionContext, value: GitContext | undefined): void {
	if (!value) {
		ctx.ui.setStatus(GIT_STATUS_ID, undefined);
		return;
	}

	const theme = ctx.ui.theme;
	const branch = theme.fg("success", `branch: ${value.branch}`);
	const worktree = theme.fg("accent", `worktree: ${value.worktree}`);

	ctx.ui.setStatus(GIT_STATUS_ID, `${branch} ${theme.fg("dim", "·")} ${worktree}`);
}

type UsageLike = {
	cost?: {
		total?: number;
	};
};

type EntryLike = {
	type: string;
	message?: {
		usage?: UsageLike;
	};
	usage?: UsageLike;
};

function formatTokens(tokens: number): string {
	if (tokens < 1_000) return String(tokens);
	if (tokens < 10_000) return `${(tokens / 1_000).toFixed(1)}k`;
	if (tokens < 1_000_000) return `${Math.round(tokens / 1_000)}k`;
	if (tokens < 10_000_000) return `${(tokens / 1_000_000).toFixed(1)}M`;
	return `${Math.round(tokens / 1_000_000)}M`;
}

function formatCwd(cwd: string): string {
	const home = process.env.HOME ?? process.env.USERPROFILE;
	if (home && (cwd === home || cwd.startsWith(`${home}/`))) {
		return `~${cwd.slice(home.length)}`;
	}
	return cwd;
}

function getSessionCost(ctx: ExtensionContext): number {
	let cost = 0;

	for (const rawEntry of ctx.sessionManager.getEntries()) {
		const entry = rawEntry as EntryLike;
		const usage = entry.type === "message" ? entry.message?.usage : entry.usage;
		const total = usage?.cost?.total;
		if (typeof total === "number" && Number.isFinite(total)) cost += total;
	}

	return cost;
}

function fitLine(left: string, right: string, width: number): string {
	if (width <= 0) return "";

	const gap = 2;
	const availableForLeft = Math.max(0, width - visibleWidth(right) - gap);
	const fittedLeft = truncateToWidth(left, availableForLeft, "");
	const remaining = Math.max(0, width - visibleWidth(fittedLeft) - visibleWidth(right));
	return truncateToWidth(`${fittedLeft}${" ".repeat(remaining)}${right}`, width, "");
}

function stripAnsiForLayout(text: string): string {
	return text
		.replace(/\x1b\][^\x07]*(?:\x07|\x1b\\)/g, "")
		.replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "");
}

function isEditorBorderLine(text: string): boolean {
	const plain = stripAnsiForLayout(text).trim();
	return /^─+$/.test(plain) || /^─{3} [↑↓] \d+ more /.test(plain);
}

class MarginedEditor extends CustomEditor {
	private readonly fixedBorder: (text: string) => string;

	constructor(
		tui: TUI,
		theme: EditorTheme,
		keybindings: KeybindingsManager,
		fixedBorder: (text: string) => string,
	) {
		super(tui, theme, keybindings, { paddingX: 0 });
		this.fixedBorder = fixedBorder;
	}

	render(width: number): string[] {
		if (width < 3) {
			this.borderColor = this.fixedBorder;
			return super.render(Math.max(1, width));
		}

		// Leave two terminal columns on both sides, then reserve one column
		// for each closed vertical edge of the prompt box.
		const margin = Math.min(2, Math.floor((width - 3) / 2));
		const insideWidth = Math.max(1, width - margin * 2 - 2);
		const padding = " ".repeat(margin);

		// Pi normally replaces this border with a thinking-level color. Set it
		// immediately before rendering so the prompt bar always stays bold.
		this.borderColor = this.fixedBorder;
		const lines = super.render(insideWidth);
		if (lines.length === 0) return lines;

		let bottomIndex = lines.length - 1;
		if (this.isShowingAutocomplete()) {
			const detectedBottom = lines.findIndex((line, index) => index > 0 && isEditorBorderLine(line));
			if (detectedBottom >= 0) bottomIndex = detectedBottom;
		}

		const border = (text: string) => this.fixedBorder(text);
		// Unicode has no heavy rounded-corner glyphs, so use the matching heavy
		// box-drawing corners to keep every border segment the same thickness.
		const top = `${padding}${border(`┏${"━".repeat(insideWidth)}┓`)}${padding}`;
		const bottom = `${padding}${border(`┗${"━".repeat(insideWidth)}┛`)}${padding}`;

		return lines.map((line, index) => {
			if (index === 0) return top;
			if (index === bottomIndex) return bottom;
			if (index > bottomIndex) return `${padding}${line}${padding}`;
			return `${padding}${border("┃")}${line}${border("┃")}${padding}`;
		});
	}
}

function renderFooter(
	ctx: ExtensionContext,
	theme: ExtensionContext["ui"]["theme"],
	footerData: Readonly<{
		getExtensionStatuses(): ReadonlyMap<string, string>;
	}>,
	width: number,
): string[] {
	if (width <= 0) return [];

	// Keep the footer's outer spacing aligned with the prompt bar.
	const margin = Math.min(2, Math.max(0, Math.floor((width - 3) / 2)));
	const contentWidth = width - margin * 2;
	const padding = " ".repeat(margin);

	const model = ctx.model;
	const modelName = model?.id ?? "no-model";
	const thinking = ctx.thinkingLevel ?? "off";

	// Keep each part separately styled so the model remains white, while the
	// provider and separator stay gray and the thinking level stays purple.
	const modelLine =
		theme.fg("text", modelName) +
		theme.fg("muted", model ? ` (${model.provider}) · ` : " · ") +
		theme.fg("thinkingHigh", thinking);

	const contextUsage = ctx.getContextUsage();
	const contextWindow = contextUsage?.contextWindow ?? model?.contextWindow ?? 0;
	const currentContext =
		contextUsage?.tokens === null || contextUsage === undefined
			? "?"
			: formatTokens(contextUsage.tokens);
	const contextPercentage =
		contextUsage?.percent === null || contextUsage === undefined
			? "?"
			: `${contextUsage.percent.toFixed(1)}%`;
	const rightLine = theme.fg(
		"dim",
		`${currentContext}/${formatTokens(contextWindow)} (${contextPercentage}) · $${getSessionCost(ctx).toFixed(3)}`,
	);

	const cwd = theme.fg("dim", formatCwd(ctx.cwd));

	const statusLines = [...footerData.getExtensionStatuses().entries()]
		.sort(([left], [right]) => left.localeCompare(right))
		.map(([, status]) => status.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim())
		.filter(Boolean)
		.map((status) => truncateToWidth(status, contentWidth, theme.fg("dim", "...")));

	return [
		fitLine(modelLine, rightLine, contentWidth),
		truncateToWidth(cwd, contentWidth, ""),
		...statusLines,
	].map((line) => `${padding}${truncateToWidth(line, contentWidth, "")}${padding}`);
}

export default function (pi: ExtensionAPI): void {
	let refreshTimer: ReturnType<typeof setInterval> | undefined;
	let refreshInFlight = false;
	let gitStatusActive = false;
	let currentContext: ExtensionContext | undefined;
	let activeTui: { requestRender(): void } | undefined;

	const refreshGitStatus = async (): Promise<void> => {
		if (!gitStatusActive || refreshInFlight || !currentContext) return;

		refreshInFlight = true;
		const ctx = currentContext;
		try {
			const value = await readGitContext(pi, ctx.cwd);
			if (gitStatusActive && currentContext === ctx) {
				renderGitStatus(ctx, value);
			}
		} finally {
			refreshInFlight = false;
		}
	};

	const stopGitStatus = (ctx: ExtensionContext): void => {
		gitStatusActive = false;
		currentContext = undefined;
		if (refreshTimer) {
			clearInterval(refreshTimer);
			refreshTimer = undefined;
		}
		ctx.ui.setStatus(GIT_STATUS_ID, undefined);
	};

	pi.on("session_start", async (_event, ctx) => {
		if (ctx.hasUI) {
			gitStatusActive = true;
			currentContext = ctx;
			if (refreshTimer) clearInterval(refreshTimer);
			renderGitStatus(ctx, undefined);
			void refreshGitStatus();
			refreshTimer = setInterval(() => void refreshGitStatus(), GIT_REFRESH_INTERVAL_MS);
		}

		if (ctx.mode !== "tui") return;

		ctx.ui.setFooter((tui, theme, footerData) => {
			activeTui = tui;
			const unsubscribe = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: () => {
					unsubscribe();
					if (activeTui === tui) activeTui = undefined;
				},
				invalidate: () => {},
				render: (width: number) => renderFooter(ctx, theme, footerData, width),
			};
		});

		ctx.ui.setEditorComponent((tui, editorTheme, keybindings) => {
			activeTui = tui;
			const boldBorder = (text: string) => ctx.ui.theme.bold(ctx.ui.theme.fg("text", text));
			return new MarginedEditor(tui, editorTheme, keybindings, boldBorder);
		});
	});

	pi.on("tool_execution_end", async () => {
		void refreshGitStatus();
	});

	pi.on("turn_end", async () => {
		void refreshGitStatus();
	});

	const requestRender = () => activeTui?.requestRender();
	pi.on("model_select", requestRender);
	pi.on("thinking_level_select", requestRender);
	pi.on("message_end", requestRender);
	pi.on("tool_execution_end", requestRender);
	pi.on("turn_end", requestRender);
	pi.on("session_compact", requestRender);

	pi.on("session_shutdown", async (_event, ctx) => {
		stopGitStatus(ctx);
		activeTui = undefined;
	});
}
