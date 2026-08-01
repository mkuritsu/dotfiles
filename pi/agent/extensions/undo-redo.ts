import { Buffer } from "node:buffer";
import { homedir } from "node:os";
import { dirname, isAbsolute, resolve } from "node:path";
import {
  chmod,
  mkdir,
  readFile,
  stat,
  unlink,
  writeFile,
} from "node:fs/promises";
import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";

/**
 * Undo/redo for files changed by Pi's built-in edit and write tools.
 *
 * A group is created for each user prompt. Before the first mutation of a
 * file, its complete contents are captured; once the agent settles, the final
 * contents are captured. This makes multiple edits to the same file one undo
 * operation and also handles parallel tool calls safely.
 */

const STATE_TYPE = "undo-redo-state";
const STATE_VERSION = 1;

type Snapshot = {
  exists: boolean;
  data?: Buffer;
  mode?: number;
};

type TrackedFile = {
  before: Snapshot;
  after?: Snapshot;
};

type PromptGroup = {
  files: Map<string, TrackedFile>;
  status: "applied" | "undone";
  finalized: boolean;
};

type PersistedSnapshot = {
  exists: boolean;
  data?: string;
  mode?: number;
};

type PersistedGroup = {
  status: "applied" | "undone";
  files: Array<{
    path: string;
    before: PersistedSnapshot;
    after: PersistedSnapshot;
  }>;
};

type PersistedState = {
  version: number;
  group?: PersistedGroup;
};

function errorCode(error: unknown): string | undefined {
  if (typeof error !== "object" || error === null || !("code" in error)) {
    return undefined;
  }
  const code = (error as { code?: unknown }).code;
  return typeof code === "string" ? code : undefined;
}

function resolveTargetPath(rawPath: string, cwd: string): string {
  // Match the useful path behavior of Pi's built-in tools: @ prefixes and ~
  // are accepted in addition to ordinary relative and absolute paths.
  let path = rawPath.replace(/^@(?=\/|~|[^/])/, "");
  if (path === "~") path = homedir();
  else if (path.startsWith("~/")) path = resolve(homedir(), path.slice(2));
  return isAbsolute(path) ? resolve(path) : resolve(cwd, path);
}

async function takeSnapshot(path: string): Promise<Snapshot> {
  try {
    const info = await stat(path);
    if (!info.isFile()) {
      throw new Error("not a regular file");
    }
    return {
      exists: true,
      data: await readFile(path),
      mode: info.mode & 0o7777,
    };
  } catch (error) {
    if (errorCode(error) === "ENOENT") {
      return { exists: false };
    }
    throw error;
  }
}

function snapshotsEqual(left: Snapshot, right: Snapshot): boolean {
  if (left.exists !== right.exists) return false;
  if (!left.exists || !right.exists) return true;
  return (
    left.mode === right.mode &&
    left.data !== undefined &&
    right.data !== undefined &&
    left.data.equals(right.data)
  );
}

async function restoreSnapshot(path: string, snapshot: Snapshot): Promise<void> {
  if (!snapshot.exists) {
    try {
      await unlink(path);
    } catch (error) {
      if (errorCode(error) !== "ENOENT") throw error;
    }
    return;
  }

  if (snapshot.data === undefined) {
    throw new Error(`missing snapshot data for ${path}`);
  }

  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, snapshot.data);
  if (snapshot.mode !== undefined) {
    await chmod(path, snapshot.mode);
  }
}

function encodeSnapshot(snapshot: Snapshot): PersistedSnapshot {
  return {
    exists: snapshot.exists,
    data: snapshot.data?.toString("base64"),
    mode: snapshot.mode,
  };
}

function decodeSnapshot(value: unknown): Snapshot | undefined {
  if (typeof value !== "object" || value === null) return undefined;
  const raw = value as Partial<PersistedSnapshot>;
  if (typeof raw.exists !== "boolean") return undefined;
  if (!raw.exists) return { exists: false };
  if (typeof raw.data !== "string") return undefined;
  return {
    exists: true,
    data: Buffer.from(raw.data, "base64"),
    mode: typeof raw.mode === "number" ? raw.mode : undefined,
  };
}

function encodeGroup(group: PromptGroup): PersistedGroup {
  return {
    status: group.status,
    files: [...group.files.entries()]
      .filter(([, file]) => file.after !== undefined)
      .map(([path, file]) => ({
        path,
        before: encodeSnapshot(file.before),
        after: encodeSnapshot(file.after as Snapshot),
      })),
  };
}

function decodeGroup(value: unknown): PromptGroup | undefined {
  if (typeof value !== "object" || value === null) return undefined;
  const raw = value as Partial<PersistedGroup>;
  if (raw.status !== "applied" && raw.status !== "undone") return undefined;
  if (!Array.isArray(raw.files)) return undefined;

  const files = new Map<string, TrackedFile>();
  for (const item of raw.files) {
    if (typeof item !== "object" || item === null) return undefined;
    const entry = item as { path?: unknown; before?: unknown; after?: unknown };
    if (typeof entry.path !== "string") return undefined;
    const before = decodeSnapshot(entry.before);
    const after = decodeSnapshot(entry.after);
    if (!before || !after) return undefined;
    files.set(entry.path, { before, after });
  }

  if (files.size === 0) return undefined;
  return { files, status: raw.status, finalized: true };
}

function restoreState(ctx: ExtensionContext): PromptGroup | undefined {
  const entries = ctx.sessionManager.getBranch();
  for (let index = entries.length - 1; index >= 0; index--) {
    const entry = entries[index] as {
      type?: string;
      customType?: string;
      data?: unknown;
    };
    if (entry.type !== "custom" || entry.customType !== STATE_TYPE) continue;

    const state = entry.data as Partial<PersistedState> | undefined;
    if (!state || state.version !== STATE_VERSION) return undefined;
    return decodeGroup(state.group);
  }
  return undefined;
}

export default function (pi: ExtensionAPI) {
  let currentGroup: PromptGroup | undefined;
  let lastGroup: PromptGroup | undefined;

  function persist(group: PromptGroup | undefined): void {
    const state: PersistedState = {
      version: STATE_VERSION,
      group: group ? encodeGroup(group) : undefined,
    };
    try {
      // Custom entries are not sent to the model and restore correctly on
      // reload/resume. The latest entry on the active branch is authoritative.
      pi.appendEntry(STATE_TYPE, state);
    } catch {
      // In-memory undo/redo remains usable for ephemeral sessions.
    }
  }

  async function finishGroup(group: PromptGroup): Promise<void> {
    if (group.finalized) return;
    group.finalized = true;

    const changed = new Map<string, TrackedFile>();
    for (const [path, file] of group.files) {
      try {
        const after = await takeSnapshot(path);
        if (!snapshotsEqual(file.before, after)) {
          changed.set(path, { before: file.before, after });
        }
      } catch {
        // A path that cannot be read safely is not made undoable. This avoids
        // replacing a file with an incomplete snapshot.
      }
    }

    group.files = changed;
    if (changed.size === 0) {
      if (lastGroup === group) lastGroup = undefined;
      return;
    }

    group.status = "applied";
    lastGroup = group;
    persist(lastGroup);
  }

  async function startPrompt(): Promise<void> {
    if (currentGroup && !currentGroup.finalized) {
      await finishGroup(currentGroup);
    }
    currentGroup = {
      files: new Map(),
      status: "applied",
      finalized: false,
    };
    // A new prompt creates a new undo boundary, so an old undone group is no
    // longer eligible for redo.
    lastGroup = undefined;
    persist(undefined);
  }

  pi.on("session_start", async (_event, ctx) => {
    currentGroup = undefined;
    lastGroup = restoreState(ctx);
  });

  pi.on("before_agent_start", async () => {
    await startPrompt();
  });

  pi.on("tool_call", async (event, ctx) => {
    if (
      !isToolCallEventType("edit", event) &&
      !isToolCallEventType("write", event)
    ) {
      return;
    }

    // This fallback is useful for non-standard callers that invoke a tool
    // without first emitting before_agent_start.
    if (!currentGroup) {
      currentGroup = {
        files: new Map(),
        status: "applied",
        finalized: false,
      };
      lastGroup = undefined;
    }

    const rawPath = event.input.path;
    const path = resolveTargetPath(rawPath, ctx.cwd);
    if (currentGroup.files.has(path)) return;

    try {
      currentGroup.files.set(path, {
        before: await takeSnapshot(path),
      });
    } catch {
      // Do not interfere with the built-in tool; just leave this file
      // untracked because its original contents could not be captured.
    }
  });

  pi.on("agent_settled", async () => {
    if (currentGroup) await finishGroup(currentGroup);
  });

  async function applyHistory(
    direction: "undo" | "redo",
    ctx: ExtensionCommandContext,
  ): Promise<void> {
    await ctx.waitForIdle();
    if (currentGroup && !currentGroup.finalized) {
      await finishGroup(currentGroup);
    }

    const group = lastGroup;
    if (!group) {
      ctx.ui.notify(
        direction === "undo"
          ? "Nothing to undo for the last user prompt."
          : "Nothing to redo.",
        "info",
      );
      return;
    }

    if (direction === "undo" && group.status === "undone") {
      ctx.ui.notify("The last prompt's changes are already undone.", "info");
      return;
    }
    if (direction === "redo" && group.status === "applied") {
      ctx.ui.notify("Nothing to redo; the last prompt's changes are applied.", "info");
      return;
    }

    const entries = [...group.files.entries()];
    const expected = direction === "undo" ? "after" : "before";
    const target = direction === "undo" ? "before" : "after";
    const current = new Map<string, Snapshot>();
    const conflicts: string[] = [];

    for (const [path, file] of entries) {
      try {
        const actual = await takeSnapshot(path);
        current.set(path, actual);
        if (!snapshotsEqual(actual, file[expected] as Snapshot)) {
          conflicts.push(path);
        }
      } catch {
        conflicts.push(path);
      }
    }

    if (conflicts.length > 0) {
      ctx.ui.notify(
        `Cannot ${direction}: files changed outside Pi (${conflicts.join(", ")}).`,
        "warning",
      );
      return;
    }

    try {
      for (const [path, file] of entries) {
        await restoreSnapshot(path, file[target] as Snapshot);
      }
    } catch (error) {
      // Best-effort transaction rollback if a later file fails to restore.
      for (const [path, snapshot] of current) {
        try {
          await restoreSnapshot(path, snapshot);
        } catch {
          // Keep the original error as the useful notification.
        }
      }
      const message = error instanceof Error ? error.message : String(error);
      ctx.ui.notify(`Could not ${direction} changes: ${message}`, "error");
      return;
    }

    group.status = direction === "undo" ? "undone" : "applied";
    persist(group);
    ctx.ui.notify(
      `${direction === "undo" ? "Undid" : "Redid"} changes in ${entries.length} file${entries.length === 1 ? "" : "s"}.`,
      "info",
    );
  }

  pi.registerCommand("undo", {
    description: "Undo all file changes made by the last user prompt",
    handler: async (_args, ctx) => {
      await applyHistory("undo", ctx);
    },
  });

  pi.registerCommand("redo", {
    description: "Redo file changes undone by /undo",
    handler: async (_args, ctx) => {
      await applyHistory("redo", ctx);
    },
  });
}
