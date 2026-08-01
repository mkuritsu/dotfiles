import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const WAVE_FRAMES = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█", "▇", "▆", "▅", "▄", "▃", "▂"];

const WORKING_WORDS = [
  "Analyzing",
  "Brewing",
  "Calculating",
  "Cerebrating",
  "Chiseling",
  "Compiling",
  "Composing",
  "Conjuring",
  "Considering",
  "Contemplating",
  "Cooking",
  "Crafting",
  "Crunching",
  "Decoding",
  "Deliberating",
  "Exploring",
  "Fiddling",
  "Forging",
  "Hatching",
  "Investigating",
  "Juggling",
  "Marinating",
  "Musing",
  "Noodling",
  "Pondering",
  "Reasoning",
  "Refactoring",
  "Reticulating",
  "Ruminating",
  "Scheming",
  "Sketching",
  "Summoning",
  "Thinking",
  "Tinkering",
  "Untangling",
  "Wiring",
  "Wrangling",
] as const;

export default function (pi: ExtensionAPI) {
  let lastWord: string | undefined;

  const setRandomWorkingMessage = (ctx: ExtensionContext) => {
    const availableWords = WORKING_WORDS.filter((word) => word !== lastWord);
    const word = availableWords[Math.floor(Math.random() * availableWords.length)] ?? WORKING_WORDS[0];
    lastWord = word;
    ctx.ui.setWorkingMessage(`${word}...`);
  };

  pi.on("session_start", (_event, ctx) => {
    ctx.ui.setWorkingIndicator({ frames: WAVE_FRAMES, intervalMs: 80 });
  });

  pi.on("agent_start", (_event, ctx) => setRandomWorkingMessage(ctx));
  pi.on("message_start", (_event, ctx) => setRandomWorkingMessage(ctx));
  pi.on("tool_execution_start", (_event, ctx) => setRandomWorkingMessage(ctx));
}
