import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const MARKER_DIRS = [".git", ".agent", ".claude", ".gemini", ".codex", ".qwen"];

export interface RootDetection {
  root: string;
  reason: string;
}

export function detectRoot(startDir: string = process.cwd()): RootDetection {
  let current = startDir;

  while (current !== join(current, "..")) {
    for (const marker of MARKER_DIRS) {
      if (existsSync(join(current, marker))) {
        return { root: current, reason: marker };
      }
    }

    if (existsSync(join(current, "AGENTS.md"))) {
      return { root: current, reason: "AGENTS.md" };
    }

    if (existsSync(join(current, "package.json"))) {
      try {
        const content = readFileSync(join(current, "package.json"), "utf-8");
        const pkg = JSON.parse(content);
        if (pkg.fireSkill) {
          return { root: current, reason: "package.json:fireSkill" };
        }
      } catch {
        // Ignore
      }
    }

    const parent = join(current, "..");
    if (parent === current) break;
    current = parent;
  }

  return { root: startDir, reason: "fallback:cwd" };
}