import { type Dirent, existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { extname, join, relative } from "node:path";
import { type InspectionReport, InspectionReportSchema, type RiskSignal } from "@skill-spark/skill-schemas";
import { parseSkillMarkdownFile } from "./skill-parser";
import { countFiles, validateSkillDirectory } from "./validation";

interface RiskRule {
  level: RiskSignal["level"];
  code: string;
  message: string;
  pattern: RegExp;
}

const riskRules: RiskRule[] = [
  {
    level: "critical",
    code: "destructive-rm-rf",
    message: "Mentions destructive rm -rf usage.",
    pattern: /\brm\s+-rf\b/i,
  },
  {
    level: "high",
    code: "curl-pipe-shell",
    message: "Mentions piping curl or wget directly into a shell.",
    pattern: /\b(?:curl|wget)\b[\s\S]{0,120}\|\s*(?:bash|sh|zsh)\b/i,
  },
  {
    level: "high",
    code: "git-reset-hard",
    message: "Mentions git reset --hard.",
    pattern: /\bgit\s+reset\s+--hard\b/i,
  },
  {
    level: "high",
    code: "git-push-force",
    message: "Mentions force-pushing Git history.",
    pattern: /\bgit\s+push\b[^\n]*(?:--force|-f)\b/i,
  },
  {
    level: "high",
    code: "credential-assignment",
    message: "Mentions possible credential assignment.",
    pattern: /\b(?:api[_-]?key|token|password|secret)\s*=/i,
  },
  {
    level: "medium",
    code: "sudo-command",
    message: "Mentions sudo usage.",
    pattern: /\bsudo\s+/i,
  },
  {
    level: "medium",
    code: "chmod-777",
    message: "Mentions chmod 777.",
    pattern: /\bchmod\s+777\b/i,
  },
  {
    level: "medium",
    code: "external-write-github",
    message: "Mentions GitHub operations that may mutate external state.",
    pattern: /\bgh\s+(?:pr\s+merge|issue\s+close|release\s+create)\b/i,
  },
  {
    level: "medium",
    code: "workflow-write",
    message: "Mentions writing GitHub Actions workflow files.",
    pattern: /\.github\/workflows\//i,
  },
];

function collectTextFiles(root: string) {
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

      if (!entry.isFile()) {
        continue;
      }

      const extension = extname(child).toLowerCase();
      if ([".md", ".txt", ".json", ".yaml", ".yml", ".js", ".mjs", ".ts", ".sh", ".py"].includes(extension)) {
        files.push(child);
      }
    }
  }

  walk(root);
  return files;
}

function riskRank(level: RiskSignal["level"]) {
  return { low: 0, medium: 1, high: 2, critical: 3 }[level];
}

function highestRisk(signals: RiskSignal[]): RiskSignal["level"] {
  return signals.reduce<RiskSignal["level"]>(
    (current, signal) => (riskRank(signal.level) > riskRank(current) ? signal.level : current),
    "low",
  );
}

function inspectRisks(skillRoot: string) {
  const signals: RiskSignal[] = [];

  for (const file of collectTextFiles(skillRoot)) {
    let content = "";
    try {
      const stats = statSync(file);
      if (stats.size > 1024 * 1024) {
        continue;
      }
      content = readFileSync(file, "utf-8");
    } catch {
      continue;
    }

    for (const rule of riskRules) {
      if (rule.pattern.test(content)) {
        signals.push({
          level: rule.level,
          code: rule.code,
          message: rule.message,
          file: relative(skillRoot, file),
        });
      }
    }
  }

  return signals;
}

function scoreQuality(report: ReturnType<typeof validateSkillDirectory>, body: string) {
  let score = 100;
  score -= report.issues.filter((issue) => issue.severity === "error").length * 25;
  score -= report.issues.filter((issue) => issue.severity === "warning").length * 8;

  if (!/\buse when\b|\bwhen to use\b|使用场景|适用/i.test(body)) {
    score -= 10;
  }

  if (body.trim().length < 200) {
    score -= 10;
  }

  return Math.max(0, Math.min(100, score));
}

function scorePortability(skillRoot: string, signals: RiskSignal[]) {
  let score = 100;
  if (existsSync(join(skillRoot, "scripts"))) {
    score -= 10;
  }
  if (signals.some((signal) => signal.code === "sudo-command")) {
    score -= 15;
  }
  if (signals.some((signal) => signal.code === "workflow-write" || signal.code === "external-write-github")) {
    score -= 10;
  }
  if (signals.some((signal) => signal.level === "critical")) {
    score -= 30;
  } else if (signals.some((signal) => signal.level === "high")) {
    score -= 20;
  }
  return Math.max(0, Math.min(100, score));
}

export function inspectSkillDirectory(skillRoot: string): InspectionReport {
  const validation = validateSkillDirectory(skillRoot);
  const skillPath = join(skillRoot, "SKILL.md");
  const parsed = existsSync(skillPath) ? parseSkillMarkdownFile(skillPath) : null;
  const riskSignals = inspectRisks(skillRoot);
  const body = parsed?.body ?? "";
  const lineCount = parsed?.content.split(/\r?\n/).length ?? 0;

  return InspectionReportSchema.parse({
    path: skillRoot,
    name: validation.name,
    description: validation.description,
    riskLevel: highestRisk(riskSignals),
    qualityScore: scoreQuality(validation, body),
    portabilityScore: scorePortability(skillRoot, riskSignals),
    validation,
    riskSignals,
    summary: {
      hasFrontmatter: Boolean(parsed?.hasFrontmatter),
      hasScripts: existsSync(join(skillRoot, "scripts")),
      hasReferences: existsSync(join(skillRoot, "references")),
      scriptCount: countFiles(join(skillRoot, "scripts")),
      referenceCount: countFiles(join(skillRoot, "references")),
      assetCount: countFiles(join(skillRoot, "assets")),
      lineCount,
    },
  });
}
