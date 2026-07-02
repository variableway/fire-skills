import { existsSync, statSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { discoverInstallables } from "./discovery";
import { resolveSourceBundle } from "./source-providers";

export interface ResolveSkillTargetsOptions {
  branch?: string;
  skills?: string[];
  all?: boolean;
}

export interface ResolvedSkillTarget {
  name: string;
  path: string;
  sourceLabel: string;
  sourceKind: string;
}

export interface ResolvedSkillTargets {
  targets: ResolvedSkillTarget[];
  cleanup(): Promise<void>;
}

function matchesSkillFilter(name: string, filters: string[] | undefined) {
  if (!filters || filters.length === 0) {
    return true;
  }

  return filters.some((filter) => filter.toLowerCase() === name.toLowerCase());
}

function skillRootFromDirectPath(input: string) {
  const path = resolve(input);
  if (!existsSync(path)) {
    return null;
  }

  const stats = statSync(path);
  if (stats.isFile() && basename(path).toLowerCase() === "skill.md") {
    return dirname(path);
  }

  if (stats.isDirectory() && existsSync(join(path, "SKILL.md"))) {
    return path;
  }

  return null;
}

export async function resolveSkillTargets(
  input: string,
  options: ResolveSkillTargetsOptions = {},
): Promise<ResolvedSkillTargets> {
  const directRoot = skillRootFromDirectPath(input);
  if (directRoot && !options.all && (!options.skills || options.skills.length === 0)) {
    return {
      targets: [
        {
          name: basename(directRoot),
          path: directRoot,
          sourceLabel: directRoot,
          sourceKind: "local",
        },
      ],
      async cleanup() {},
    };
  }

  const resolvedSource = await resolveSourceBundle(input, { branch: options.branch });
  const { bundle } = resolvedSource;
  const installables = discoverInstallables(bundle.root, bundle.subpath).filter(
    (installable) => installable.type === "skill" && matchesSkillFilter(installable.name, options.skills),
  );

  return {
    targets: installables.map((installable) => ({
      name: installable.name,
      path: installable.path,
      sourceLabel: bundle.label,
      sourceKind: resolvedSource.provider,
    })),
    cleanup: resolvedSource.cleanup,
  };
}
