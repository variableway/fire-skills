import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { parse as parseYaml } from "yaml";
import { BASE_FIELDS, type Project } from "./types.ts";

export function extraFields(entry: Project): Record<string, unknown> {
  const extra: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(entry)) {
    if (!(BASE_FIELDS as readonly string[]).includes(k)) extra[k] = v;
  }
  return extra;
}

export function yamlScalar(value: unknown): string {
  const s = String(value);
  if (s && ("@`&*!|>%\"'{}[],".includes(s[0]) || s.includes(":") || s.includes("#") || s.includes(" "))) {
    return `"${s.replaceAll("\\", "\\\\").replaceAll('"', '\\"')}"`;
  }
  return s;
}

export function writeExtraFields(entry: Project): string[] {
  const lines: string[] = [];
  for (const [k, v] of Object.entries(extraFields(entry))) {
    if (Array.isArray(v)) {
      lines.push(`    ${k}: [${v.map((i) => yamlScalar(i)).join(", ")}]`);
    } else {
      lines.push(`    ${k}: ${yamlScalar(v)}`);
    }
  }
  return lines;
}

export type SectionRules = {
  secondOnly?: string[];
  keepPrefix?: string[];
};

export function sectionOf(path: string, rules: SectionRules = {}): string {
  const parts = path.split("/");
  const head = parts[0] ?? "";
  if (parts.length > 1 && (rules.secondOnly ?? []).includes(head)) return parts[1] ?? head;
  if (parts.length > 1 && (rules.keepPrefix ?? []).includes(head)) return `${head}/${parts[1]}`;
  return head;
}

export function readExisting(registry: string): Project[] {
  if (!existsSync(registry)) return [];
  const raw = readFileSync(registry, "utf8");
  const data = parseYaml(raw) as { projects?: Project[] } | null;
  return data?.projects ?? [];
}

export function writeRegistry(
  projects: Project[],
  registry: string,
  syncedBy = "skill-spark registry scan",
  consumedBy: string | null = "skill-spark registry clone",
  sectionRules: SectionRules = {},
): void {
  const order: string[] = [];
  const groups = new Map<string, Project[]>();
  for (const p of projects) {
    const key = sectionOf(p.path ?? "", sectionRules);
    if (!groups.has(key)) {
      groups.set(key, []);
      order.push(key);
    }
    groups.get(key)!.push(p);
  }

  const lines = [
    "# Project registry",
    `# Synced by ${syncedBy}: source of truth is actual dir contents; entries are added/moved/deleted and desc is preserved`,
  ];
  if (consumedBy) {
    lines.push(`# ${consumedBy} reads this file and clones each project into its path field`);
  }
  lines.push("", "projects:");

  for (const key of order) {
    lines.push(`  # === ${key} ===`);
    for (const p of groups.get(key) ?? []) {
      lines.push(`  - name: ${p.name}`);
      lines.push(`    repo: ${p.repo}`);
      lines.push(`    path: ${p.path}`);
      if (p.desc) lines.push(`    desc: ${p.desc}`);
      lines.push(...writeExtraFields(p));
      lines.push("");
    }
  }

  if (lines.at(-1) === "") lines.pop();
  writeFileSync(registry, `${lines.join("\n")}\n`, "utf8");
}
