import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export type SkillType = "skill" | "command";

export interface TrackedItem {
  name: string;
  type: SkillType;
  scope: "project" | "global";
  url: string;
  subpath?: string;
  branch: string;
  commit: string;
  /** Whether the skill has been installed to agent directories. false = registered only. */
  installed: boolean;
}

interface ProjectLock {
  version: string;
  skills: Record<string, TrackedItem>;
}

interface GlobalLock {
  version: string;
  skills: Record<string, TrackedItem>;
}

const flinsHome = join(homedir(), ".skill-spark");

function getProjectLockPath(cwd: string) {
  return join(cwd, "skills.lock");
}

function getGlobalLockPath() {
  return join(flinsHome, "skills.lock");
}

function normalizeLockEntry(item: Record<string, unknown>): TrackedItem {
  return {
    name: item.name as string,
    type: (item.type as SkillType) ?? "skill",
    scope: (item.scope as "project" | "global") ?? "global",
    url: item.url as string,
    subpath: item.subpath as string | undefined,
    branch: (item.branch as string) ?? "main",
    commit: (item.commit as string) ?? "",
    installed: item.installed !== false, // default true for backward compat
  };
}

function readProjectLock(cwd: string): ProjectLock {
  const path = getProjectLockPath(cwd);
  if (!existsSync(path)) {
    return { version: "1", skills: {} };
  }
  try {
    const content = readFileSync(path, "utf-8");
    const parsed = JSON.parse(content) as ProjectLock;
    const normalized: Record<string, TrackedItem> = {};
    for (const [key, item] of Object.entries(parsed.skills ?? {})) {
      normalized[key] = normalizeLockEntry(item as unknown as Record<string, unknown>);
    }
    return {
      version: parsed.version ?? "1",
      skills: normalized,
    };
  } catch {
    return { version: "1", skills: {} };
  }
}

function writeProjectLock(cwd: string, lock: ProjectLock) {
  const path = getProjectLockPath(cwd);
  mkdirSync(".", { recursive: true });
  if (Object.keys(lock.skills).length === 0) {
    rmSync(path, { force: true });
    return;
  }
  writeFileSync(path, `${JSON.stringify(lock, null, 2)}\n`, "utf-8");
}

function readGlobalLock(): GlobalLock {
  mkdirSync(flinsHome, { recursive: true });
  const path = getGlobalLockPath();
  if (!existsSync(path)) {
    return { version: "1", skills: {} };
  }
  try {
    const content = readFileSync(path, "utf-8");
    const parsed = JSON.parse(content) as GlobalLock;
    const normalized: Record<string, TrackedItem> = {};
    for (const [key, item] of Object.entries(parsed.skills ?? {})) {
      normalized[key] = normalizeLockEntry(item as unknown as Record<string, unknown>);
    }
    return {
      version: parsed.version ?? "1",
      skills: normalized,
    };
  } catch {
    return { version: "1", skills: {} };
  }
}

function writeGlobalLock(lock: GlobalLock) {
  mkdirSync(flinsHome, { recursive: true });
  const path = getGlobalLockPath();
  if (Object.keys(lock.skills).length === 0) {
    rmSync(path, { force: true });
    return;
  }
  writeFileSync(path, `${JSON.stringify(lock, null, 2)}\n`, "utf-8");
}

export function listTrackedItems(cwd: string = process.cwd()): TrackedItem[] {
  const projectLock = readProjectLock(cwd);
  const globalLock = readGlobalLock();
  const combined: Record<string, TrackedItem> = {};

  for (const [key, item] of Object.entries(globalLock.skills)) {
    combined[key] = item;
  }

  for (const [key, item] of Object.entries(projectLock.skills)) {
    combined[key] = { ...item, scope: "project" };
  }

  return Object.values(combined).map((item) => ({
    name: item.name,
    type: item.type,
    scope: item.scope,
    url: item.url,
    subpath: item.subpath,
    branch: item.branch,
    commit: item.commit,
    installed: item.installed,
  }));
}

export function trackInstall(item: Omit<TrackedItem, "installed">, cwd: string = process.cwd()) {
  const key = `${item.type}:${item.name.toLowerCase()}`;
  const entry = { ...item, installed: true };
  if (item.scope === "global") {
    const lock = readGlobalLock();
    lock.skills[key] = entry;
    writeGlobalLock(lock);
  } else {
    const lock = readProjectLock(cwd);
    lock.skills[key] = { ...entry, scope: "project" };
    writeProjectLock(cwd, lock);
  }
}

export function registerTrackedItem(item: Omit<TrackedItem, "installed">, cwd: string = process.cwd()) {
  const key = `${item.type}:${item.name.toLowerCase()}`;
  const entry = { ...item, installed: false };
  if (item.scope === "global") {
    const lock = readGlobalLock();
    lock.skills[key] = entry;
    writeGlobalLock(lock);
  } else {
    const lock = readProjectLock(cwd);
    lock.skills[key] = { ...entry, scope: "project" };
    writeProjectLock(cwd, lock);
  }
}

export function updateTrackedCommit(
  scope: "project" | "global",
  name: string,
  type: SkillType,
  commit: string,
  cwd: string = process.cwd(),
) {
  const key = `${type}:${name.toLowerCase()}`;
  if (scope === "global") {
    const lock = readGlobalLock();
    if (lock.skills[key]) {
      lock.skills[key].commit = commit;
      writeGlobalLock(lock);
    }
  } else {
    const lock = readProjectLock(cwd);
    if (lock.skills[key]) {
      lock.skills[key].commit = commit;
      writeProjectLock(cwd, lock);
    }
  }
}

export function removeTrackedItem(
  scope: "project" | "global",
  name: string,
  type: SkillType,
  cwd: string = process.cwd(),
) {
  const key = `${type}:${name.toLowerCase()}`;
  if (scope === "global") {
    const lock = readGlobalLock();
    delete lock.skills[key];
    writeGlobalLock(lock);
  } else {
    const lock = readProjectLock(cwd);
    delete lock.skills[key];
    writeProjectLock(cwd, lock);
  }
}
