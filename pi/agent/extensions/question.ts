/**
 * Ask the user a question with model-provided choices or a custom answer.
 *
 * The custom-answer choice is always appended as the final option. Selecting
 * it opens an inline editor; Escape returns to the choices list.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
	Editor,
	type EditorTheme,
	Key,
	matchesKey,
	Text,
	visibleWidth,
	wrapTextWithAnsi,
} from "@earendil-works/pi-tui";
import { Type } from "typebox";

const CUSTOM_OPTION = "Write a different answer...";

interface QuestionDetails {
	question: string;
	options: string[];
	answer: string | null;
	wasCustom: boolean;
	cancelled: boolean;
}

const QuestionParams = Type.Object({
	question: Type.String({ description: "The question to ask the user" }),
	options: Type.Array(Type.String(), {
		description: "The choices to show the user; a custom-answer choice is added automatically",
	}),
});

type PromptResult =
	| { answer: string; wasCustom: false; index: number }
	| { answer: string; wasCustom: true }
	| null;

function resultDetails(
	params: { question: string; options: string[] },
	answer: string | null,
	wasCustom: boolean,
	cancelled: boolean,
): QuestionDetails {
	return {
		question: params.question,
		options: params.options,
		answer,
		wasCustom,
		cancelled,
	};
}

export default function questionExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "question",
		label: "Question",
		description:
			"Ask the user a question and wait for their answer. The user can choose one of the provided options or write a different answer.",
		parameters: QuestionParams,
		// Only one question dialog should own the terminal at a time.
		executionMode: "sequential",

		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			if (ctx.mode !== "tui") {
				return {
					content: [
						{
							type: "text",
							text: "Unable to ask the question: an interactive TUI is not available.",
						},
					],
					details: resultDetails(params, null, false, true),
				};
			}

			if (signal?.aborted) {
				return {
					content: [{ type: "text", text: "Question cancelled." }],
					details: resultDetails(params, null, false, true),
				};
			}

			const choices = [...params.options, CUSTOM_OPTION];

			const result = await ctx.ui.custom<PromptResult>((tui, theme, _keybindings, done) => {
				let selected = 0;
				let editing = false;
				let cachedLines: string[] | undefined;

				const editorTheme: EditorTheme = {
					borderColor: (text) => theme.fg("accent", text),
					selectList: {
						selectedPrefix: (text) => theme.fg("accent", text),
						selectedText: (text) => theme.fg("accent", text),
						description: (text) => theme.fg("muted", text),
						scrollInfo: (text) => theme.fg("dim", text),
						noMatch: (text) => theme.fg("warning", text),
					},
				};
				const editor = new Editor(tui, editorTheme);

				const refresh = () => {
					cachedLines = undefined;
					tui.requestRender();
				};

				editor.onSubmit = (value) => {
					const answer = value.trim();
					if (!answer) return;
					done({ answer, wasCustom: true });
				};

				const handleInput = (data: string) => {
					if (editing) {
						if (matchesKey(data, Key.escape)) {
							editing = false;
							editor.setText("");
							refresh();
							return;
						}
						editor.handleInput(data);
						refresh();
						return;
					}

					if (matchesKey(data, Key.up)) {
						selected = Math.max(0, selected - 1);
						refresh();
						return;
					}
					if (matchesKey(data, Key.down)) {
						selected = Math.min(choices.length - 1, selected + 1);
						refresh();
						return;
					}
					if (matchesKey(data, Key.enter)) {
						if (selected === choices.length - 1) {
							editing = true;
							editor.setText("");
							refresh();
						} else {
							done({ answer: choices[selected], wasCustom: false, index: selected + 1 });
						}
						return;
					}
					if (matchesKey(data, Key.escape)) done(null);
				};

				const render = (width: number): string[] => {
					if (cachedLines) return cachedLines;

					const lines: string[] = [];
					const renderWidth = Math.max(1, width);

					const addWrapped = (text: string) => {
						lines.push(...wrapTextWithAnsi(text, renderWidth));
					};

					const addWrappedWithPrefix = (prefix: string, text: string) => {
						const prefixWidth = visibleWidth(prefix);
						if (prefixWidth >= renderWidth) {
							addWrapped(prefix + text);
							return;
						}
						const wrapped = wrapTextWithAnsi(text, renderWidth - prefixWidth);
						const continuationPrefix = " ".repeat(prefixWidth);
						for (let i = 0; i < wrapped.length; i++) {
							lines.push(`${i === 0 ? prefix : continuationPrefix}${wrapped[i]}`);
						}
					};

					lines.push(theme.fg("accent", "─".repeat(renderWidth)));
					addWrappedWithPrefix(" ", theme.fg("text", params.question));
					lines.push("");

					for (let i = 0; i < choices.length; i++) {
						const isSelected = i === selected;
						const isCustom = i === choices.length - 1;
						const prefix = isSelected ? theme.fg("accent", "> ") : "  ";
						const label = `${i + 1}. ${choices[i]}${isCustom && editing ? " ✎" : ""}`;
						const color = isSelected || (isCustom && editing) ? "accent" : "text";
						addWrappedWithPrefix(prefix, theme.fg(color, label));
					}

					if (editing) {
						lines.push("");
						addWrappedWithPrefix(" ", theme.fg("muted", "Your answer:"));
						for (const line of editor.render(Math.max(1, renderWidth - 2))) {
							lines.push(` ${line}`);
						}
					}

					lines.push("");
					const help = editing
						? "Enter to submit • Esc to return to choices"
						: "↑↓ navigate • Enter to select • Esc to cancel";
					addWrappedWithPrefix(" ", theme.fg("dim", help));
					lines.push(theme.fg("accent", "─".repeat(renderWidth)));

					cachedLines = lines;
					return lines;
				};

				return {
					render,
					invalidate: () => {
						cachedLines = undefined;
					},
					handleInput,
				};
			});

			if (result === null) {
				return {
					content: [{ type: "text", text: "The user cancelled the question." }],
					details: resultDetails(params, null, false, true),
				};
			}

			if (result.wasCustom) {
				return {
					content: [{ type: "text", text: `The user wrote: ${result.answer}` }],
					details: resultDetails(params, result.answer, true, false),
				};
			}

			return {
				content: [{ type: "text", text: `The user selected option ${result.index}: ${result.answer}` }],
				details: resultDetails(params, result.answer, false, false),
			};
		},

		renderCall(args, theme) {
			const options = Array.isArray(args.options) ? args.options : [];
			const optionText = [...options, CUSTOM_OPTION]
				.map((option, index) => `${index + 1}. ${String(option)}`)
				.join(", ");
			return new Text(
				theme.fg("toolTitle", theme.bold("question ")) +
					theme.fg("muted", String(args.question ?? "")) +
					`\n${theme.fg("dim", `  Options: ${optionText}`)}`,
				0,
				0,
			);
		},

		renderResult(result, _options, theme) {
			const details = result.details as QuestionDetails | undefined;
			if (!details) {
				const text = result.content[0];
				return new Text(text?.type === "text" ? text.text : "", 0, 0);
			}
			if (details.cancelled) return new Text(theme.fg("warning", "Cancelled"), 0, 0);

			if (details.wasCustom) {
				return new Text(
					theme.fg("success", "✓ ") +
						theme.fg("muted", "(wrote) ") +
						theme.fg("accent", details.answer ?? ""),
					0,
					0,
				);
			}

			const index = details.options.indexOf(details.answer ?? "") + 1;
			const display = index > 0 ? `${index}. ${details.answer}` : details.answer ?? "";
			return new Text(theme.fg("success", "✓ ") + theme.fg("accent", display), 0, 0);
		},
	});
}
