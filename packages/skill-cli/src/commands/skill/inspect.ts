import { writeFileSync } from "node:fs";
import { inspectSkillDirectory } from "@skill-spark/skill-core/inspection";
import type { InspectionReport, RiskSignal } from "@skill-spark/skill-core/schemas";
import { resolveSkillTargets } from "@skill-spark/skill-core/skill-targets";
import pc from "picocolors";
import { normalizedFormat } from "../shared/format.js";

export const COMMAND_DESCRIPTION = "Inspect skills with deterministic rule-based risk and quality checks";
export const COMMAND_EXAMPLES = [
  "skill-spark inspect .",
  "skill-spark inspect skills/base --all --fail-on high",
  "skill-spark inspect . --skill my-skill --format markdown --output report.md",
];
export const COMMAND_PREREQUISITES = [
  "Target path must contain skills with SKILL.md files",
  "Git source must be accessible when using --branch",
];

export interface InspectOptions {
  all?: boolean;
  branch?: string;
  skill?: string[];
  mode?: string;
  viaSkill?: string;
  format?: string;
  output?: string;
  failOn?: string;
}

function riskRank(level: RiskSignal["level"]) {
  return { low: 0, medium: 1, high: 2, critical: 3 }[level];
}

function riskColor(level: RiskSignal["level"]) {
  if (level === "critical" || level === "high") {
    return pc.red(level);
  }
  if (level === "medium") {
    return pc.yellow(level);
  }
  return pc.green(level);
}

function formatText(reports: InspectionReport[]) {
  const lines: string[] = [];

  for (const report of reports) {
    lines.push(`${pc.bold(report.name ?? report.path)} ${pc.dim(report.path)}`);
    lines.push(`  risk: ${riskColor(report.riskLevel)}`);
    lines.push(`  quality: ${report.qualityScore}/100`);
    lines.push(`  portability: ${report.portabilityScore}/100`);
    lines.push(
      `  files: scripts=${report.summary.scriptCount}, references=${report.summary.referenceCount}, assets=${report.summary.assetCount}, lines=${report.summary.lineCount}`,
    );

    const validationErrors = report.validation.issues.filter((issue) => issue.severity === "error").length;
    const validationWarnings = report.validation.issues.filter((issue) => issue.severity === "warning").length;
    lines.push(
      `  validation: ${report.validation.status} (${validationErrors} errors, ${validationWarnings} warnings)`,
    );

    for (const signal of report.riskSignals) {
      lines.push(
        `  ${riskColor(signal.level)} ${signal.code}${signal.file ? ` (${signal.file})` : ""}: ${signal.message}`,
      );
    }

    lines.push("");
  }

  return lines.join("\n").trimEnd();
}

function formatMarkdown(reports: InspectionReport[]) {
  const lines: string[] = ["# Skill Inspect Report", "", `Date: ${new Date().toISOString()}`, ""];

  for (const report of reports) {
    lines.push(`## ${report.name ?? report.path}`);
    lines.push("");
    lines.push(`- Path: ${report.path}`);
    lines.push(`- Risk: ${report.riskLevel}`);
    lines.push(`- Quality: ${report.qualityScore}/100`);
    lines.push(`- Portability: ${report.portabilityScore}/100`);
    lines.push(`- Validation: ${report.validation.status}`);
    lines.push(
      `- Files: scripts=${report.summary.scriptCount}, references=${report.summary.referenceCount}, assets=${report.summary.assetCount}, lines=${report.summary.lineCount}`,
    );
    lines.push("");

    if (report.riskSignals.length > 0) {
      lines.push("| Risk | Code | File | Message |");
      lines.push("| --- | --- | --- | --- |");
      for (const signal of report.riskSignals) {
        lines.push(
          `| ${signal.level} | ${signal.code} | ${signal.file ?? ""} | ${signal.message.replace(/\|/g, "\\|")} |`,
        );
      }
      lines.push("");
    }
  }

  return lines.join("\n");
}

function shouldFail(reports: InspectionReport[], failOn?: RiskSignal["level"]) {
  if (!failOn) {
    return false;
  }

  return reports.some((report) => riskRank(report.riskLevel) >= riskRank(failOn));
}

function normalizeRiskLevel(value: string | undefined) {
  if (!value) {
    return undefined;
  }

  if (!["low", "medium", "high", "critical"].includes(value)) {
    throw new Error(`Unsupported risk level: ${value}`);
  }

  return value as RiskSignal["level"];
}

export async function runInspect(input: string, options: InspectOptions) {
  if (options.mode && options.mode !== "rules") {
    throw new Error("Only inspect --mode rules is implemented in Phase 0-1.");
  }

  if (options.viaSkill) {
    throw new Error("inspect --via-skill is not implemented yet. Use --mode rules for deterministic inspect-lite.");
  }

  const resolved = await resolveSkillTargets(input, {
    all: options.all,
    branch: options.branch,
    skills: options.skill,
  });

  try {
    if (resolved.targets.length === 0) {
      throw new Error("No skills found to inspect.");
    }

    const reports = resolved.targets.map((target) => inspectSkillDirectory(target.path));
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

    if (shouldFail(reports, normalizeRiskLevel(options.failOn))) {
      process.exitCode = 1;
    }
  } finally {
    await resolved.cleanup();
  }
}
