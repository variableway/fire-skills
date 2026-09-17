import { urlKey } from "../git/repo.ts";
import type { Project } from "../store/types.ts";
import { extraFields, sectionOf, type SectionRules } from "../store/yaml.ts";
import type { MergeStats } from "./constants.ts";

export function merge(
  existing: Project[],
  discovered: Project[],
  keepMissing = false,
  descBySection: Record<string, string> = {},
  sectionRules: SectionRules = {},
): { final: Project[]; changes: MergeStats } {
  const discoveredByPath = new Map(discovered.map((p) => [p.path, p]));
  const discoveredByUrl = new Map(discovered.map((p) => [urlKey(p.repo), p]));

  const final: Project[] = [];
  const matchedPaths = new Set<string>();
  const moved: string[] = [];
  const missing: Project[] = [];

  for (const old of existing) {
    let next = discoveredByPath.get(old.path ?? "");
    if (!next) next = discoveredByUrl.get(urlKey(old.repo ?? ""));
    if (next) {
      const entry: Project = { ...next };
      if (old.name) entry.name = old.name;
      if (old.desc) entry.desc = old.desc;
      else if (!entry.desc) entry.desc = descBySection[sectionOf(entry.path, sectionRules)] ?? "";
      Object.assign(entry, extraFields(old));
      if (next.path !== old.path) moved.push(`${old.path} -> ${next.path}`);
      final.push(entry);
      matchedPaths.add(next.path);
    } else {
      missing.push(old);
      if (keepMissing) final.push(old);
    }
  }

  const added: Project[] = [];
  const dup: string[] = [];
  const finalUrls = new Set(final.map((p) => urlKey(p.repo)));
  for (const p of discovered) {
    if (matchedPaths.has(p.path)) continue;
    const key = urlKey(p.repo);
    if (finalUrls.has(key)) {
      dup.push(p.path);
      continue;
    }
    finalUrls.add(key);
    if (!p.desc) p.desc = descBySection[sectionOf(p.path, sectionRules)] ?? "";
    added.push(p);
    final.push(p);
  }

  return { final, changes: { moved, missing, added, dup } };
}
