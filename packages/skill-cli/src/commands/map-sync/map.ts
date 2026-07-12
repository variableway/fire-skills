import { existsSync, readdirSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { TargetEnvironment } from "@skill-spark/skill-core/types";
import { mapSkill } from "@skill-spark/skill-core/mapping";
import { printJson } from "../../utils/json";
import { detectRoot } from "../../utils/root";

export const COMMAND_DESCRIPTION = "Map installed skills into a target agent directory structure";
export const COMMAND_EXAMPLES = [
  "skill-spark map --target codex",
  "skill-spark map --target claude --universal",
  "skill-spark map --target gemini --global",
];
export const COMMAND_PREREQUISITES = [
  "Skills must be installed in the source directory (default: .claude/skills)",
  "Target agent directory must be writable",
];

export interface MapCommandOptions {
  target?: string;
  global?: boolean;
  universal?: boolean;
  forceMap?: boolean;
}

export async function runMap(options: MapCommandOptions): Promise<void> {
  if (!options.target) {
    console.error("Error: --target is required");
    process.exit(1);
  }

  const target = options.target as TargetEnvironment;
  if (!["codex", "gemini", "claude", "agent", "qwen"].includes(target)) {
    console.error(`Error: Invalid target '${target}'. Valid options: codex, gemini, claude, agent, qwen`);
    process.exit(1);
  }

  const { root } = detectRoot(process.cwd());

  let sourceBase: string;
  if (options.global) {
    sourceBase = join(homedir(), ".skill-spark/skills");
  } else if (options.universal) {
    sourceBase = join(root, ".agents/skills");
  } else {
    sourceBase = join(root, ".claude/skills");
  }

  if (!existsSync(sourceBase)) {
    printJson({ schemaVersion: "1", mapped: 0, sourceBase, targetRoot: "" });
    return;
  }

  const entries = readdirSync(sourceBase, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name);

  let mapped = 0;
  const targetRoot = join(root, target === "codex" ? ".codex/skills" : `.${target}/skills`);

  for (const skillName of entries) {
    const sourcePath = join(sourceBase, skillName);
    try {
      mapSkill(root, target, skillName, sourcePath, { forceMap: options.forceMap });
      mapped++;
    } catch {
      // Skip already mapped or errors
    }
  }

  printJson({ schemaVersion: "1", mapped, sourceBase, targetRoot });
}
