import { lstatSync } from "node:fs";
import { join } from "node:path";
import { findInstallations, type InstallationRecord } from "./installations";
import { listTrackedItems, type TrackedItem } from "./state";
import { getLatestCommit } from "./sources";

export interface TrackedItemStatus extends TrackedItem {
  validInstallations: InstallationRecord[];
  missingInstallations: InstallationRecord[];
  status: "latest" | "update-available" | "orphaned" | "error";
  latestCommit?: string;
}

export function id(item: TrackedItem) {
  return `${item.scope}:${item.type}:${item.name.toLowerCase()}`;
}

function isValidSkillPath(path: string): boolean {
  try {
    const stats = lstatSync(path);
    return (stats.isDirectory() || stats.isSymbolicLink()) && lstatSync(join(path, "SKILL.md")).isFile();
  } catch {
    return false;
  }
}

function isValidCommandPath(path: string): boolean {
  try {
    const stats = lstatSync(path);
    return (stats.isFile() || stats.isSymbolicLink()) && path.toLowerCase().endsWith(".md");
  } catch {
    return false;
  }
}

export function scanTracked(names?: string[], cwd: string = process.cwd()): TrackedItemStatus[] {
  const items = listTrackedItems(cwd).filter((item) => {
    if (!names || names.length === 0) {
      return true;
    }
    return names.some((name) => item.name.toLowerCase() === name.toLowerCase());
  });

  return items.map((item) => {
    const installations = findInstallations(item.name, item.type, item.scope, cwd);

    const validInstallations = installations.filter((inst) => {
      if (item.type === "skill") {
        return isValidSkillPath(inst.path);
      }
      return isValidCommandPath(inst.path);
    });

    const missingInstallations = installations.filter((inst) => !validInstallations.some((v) => v.path === inst.path));

    return {
      ...item,
      validInstallations,
      missingInstallations,
      status: validInstallations.length > 0 ? ("latest" as const) : ("orphaned" as const),
    };
  });
}

export async function hydrateTracked(
  items: TrackedItemStatus[],
  cwd: string = process.cwd(),
): Promise<TrackedItemStatus[]> {
  return Promise.all(
    items.map(async (item) => {
      if (item.validInstallations.length === 0) {
        return { ...item, status: "orphaned" as const };
      }

      if (item.url?.startsWith("well-known:")) {
        return { ...item, status: "latest" as const };
      }

      try {
        const latestCommit = await getLatestCommit(item.url, item.branch);
        if (latestCommit && latestCommit !== item.commit) {
          return { ...item, status: "update-available" as const, latestCommit };
        }
        return { ...item, status: "latest" as const, latestCommit };
      } catch {
        return { ...item, status: "error" as const };
      }
    }),
  );
}
