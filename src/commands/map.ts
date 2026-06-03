import { spawnSync } from "child_process";
import { existsSync, readdirSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { homedir } from "os";
import { printJson } from "../utils/json";
import { detectRoot } from "../utils/root";
import { mapSkill } from "../core/mapping";
import type { TargetEnvironment } from "../core/types";

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
    sourceBase = join(root, ".agent/skills");
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

export function runSync(_options: { yes?: boolean; output?: string }): void {
  console.error("Error: sync command is not yet implemented");
  process.exit(1);
}