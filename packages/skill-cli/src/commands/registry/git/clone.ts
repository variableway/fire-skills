import { existsSync, mkdirSync, readdirSync } from "node:fs";
import { dirname, relative } from "node:path";
import { resolveOnDisk } from "../config/index.ts";
import type { RuntimeLayout } from "../config/types.ts";
import type { Project } from "../store/types.ts";
import { readExisting } from "../store/yaml.ts";
import { gitClone, isGitRepo, runGit, urlKey } from "./repo.ts";

export type CloneOptions = {
  layout: RuntimeLayout;
  registry: string;
};

function rel(worksRoot: string, target: string): string {
  return relative(worksRoot, target).split("\\").join("/");
}

export function updateRepo(target: string, repo: string, worksRoot: string): "ok" | "updated" | "skipped" | "error" {
  const remote = runGit(["remote", "get-url", "origin"], target);
  if (remote.ok) {
    if (urlKey(remote.stdout) !== urlKey(repo)) {
      console.log(`[WARN] ${rel(worksRoot, target)} origin is ${remote.stdout}, registry is ${repo}`);
    }
  } else {
    runGit(["remote", "add", "origin", repo], target);
  }

  const fetch = runGit(["fetch", "--prune", "origin"], target);
  if (!fetch.ok) {
    console.log(`[ERROR] fetch failed: ${rel(worksRoot, target)}`);
    if (fetch.stderr) console.log(fetch.stderr);
    return "error";
  }

  const upstream = runGit(["rev-parse", "--abbrev-ref", "@{u}"], target);
  let targetRef = "";
  if (upstream.ok) {
    targetRef = upstream.stdout;
  } else {
    for (const candidate of ["origin/main", "origin/master"]) {
      if (runGit(["rev-parse", "--verify", candidate], target).ok) {
        targetRef = candidate;
        break;
      }
    }
    if (!targetRef) {
      console.log(`[WARN] ${rel(worksRoot, target)} has no usable remote branch, skipping update`);
      return "skipped";
    }
  }

  const before = runGit(["rev-parse", "HEAD"], target).stdout;
  const pull = runGit(["merge", "--ff-only", targetRef], target);
  if (!pull.ok) {
    console.log(`[WARN] ${rel(worksRoot, target)} cannot fast-forward to ${targetRef}`);
    const detail = (pull.stderr || pull.stdout).trim();
    if (detail) console.log(`       ${detail}`);
    return "skipped";
  }

  const after = runGit(["rev-parse", "HEAD"], target).stdout;
  if (before === after) {
    console.log(`[OK]    ${rel(worksRoot, target)} is up to date`);
    return "ok";
  }
  console.log(`[PULL]  ${rel(worksRoot, target)} ${before.slice(0, 7)} -> ${after.slice(0, 7)}`);
  return "updated";
}

export async function runClone(opts: CloneOptions): Promise<number> {
  if (!existsSync(opts.registry)) {
    console.log(`[ERROR] registry file not found: ${opts.registry}`);
    return 1;
  }

  console.log(`==> Registry: ${opts.registry.split("/").pop()}`);
  const projects: Project[] = readExisting(opts.registry);
  if (!projects.length) {
    console.log("==> No projects in registry");
    return 0;
  }

  console.log("==> Found the following projects:");
  for (const p of projects) {
    console.log(`    ${p.name ?? "?"} -> ${p.repo ?? "?"}  (${p.path ?? "?"})`);
  }
  console.log();

  let cloned = 0;
  let updated = 0;
  let skipped = 0;
  let errors = 0;

  for (const p of projects) {
    const name = p.name ?? "?";
    const repo = p.repo ?? "";
    const relPath = p.path ?? "";
    if (!repo || !relPath) {
      console.log(`[SKIP] ${name}: repo or path missing`);
      skipped += 1;
      continue;
    }

    const target = resolveOnDisk(opts.layout, relPath);
    if (isGitRepo(target)) {
      const status = updateRepo(target, repo, opts.layout.worksRoot);
      if (status === "updated") updated += 1;
      else if (status === "error") errors += 1;
      else skipped += 1;
    } else if (existsSync(target) && readdirSync(target).length > 0) {
      console.log(`[SKIP] ${relPath} exists but is not a git repository`);
      skipped += 1;
    } else {
      console.log(`[CLONE] ${repo} -> ${relPath}`);
      mkdirSync(dirname(target), { recursive: true });
      if (gitClone(repo, target)) cloned += 1;
      else {
        console.log(`[ERROR] clone failed: ${relPath}`);
        errors += 1;
      }
    }
  }

  console.log(
    `\n==> Done: cloned ${cloned}, updated ${updated}, skipped/up-to-date ${skipped}, failed ${errors}`,
  );
  return errors ? 1 : 0;
}
