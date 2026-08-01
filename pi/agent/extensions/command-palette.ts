import type {
	ExtensionAPI,
	ExtensionContext,
	KeybindingsManager,
	SlashCommandInfo,
	Theme,
} from "@earendil-works/pi-coding-agent";
import { DynamicBorder } from "@earendil-works/pi-coding-agent";
import {
	Box,
	fuzzyFilter,
	Input,
	type Focusable,
	type SelectItem,
	SelectList,
	Text,
	type TUI,
} from "@earendil-works/pi-tui";

interface BuiltinCommand {
	name: string;
	description: string;
	argumentHint?: string;
}

// Built-in interactive commands are intentionally not returned by pi.getCommands().
// Keep this list in the same order as Pi's built-in slash command catalogue.
const BUILTIN_COMMANDS: readonly BuiltinCommand[] = [
	{ name: "settings", description: "Open settings menu" },
	{ name: "model", description: "Select model (opens selector UI)", argumentHint: "<provider/model>" },
	{ name: "scoped-models", description: "Enable/disable models for Ctrl+P cycling" },
	{ name: "export", description: "Export session (HTML default, or specify path: .html/.jsonl)" },
	{ name: "import", description: "Import and resume a session from a JSONL file" },
	{ name: "share", description: "Share session as a secret GitHub gist" },
	{ name: "copy", description: "Copy last agent message to clipboard" },
	{ name: "name", description: "Set session display name" },
	{ name: "session", description: "Show session info and stats" },
	{ name: "changelog", description: "Show changelog entries" },
	{ name: "hotkeys", description: "Show all keyboard shortcuts" },
	{ name: "fork", description: "Create a new fork from a previous user message" },
	{ name: "clone", description: "Duplicate the current session at the current position" },
	{ name: "tree", description: "Navigate session tree (switch branches)" },
	{ name: "trust", description: "Save project trust decision for future sessions" },
	{ name: "login", description: "Configure provider authentication", argumentHint: "<provider>" },
	{ name: "logout", description: "Remove provider authentication" },
	{ name: "new", description: "Start a new session" },
	{ name: "compact", description: "Manually compact the session context" },
	{ name: "resume", description: "Resume a different session" },
	{ name: "reload", description: "Reload keybindings, extensions, skills, prompts, themes, and context files" },
	{ name: "quit", description: "Quit Pi" },
];

interface PaletteCommand {
	command: string;
	label: string;
	description: string;
	searchText: string;
}

const PALETTE_BACKGROUND = (text: string): string =>
	`\u001b[48;2;30;32;48m${text}\u001b[49m`;

interface SubmittableEditor {
	onSubmit?: (text: string) => void | Promise<void>;
}

// Pi does not currently expose a public command-dispatch method to extensions.
// The focused editor's submit callback is the same callback Enter invokes, so using
// it preserves native handling for built-ins, extensions, prompts, and skills.
interface TuiWithFocusedComponent {
	focusedComponent?: SubmittableEditor;
}

function getFocusedEditor(tui: TUI): SubmittableEditor | undefined {
	return (tui as unknown as TuiWithFocusedComponent).focusedComponent;
}

function sourceLabel(command: SlashCommandInfo): string {
	switch (command.source) {
		case "prompt":
			return "prompt";
		case "skill":
			return "skill";
		default:
			return "extension";
	}
}

function getPaletteCommands(pi: ExtensionAPI): PaletteCommand[] {
	const commands: PaletteCommand[] = BUILTIN_COMMANDS.map((command) => {
		const invocation = `/${command.name}`;
		const hint = command.argumentHint ? ` · ${command.argumentHint}` : "";
		return {
			command: invocation,
			label: invocation,
			description: `[pi] ${command.description}${hint}`,
			searchText: `${invocation} ${command.name} ${command.description} ${command.argumentHint ?? ""} pi builtin`,
		};
	});

	const seen = new Set(commands.map((command) => command.command));
	for (const command of pi.getCommands()) {
		const invocation = `/${command.name}`;
		// A built-in command wins when an extension uses the same unsuffixed name.
		if (seen.has(invocation)) continue;

		const source = sourceLabel(command);
		const description = command.description ?? `Run ${source} command`;
		commands.push({
			command: invocation,
			label: invocation,
			description: `[${source}] ${description}`,
			searchText: `${invocation} ${command.name} ${description} ${source} ${command.sourceInfo.source} ${command.sourceInfo.path}`,
		});
		seen.add(invocation);
	}

	return commands;
}

class CommandPalette extends Box implements Focusable {
	private readonly searchInput = new Input();
	private selectList!: SelectList;
	private _focused = false;

	get focused(): boolean {
		return this._focused;
	}

	set focused(value: boolean) {
		this._focused = value;
		this.searchInput.focused = value;
	}

	constructor(
		private readonly commands: PaletteCommand[],
		private readonly theme: Theme,
		private readonly keybindings: KeybindingsManager,
		private readonly onSelect: (command: string) => void,
		private readonly onCancel: () => void,
	) {
		// Use the requested exact RGB background for the entire palette surface.
		super(0, 0, PALETTE_BACKGROUND);
		this.rebuild();
	}

	private rebuild(): void {
		const query = this.searchInput.getValue();
		const filtered = fuzzyFilter(this.commands, query, (command) => command.searchText);
		const items: SelectItem[] = filtered.map((command) => ({
			value: command.command,
			label: command.label,
			description: command.description,
		}));

		this.selectList = new SelectList(items, Math.min(Math.max(items.length, 1), 12), {
			selectedPrefix: (text) => this.theme.fg("accent", text),
			// Keep the palette RGB surface on the hovered row; highlight it with
			// accent/bold text instead of replacing the background with selectedBg.
			selectedText: (text) => this.theme.bold(this.theme.fg("accent", text)),
			description: (text) => this.theme.fg("muted", text),
			scrollInfo: (text) => this.theme.fg("dim", text),
			noMatch: (text) => this.theme.fg("warning", text),
		});
		this.selectList.onSelect = (item) => this.onSelect(item.value);
		this.selectList.onCancel = this.onCancel;

		this.clear();
		this.addChild(new DynamicBorder((text: string) => this.theme.fg("accent", text)));
		this.addChild(
			new Text(
				this.theme.fg("accent", this.theme.bold(`Command Palette · ${this.commands.length} commands`)),
				1,
				0,
			),
		);
		this.addChild(new Text(this.theme.fg("dim", "Type to fuzzy-search"), 1, 0));
		this.addChild(this.searchInput);
		this.addChild(this.selectList);
		this.addChild(new Text(this.theme.fg("dim", "↑↓ navigate · enter execute · esc cancel"), 1, 0));
		this.addChild(new DynamicBorder((text: string) => this.theme.fg("accent", text)));
	}

	handleInput(data: string): void {
		if (
			this.keybindings.matches(data, "tui.select.up") ||
			this.keybindings.matches(data, "tui.select.down") ||
			this.keybindings.matches(data, "tui.select.confirm") ||
			this.keybindings.matches(data, "tui.select.cancel")
		) {
			this.selectList.handleInput(data);
			return;
		}

		const previousQuery = this.searchInput.getValue();
		this.searchInput.handleInput(data);
		if (this.searchInput.getValue() !== previousQuery) {
			this.rebuild();
		}
	}

	override invalidate(): void {
		super.invalidate();
		this.rebuild();
	}
}

function tryRestoreDraft(ctx: ExtensionContext, draft: string, force: boolean): void {
	try {
		const current = ctx.ui.getEditorText();
		if (force || current.length === 0) {
			ctx.ui.setEditorText(draft);
		}
	} catch {
		// Commands such as /reload and session replacement can invalidate this ctx.
	}
}

export default function commandPaletteExtension(pi: ExtensionAPI) {
	async function openCommandPalette(ctx: ExtensionContext): Promise<void> {
		if (ctx.mode !== "tui") {
			ctx.ui.notify("The command palette requires TUI mode", "error");
			return;
		}

		const draft = ctx.ui.getEditorText();
		const commands = getPaletteCommands(pi);
		let editor: SubmittableEditor | undefined;

		const selected = await ctx.ui.custom<string | null>(
			(tui, theme, keybindings, done) => {
				editor = getFocusedEditor(tui);
				return new CommandPalette(commands, theme, keybindings, done, () => done(null));
			},
			{
				overlay: true,
				overlayOptions: {
					anchor: "center",
					width: "80%",
					minWidth: 50,
					maxHeight: "80%",
					margin: 1,
				},
			},
		);

		if (!selected) return;
		if (!editor?.onSubmit) {
			ctx.ui.notify(`Could not execute ${selected}: Pi's editor dispatcher is unavailable`, "error");
			return;
		}

		try {
			const submission = editor.onSubmit(selected);
			// Native command handlers often clear the editor before their first await.
			tryRestoreDraft(ctx, draft, true);
			await Promise.resolve(submission);
			// Do not replace text intentionally placed in the editor by a command.
			tryRestoreDraft(ctx, draft, false);
		} catch (error) {
			tryRestoreDraft(ctx, draft, false);
			const message = error instanceof Error ? error.message : String(error);
			ctx.ui.notify(`Failed to execute ${selected}: ${message}`, "error");
		}
	}

	pi.registerShortcut("ctrl+p", {
		description: "Open command palette",
		handler: openCommandPalette,
	});

	pi.registerCommand("palette", {
		description: "Open the command palette",
		handler: async (_args, ctx) => openCommandPalette(ctx),
	});
}
