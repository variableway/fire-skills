import { existsSync, readdirSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { resolveScanRoot } from "../config/index.ts";
import type { RuntimeLayout } from "../config/types.ts";
import { getRemoteUrl } from "../git/repo.ts";
import type { Project } from "../store/types.ts";

export function scanDir(layout: RuntimeLayout, name: string, maxDepth: number): Project[] {
  const { root, relBase } = resolveScanRoot(layout, name);
  if (!existsSync(root) || !statSync(root).isDirectory()) return [];

  const found: Project[] = [];

  const walk = (dir: string, depth: number): void => {
    const entries = readdirSync(dir).sort();
    for (const entryName of entries) {
      if (entryName.startsWith(".") || layout.ignoreDirs.has(entryName)) continue;
      const entry = join(dir, entryName);
      if (!statSync(entry).isDirectory()) continue;
      const url = getRemoteUrl(entry);
      if (url) {
        found.push({
          name: entryName,
          repo: url,
          path: relative(relBase, entry).split("\\").join("/"),
          desc: "",
        });
      }
      if (maxDepth === 0 || depth < maxDepth) walk(entry, depth + 1);
    }
  };

  walk(root, 1);
  return found;
}
