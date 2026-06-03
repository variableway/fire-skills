import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join, sep } from "node:path";

export function ensureDir(path: string) {
  mkdirSync(path, { recursive: true });
}

export function readJsonFile<T>(path: string): T | null {
  if (!existsSync(path)) {
    return null;
  }
  try {
    const content = readFileSync(path, "utf-8");
    return JSON.parse(content) as T;
  } catch {
    return null;
  }
}

export function writeJsonFile(path: string, data: unknown) {
  ensureDir(path);
  const parent = join(path, "..");
  ensureDir(parent);
  writeFileSync(path, JSON.stringify(data, null, 2) + "\n", "utf-8");
}

export function isPathInside(target: string, base: string): boolean {
  const absTarget = join(target);
  const absBase = join(base);
  return absTarget === absBase || absTarget.startsWith(absBase + sep);
}