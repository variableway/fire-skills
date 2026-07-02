import { type Dirent, existsSync, readdirSync, statSync } from "node:fs";
import { basename, dirname, extname, join, relative, resolve } from "node:path";
import {
  RequiredSkillFrontmatterSchema,
  type ValidationIssue,
  type ValidationReport,
  ValidationReportSchema,
} from "@skill-spark/skill-schemas";
import { parseSkillMarkdownFile } from "./skill-parser";

const ignoredLinkPrefixes = ["http:", "https:", "mailto:", "#", "data:"];
const fileReferenceKeys = ["references", "resources", "files", "scripts"];

function issue(severity: ValidationIssue["severity"], code: string, message: string, file?: string, path?: string) {
  return { severity, code, message, file, path } satisfies ValidationIssue;
}

function isInside(parent: string, child: string) {
  const relativePath = relative(parent, child);
  return (
    relativePath === "" || (!relativePath.startsWith("..") && !relativePath.startsWith("/") && relativePath !== "..")
  );
}

function normalizeReferenceTarget(rawTarget: string) {
  let target = rawTarget.trim();
  if (!target || ignoredLinkPrefixes.some((prefix) => target.toLowerCase().startsWith(prefix))) {
    return null;
  }

  if (target.startsWith("<") && target.endsWith(">")) {
    target = target.slice(1, -1).trim();
  }

  const titleMatch = target.match(/^(.*?)(?:\s+["'].*["'])$/);
  if (titleMatch?.[1]) {
    target = titleMatch[1].trim();
  }

  target = target.split("#")[0]?.trim() ?? "";
  if (!target || ignoredLinkPrefixes.some((prefix) => target.toLowerCase().startsWith(prefix))) {
    return null;
  }

  try {
    return decodeURIComponent(target);
  } catch {
    return target;
  }
}

function markdownReferences(body: string) {
  const targets = new Set<string>();
  const linkPattern = /!?\[[^\]]*\]\(([^)]+)\)/g;
  for (const match of body.matchAll(linkPattern)) {
    const target = normalizeReferenceTarget(match[1] ?? "");
    if (target) {
      targets.add(target);
    }
  }

  return [...targets];
}

function frontmatterReferences(frontmatter: Record<string, unknown>) {
  const targets = new Set<string>();

  for (const key of fileReferenceKeys) {
    const value = frontmatter[key];
    if (typeof value === "string") {
      const target = normalizeReferenceTarget(value);
      if (target) {
        targets.add(target);
      }
      continue;
    }

    if (Array.isArray(value)) {
      for (const item of value) {
        if (typeof item === "string") {
          const target = normalizeReferenceTarget(item);
          if (target) {
            targets.add(target);
          }
        }
      }
    }
  }

  return [...targets];
}

function validateReferences(skillRoot: string, references: string[]) {
  const issues: ValidationIssue[] = [];

  for (const reference of references) {
    const targetPath = resolve(skillRoot, reference);
    if (!isInside(skillRoot, targetPath)) {
      issues.push(
        issue(
          "warning",
          "reference-outside-skill",
          `Reference leaves the skill directory and may reduce portability: ${reference}`,
          "SKILL.md",
        ),
      );
      continue;
    }

    if (!existsSync(targetPath)) {
      issues.push(issue("warning", "reference-missing", `Referenced file does not exist: ${reference}`, "SKILL.md"));
    }
  }

  return issues;
}

function collectFiles(root: string) {
  const files: string[] = [];

  function walk(path: string) {
    let entries: Dirent[];
    try {
      entries = readdirSync(path, { withFileTypes: true });
    } catch {
      return;
    }

    for (const entry of entries) {
      if (entry.name === "node_modules" || entry.name === ".git") {
        continue;
      }

      const child = join(path, entry.name);
      if (entry.isDirectory()) {
        walk(child);
        continue;
      }

      if (entry.isFile()) {
        files.push(child);
      }
    }
  }

  walk(root);
  return files;
}

function validateFileLayout(skillRoot: string) {
  const issues: ValidationIssue[] = [];
  const files = collectFiles(skillRoot);

  for (const file of files) {
    const relativePath = relative(skillRoot, file);
    if (relativePath.includes("..")) {
      issues.push(issue("error", "path-traversal", `Unexpected file outside skill root: ${relativePath}`));
    }

    const extension = extname(file).toLowerCase();
    if (extension === ".exe" || extension === ".dll" || extension === ".dylib" || extension === ".so") {
      issues.push(issue("warning", "binary-file", `Binary executable-like file found: ${relativePath}`, relativePath));
    }
  }

  return issues;
}

export function countFiles(root: string) {
  if (!existsSync(root)) {
    return 0;
  }

  const stats = statSync(root);
  if (!stats.isDirectory()) {
    return 0;
  }

  return collectFiles(root).length;
}

export function validateSkillDirectory(skillRoot: string): ValidationReport {
  const skillPath = join(skillRoot, "SKILL.md");
  const issues: ValidationIssue[] = [];
  let name: string | undefined;
  let description: string | undefined;

  if (!existsSync(skillPath)) {
    return ValidationReportSchema.parse({
      path: skillRoot,
      status: "invalid",
      issues: [issue("error", "missing-skill-md", "Missing SKILL.md.", "SKILL.md")],
    });
  }

  try {
    const parsed = parseSkillMarkdownFile(skillPath);
    issues.push(...parsed.issues);

    if (!parsed.hasFrontmatter) {
      issues.push(
        issue("warning", "missing-frontmatter", "SKILL.md does not start with YAML frontmatter.", "SKILL.md"),
      );
    }

    const required = RequiredSkillFrontmatterSchema.safeParse(parsed.frontmatter);
    if (!required.success) {
      for (const zodIssue of required.error.issues) {
        issues.push(issue("error", "frontmatter-required", zodIssue.message, "SKILL.md", zodIssue.path.join(".")));
      }
    } else {
      name = required.data.name;
      description = required.data.description;

      if (name !== name.toLowerCase()) {
        issues.push(issue("warning", "name-lowercase", "Skill name should be lowercase kebab-case.", "SKILL.md"));
      }

      if (name.toLowerCase() !== basename(skillRoot).toLowerCase()) {
        issues.push(
          issue(
            "warning",
            "name-directory-mismatch",
            `Skill name '${name}' does not match directory '${basename(skillRoot)}'.`,
            "SKILL.md",
          ),
        );
      }

      if (description.length > 1024) {
        issues.push(
          issue("warning", "description-long", "Skill description is longer than 1024 characters.", "SKILL.md"),
        );
      }
    }

    issues.push(
      ...validateReferences(skillRoot, [
        ...markdownReferences(parsed.body),
        ...frontmatterReferences(parsed.frontmatter),
      ]),
    );
    issues.push(...validateFileLayout(skillRoot));
  } catch (error) {
    issues.push(
      issue(
        "error",
        "skill-read-failed",
        error instanceof Error ? error.message : "Unable to read SKILL.md.",
        "SKILL.md",
      ),
    );
  }

  const status = issues.some((item) => item.severity === "error")
    ? "invalid"
    : issues.some((item) => item.severity === "warning")
      ? "warning"
      : "valid";

  return ValidationReportSchema.parse({
    path: skillRoot,
    name,
    description,
    status,
    issues,
  });
}

export function validateSkillFile(skillFile: string) {
  return validateSkillDirectory(dirname(skillFile));
}
