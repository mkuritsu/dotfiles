import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getSupportedThinkingLevels } from "@earendil-works/pi-ai";

export default function (pi: ExtensionAPI): void {
  pi.registerShortcut("ctrl+t", {
    description: "Cycle thinking level",
    handler: (ctx) => {
      const model = ctx.model;
      if (!model?.reasoning) return;

      const levels = getSupportedThinkingLevels(model);
      if (levels.length === 0) return;

      const current = ctx.thinkingLevel ?? "off";
      const currentIndex = levels.indexOf(current);
      const next = levels[(currentIndex + 1) % levels.length] ?? levels[0];
      pi.setThinkingLevel(next);
    },
  });
}
