import { readFileSync } from "node:fs";
import { dirname } from "node:path";
import { type SkillFrontmatter, SkillFrontmatterSchema, type ValidationIssue } from "@skill-spark/skill-schemas";
import { parseDocument } from "yaml";

export interface ParsedSkillMarkdown {
  filePath: string;
  root: string;
  content: string;
  body: string;
  frontmatterRaw?: string;
  frontmatter: SkillFrontmatter;
  hasFrontmatter: boolean;
  issues: ValidationIssue[];
}

export function extractFrontmatter(content: string) {
  const normalized = content.replace(/\r\n/g, "\n");
  const match = normalized.match(/^---\n([\s\S]*?)\n---(?:\n|$)/);

  if (!match) {
    return {
      body: normalized,
      frontmatterRaw: undefined,
      hasFrontmatter: false,
    };
  }

  return {
    body: normalized.slice(match[0].length),
    frontmatterRaw: match[1] ?? "",
    hasFrontmatter: true,
  };
}

function frontmatterIssue(message: string): ValidationIssue {
  return {
    severity: "error",
    code: "frontmatter-yaml",
    message,
    file: "SKILL.md",
  };
}

export function parseFrontmatter(raw: string | undefined) {
  if (raw === undefined) {
    return {
      frontmatter: {},
      issues: [] as ValidationIssue[],
    };
  }

  const document = parseDocument(raw, {
    prettyErrors: false,
  });
  const issues: ValidationIssue[] = [];

  for (const error of document.errors) {
    issues.push(frontmatterIssue(error.message));
  }

  for (const warning of document.warnings) {
    issues.push({
      severity: "warning",
      code: "frontmatter-yaml-warning",
      message: warning.message,
      file: "SKILL.md",
    });
  }

  const data = document.toJSON();
  if (data !== null && (typeof data !== "object" || Array.isArray(data))) {
    issues.push(frontmatterIssue("YAML frontmatter must be a mapping object."));
    return {
      frontmatter: {},
      issues,
    };
  }

  const parsed = SkillFrontmatterSchema.safeParse(data ?? {});
  if (!parsed.success) {
    for (const issue of parsed.error.issues) {
      issues.push({
        severity: "error",
        code: "frontmatter-schema",
        message: issue.message,
        path: issue.path.join("."),
        file: "SKILL.md",
      });
    }

    return {
      frontmatter: {},
      issues,
    };
  }

  return {
    frontmatter: parsed.data,
    issues,
  };
}

export function parseSkillMarkdownFile(filePath: string): ParsedSkillMarkdown {
  const content = readFileSync(filePath, "utf-8");
  const extracted = extractFrontmatter(content);
  const parsed = parseFrontmatter(extracted.frontmatterRaw);

  return {
    filePath,
    root: dirname(filePath),
    content,
    body: extracted.body,
    frontmatterRaw: extracted.frontmatterRaw,
    frontmatter: parsed.frontmatter,
    hasFrontmatter: extracted.hasFrontmatter,
    issues: parsed.issues,
  };
}

export function fallbackDescription(markdownBody: string) {
  return (
    markdownBody
      .split("\n")
      .map((line) => line.trim())
      .find((line) => line && !line.startsWith("#") && !line.startsWith("---")) ?? "No description found."
  )
    .replace(/^>\s*/, "")
    .trim();
}
