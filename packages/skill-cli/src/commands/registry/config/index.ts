import { existsSync, readFileSync } from "node:fs";
import { basename, dirname, isAbsolute, join, resolve } from "node:path";
import { parse as parseYaml } from "yaml";
import {
  CONFIG_FILENAMES,
  DEFAULT_IGNORE_DIRS,
  type FileConfig,
  type LayoutOverrides,
  type RuntimeLayout,
} from "./types.ts";

export type { FileConfig, LayoutOverrides, RuntimeLayout } from "./types.ts";
export { CONFIG_FILENAMES } from "./types.ts";

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

function resolveMaybe(base: string, path: string | undefined): string {
  if (!path) return "";
  return isAbsolute(path) ? path : resolve(base, path);
}

export function readFileConfig(path: string): FileConfig {
  const data = parseYaml(readFileSync(path, "utf8")) as FileConfig | null;
  return data ?? {};
}

export function findConfigFile(cwd: string, explicit?: string): string {
  if (explicit) {
    const path = resolve(cwd, explicit);
    if (!exists(path)) throw new Error(`config file not found: ${path}`);
    return path;
  }
  const fromEnv = process.env.REGISTRY_CLI_CONFIG;
  if (fromEnv) {
    const path = resolve(cwd, fromEnv);
    if (!exists(path)) throw new Error(`config file not found: ${path}`);
    return path;
  }
  for (const dir of walkParents(cwd)) {
    for (const name of CONFIG_FILENAMES) {
      const path = join(dir, name);
      if (exists(path)) return path;
    }
  }
  return "";
}

function findNamedDir(start: string, name: string): string {
  for (const dir of walkParents(start)) {
    const candidate = join(dir, name);
    if (exists(candidate)) return candidate;
    if (basename(dir) === name && exists(dir)) return dir;
  }
  return "";
}

export function resolveOnDisk(layout: RuntimeLayout, relPath: string): string {
  const prefix = layout.appsPrefix;
  if (prefix && (relPath === prefix || relPath.startsWith(`${prefix}/`))) {
    const rest = relPath === prefix ? "" : relPath.slice(prefix.length + 1);
    return rest ? join(layout.appsRoot, rest) : layout.appsRoot;
  }
  const hub = layout.hubName;
  if (hub && (relPath === hub || relPath.startsWith(`${hub}/`))) {
    const rest = relPath === hub ? "" : relPath.slice(hub.length + 1);
    return rest ? join(layout.hubRoot, rest) : layout.hubRoot;
  }
  return join(layout.worksRoot, relPath);
}

export function resolveScanRoot(layout: RuntimeLayout, name: string): { root: string; relBase: string } {
  if (layout.appsPrefix && name === layout.appsPrefix) {
    return { root: layout.appsRoot, relBase: dirname(layout.appsRoot) };
  }
  if (layout.hubName && (name === layout.hubName || name.startsWith(`${layout.hubName}/`))) {
    const rest = name === layout.hubName ? "" : name.slice(layout.hubName.length + 1);
    return { root: rest ? join(layout.hubRoot, rest) : layout.hubRoot, relBase: dirname(layout.hubRoot) };
  }
  return { root: resolveOnDisk(layout, name), relBase: layout.worksRoot };
}

export function resolveLayout(cwd = process.cwd(), overrides: LayoutOverrides = {}): RuntimeLayout {
  const configPath = findConfigFile(cwd, overrides.configPath);
  const file = configPath ? readFileConfig(configPath) : {};
  const configDir = configPath ? dirname(configPath) : cwd;

  const hubRoot =
    resolveMaybe(cwd, overrides.hubRoot || process.env.REGISTRY_CLI_HUB_ROOT) ||
    resolveMaybe(configDir, file.hubRoot) ||
    (configPath ? configDir : "");

  const worksName = overrides.worksName || process.env.REGISTRY_CLI_WORKS_NAME || file.worksName || "";

  const worksRoot =
    resolveMaybe(cwd, overrides.worksRoot || process.env.REGISTRY_CLI_WORKS_ROOT) ||
    resolveMaybe(hubRoot || configDir, file.worksRoot) ||
    (worksName ? findNamedDir(hubRoot || cwd, worksName) : "");

  const appsPrefix = overrides.appsPrefix || file.appsPrefix || "";
  const appsRoot =
    resolveMaybe(cwd, overrides.appsRoot || process.env.REGISTRY_CLI_APPS_ROOT) ||
    resolveMaybe(hubRoot || configDir, file.appsRoot) ||
    (appsPrefix ? join(worksRoot, appsPrefix) : worksRoot);

  const registryRel = overrides.registry || file.registry || "";
  const refsRegistryRel = file.refsRegistry || "";

  if (!hubRoot) {
    throw new Error("Cannot find hub root. Pass --hub-root, REGISTRY_CLI_HUB_ROOT, or a config file.");
  }
  if (!worksRoot) {
    throw new Error(
      "Cannot find works root. Pass --works-root, --works-name, REGISTRY_CLI_WORKS_ROOT, or set worksRoot / worksName in config.",
    );
  }
  if (!registryRel) {
    throw new Error("Cannot find hub registry path. Pass --registry or set registry in config.");
  }

  return {
    hubRoot,
    hubName: basename(hubRoot),
    worksRoot,
    appsRoot,
    appsPrefix,
    registry: resolveMaybe(hubRoot, registryRel),
    refsRegistry: refsRegistryRel ? resolveMaybe(worksRoot, refsRegistryRel) : "",
    scanDirs: file.scanDirs ?? [],
    refsScanDirs: file.refsScanDirs ?? [],
    sectionSecondOnly: file.sectionSecondOnly ?? [],
    sectionKeepPrefix: file.sectionKeepPrefix ?? [],
    defaultDescBySection: file.defaultDescBySection ?? {},
    ignoreDirs: new Set(file.ignoreDirs ?? [...DEFAULT_IGNORE_DIRS]),
  };
}
