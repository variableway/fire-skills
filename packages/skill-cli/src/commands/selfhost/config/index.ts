import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, isAbsolute, join, resolve } from "node:path";
import type { FileConfig, ProfileConfig, RuntimeShare, ShareOverrides, Via } from "./types.ts";

export type { FileConfig, ProfileConfig, RuntimeShare, ShareOverrides, Via } from "./types.ts";

const PACKAGE_CONFIG = "config.json";

function exists(path: string): boolean {
  return existsSync(path);
}

function walkParents(start: string): string[] {
  const out: string[] = [];
  let cur = resolve(start);
  for (let i = 0; i < 8; i++) {
    out.push(cur);
    const parent = dirname(cur);
    if (parent === cur) break;
    cur = parent;
  }
  return out;
}

export function expandHome(path: string): string {
  if (path === "~") return homedir();
  if (path.startsWith("~/")) return join(homedir(), path.slice(2));
  return path;
}

function looksLikeFileConfig(data: unknown): data is FileConfig {
  return Boolean(data && typeof data === "object" && data !== null && "profiles" in data);
}

export function readFileConfig(path: string): FileConfig {
  const data = JSON.parse(readFileSync(path, "utf8")) as unknown;
  if (!looksLikeFileConfig(data)) {
    throw new Error(`${path} must be a JSON object with a "profiles" map`);
  }
  return data;
}

export function findConfigFile(cwd: string, explicit?: string): string {
  if (explicit) {
    const path = resolve(cwd, explicit);
    if (!exists(path)) throw new Error(`config file not found: ${path}`);
    return path;
  }

  for (const dir of walkParents(cwd)) {
    const local = join(dir, PACKAGE_CONFIG);
    if (exists(local) && looksLikeFileConfig(JSON.parse(readFileSync(local, "utf8")))) {
      return local;
    }
  }

  return "";
}

function parseVia(value: string | undefined): Via {
  if (!value) return "open";
  if (value === "open" || value === "smbfs") return value;
  throw new Error(`via must be "open" or "smbfs", got ${value}`);
}

export function listProfiles(file: FileConfig): string[] {
  return Object.keys(file.profiles ?? {});
}

export function resolveShare(cwd = process.cwd(), overrides: ShareOverrides = {}): RuntimeShare {
  const configPath = findConfigFile(cwd, overrides.configPath);
  if (!configPath) {
    throw new Error(`config.json not found. Add a config.json with "profiles" in this tree or pass --config.`);
  }
  const file = readFileConfig(configPath);
  const profiles = file.profiles ?? {};
  const names = Object.keys(profiles);
  if (!names.length) throw new Error(`${configPath} has no profiles`);

  const name = overrides.profile || file.default || names[0]!;
  const profile: ProfileConfig | undefined = profiles[name];
  if (!profile) {
    throw new Error(`unknown profile "${name}". Available: ${names.join(", ")}`);
  }

  const host = (profile.host || "").trim();
  const share = (profile.share || "").trim();
  const user = (profile.user || "").trim();
  const mountRaw = profile.mountPoint || "";
  const via = parseVia(profile.via);
  const password = (process.env.SELFHOST_CLI_PASSWORD || "").trim();

  if (!host) throw new Error(`profile "${name}" is missing host in ${configPath}`);
  if (!share) throw new Error(`profile "${name}" is missing share in ${configPath}`);
  if (!user) throw new Error(`profile "${name}" is missing user in ${configPath}`);
  if (!mountRaw) throw new Error(`profile "${name}" is missing mountPoint in ${configPath}`);

  const expanded = expandHome(mountRaw);
  const mountPoint = isAbsolute(expanded) ? expanded : resolve(cwd, expanded);

  return { name, host, share, user, password, mountPoint, via };
}
