import { relative } from "node:path";
import type { Project } from "../store/types.ts";
import { readExisting, writeRegistry } from "../store/yaml.ts";
import type { ScanOptions } from "./constants.ts";
import { merge } from "./merge.ts";
import { scanDir } from "./walk.ts";

function displayPath(path: string, worksRoot: string): string {
  const rel = relative(worksRoot, path);
  if (rel && !rel.startsWith("..")) return rel.split("\\").join("/");
  return path;
}

export async function runScan(opts: ScanOptions): Promise<void> {
  const { layout } = opts;
  const sectionRules = {
    secondOnly: layout.sectionSecondOnly,
    keepPrefix: layout.sectionKeepPrefix,
  };
  console.log(`==> works ${layout.worksRoot}`);
  if (layout.appsPrefix) console.log(`==> apps  ${layout.appsRoot} (${layout.appsPrefix})`);
  console.log(`==> file  ${opts.registry}`);
  console.log();
  const existing = opts.regenerate ? [] : readExisting(opts.registry);
  const discovered: Project[] = [];

  for (const dir of opts.dirs) {
    const found = scanDir(layout, dir, opts.depth);
    discovered.push(...found);
    if (found.length) {
      console.log(`[${dir}] found ${found.length} repos (depth=${opts.depth}):`);
      for (const p of found) console.log(`    ${p.path}  ->  ${p.repo}`);
    } else {
      console.log(`[${dir}] no git repos found`);
    }
    console.log();
  }

  const { final, changes } = merge(
    existing,
    discovered,
    opts.keepMissing,
    layout.defaultDescBySection,
    sectionRules,
  );

  if (changes.added.length) {
    console.log(`[added] ${changes.added.length}:`);
    for (const p of changes.added) console.log(`    ${p.path}  ->  ${p.repo}`);
  }
  if (changes.moved.length) {
    console.log(`[moved] ${changes.moved.length} (matched by repo URL, path updated):`);
    for (const m of changes.moved) console.log(`    ${m}`);
  }
  if (changes.dup.length) {
    console.log(`[dedup] ${changes.dup.length} (same as an already-registered repo, skipped):`);
    for (const p of changes.dup) console.log(`    ${p}`);
  }
  if (changes.missing.length) {
    const action = opts.keepMissing ? "kept" : "removed";
    console.log(`[${action}] ${changes.missing.length} directories no longer exist:`);
    for (const p of changes.missing) console.log(`    ${p.path}`);
  }
  console.log();

  writeRegistry(final, opts.registry, opts.syncedBy, opts.consumedBy, sectionRules);
  const shown = displayPath(opts.registry, layout.worksRoot);
  const removed = opts.keepMissing ? 0 : changes.missing.length;
  console.log(
    `==> Wrote ${shown}, total ${final.length} projects (original ${existing.length}, added ${changes.added.length}, removed ${removed})`,
  );
}
