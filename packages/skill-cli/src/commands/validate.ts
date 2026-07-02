import { writeFileSync } from "node:fs";
import type { ValidationReport } from "@skill-spark/skill-core/schemas";
import { resolveSkillTargets } from "@skill-spark/skill-core/skill-targets";
import { validateSkillDirectory } from "@skill-spark/skill-core/validation";
import pc from "picocolors";

export interface ValidateOptions {
  all?: boolean;
  branch?: string;
  skill?: string[];
  format?: string;
  output?: string;
  strict?: boolean;
}

function normalizedFormat(format: ValidateOptions["format"], output?: string) {
  if (format) {
    if (!["text", "json", "markdown", "md"].includes(format)) {
      throw new Error(`Unsupported format: ${format}`);
    }

    return format === "md" ? "markdown" : format;
  }

  if (output?.endsWith(".json")) {
    return "json";
  }

  if (output?.endsWith(".md") || output?.endsWith(".markdown")) {
    return "markdown";
  }

  return "text";
}

function reportSummary(report: ValidationReport) {
  const errors = report.issues.filter((issue) => issue.severity === "error").length;
  const warnings = report.issues.filter((issue) => issue.severity === "warning").length;
  return { errors, warnings };
}

function formatText(reports: ValidationReport[]) {
  const lines: string[] = [];

  for (const report of reports) {
    const { errors, warnings } = reportSummary(report);
    const color = report.status === "invalid" ? pc.red : report.status === "warning" ? pc.yellow : pc.green;
    lines.push(`${color(report.status.toUpperCase())} ${report.name ?? report.path}`);
    lines.push(`  path: ${report.path}`);
    lines.push(`  issues: ${errors} errors, ${warnings} warnings`);

    for (const issue of report.issues) {
      const icon = issue.severity === "error" ? pc.red("x") : issue.severity === "warning" ? pc.yellow("!") : "i";
      const location = [issue.file, issue.path].filter(Boolean).join(":");
      lines.push(`  ${icon} ${issue.code}${location ? ` (${location})` : ""}: ${issue.message}`);
    }

    lines.push("");
  }

  return lines.join("\n").trimEnd();
}

function formatMarkdown(reports: ValidationReport[]) {
  const lines: string[] = ["# Skill Validation Report", "", `Date: ${new Date().toISOString()}`, ""];

  for (const report of reports) {
    const { errors, warnings } = reportSummary(report);
    lines.push(`## ${report.name ?? report.path}`);
    lines.push("");
    lines.push(`- Status: ${report.status}`);
    lines.push(`- Path: ${report.path}`);
    lines.push(`- Issues: ${errors} errors, ${warnings} warnings`);
    lines.push("");

    if (report.issues.length > 0) {
      lines.push("| Severity | Code | Location | Message |");
      lines.push("| --- | --- | --- | --- |");
      for (const issue of report.issues) {
        const location = [issue.file, issue.path].filter(Boolean).join(":");
        lines.push(`| ${issue.severity} | ${issue.code} | ${location} | ${issue.message.replace(/\|/g, "\\|")} |`);
      }
      lines.push("");
    }
  }

  return lines.join("\n");
}

function shouldFail(reports: ValidationReport[], strict: boolean | undefined) {
  return reports.some((report) =>
    report.issues.some((issue) => issue.severity === "error" || (strict && issue.severity === "warning")),
  );
}

export async function runValidate(input: string, options: ValidateOptions) {
  const resolved = await resolveSkillTargets(input, {
    all: options.all,
    branch: options.branch,
    skills: options.skill,
  });

  try {
    if (resolved.targets.length === 0) {
      throw new Error("No skills found to validate.");
    }

    const reports = resolved.targets.map((target) => validateSkillDirectory(target.path));
    const format = normalizedFormat(options.format, options.output);
    const output =
      format === "json"
        ? JSON.stringify({ reports }, null, 2)
        : format === "markdown"
          ? formatMarkdown(reports)
          : formatText(reports);

    if (options.output) {
      writeFileSync(options.output, `${output}\n`, "utf-8");
    } else {
      console.log(output);
    }

    if (shouldFail(reports, options.strict)) {
      process.exitCode = 1;
    }
  } finally {
    await resolved.cleanup();
  }
}
