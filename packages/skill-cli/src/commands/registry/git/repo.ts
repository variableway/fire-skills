import { spawnSync } from "node:child_process";
import { existsSync, lstatSync } from "node:fs";
import { join } from "node:path";

export function isGitRepo(path: string): boolean {
  const git = join(path, ".git");
  if (!existsSync(git)) return false;
  const st = lstatSync(git);
  return st.isDirectory() || st.isFile();
}

export function normalizeUrl(url: string): string {
  if (url.startsWith("git@") && url.includes(":")) {
    const rest = url.slice(4);
    const colon = rest.indexOf(":");
    const host = rest.slice(0, colon);
    const path = rest.slice(colon + 1);
    return `https://${host}/${path}`;
  }
  return url;
}

export function urlKey(url: string): string {
  return normalizeUrl(url).replace(/\/+$/, "").replace(/\.git$/, "");
}

export type GitResult = {
  ok: boolean;
  stdout: string;
  stderr: string;
  code: number;
};

export function runGit(args: string[], cwd: string): GitResult {
  const result = spawnSync("git", args, { cwd, encoding: "utf8" });
  return {
    ok: result.status === 0,
    stdout: (result.stdout ?? "").trim(),
    stderr: (result.stderr ?? "").trim(),
    code: result.status ?? 1,
  };
}

export function getRemoteUrl(path: string): string | null {
  if (!isGitRepo(path)) return null;
  const result = runGit(["remote", "get-url", "origin"], path);
  if (!result.ok || !result.stdout) return null;
  return normalizeUrl(result.stdout);
}

export function gitClone(repo: string, target: string): boolean {
  const result = spawnSync("git", ["clone", repo, target], { stdio: "inherit" });
  return result.status === 0;
}
