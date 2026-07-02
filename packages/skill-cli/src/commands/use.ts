import { writeFileSync } from "node:fs";
import { join } from "node:path";
import { inspectSkillDirectory } from "@skill-spark/skill-core/inspection";
import { parseSkillMarkdownFile } from "@skill-spark/skill-core/skill-parser";
import { resolveSkillTargets } from "@skill-spark/skill-core/skill-targets";

export interface UseOptions {
  branch?: string;
  skill?: string[];
  objective?: string;
  agent?: string;
  format?: string;
  output?: string;
}

function normalizedFormat(format: UseOptions["format"], output?: string) {
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

function taskPacketText(packet: ReturnType<typeof buildTaskPacket>) {
  const lines: string[] = [];
  lines.push(`# Skill Task Packet`);
  lines.push("");
  lines.push(`Objective: ${packet.objective}`);
  lines.push(`Agent: ${packet.agent}`);
  lines.push("");

  for (const skill of packet.skills) {
    lines.push(`## ${skill.name}`);
    lines.push(skill.description ? `Description: ${skill.description}` : "Description: n/a");
    lines.push(`Source: ${skill.source}`);
    lines.push(`Risk: ${skill.inspect.riskLevel}`);
    lines.push("");
    lines.push(skill.body.trim());
    lines.push("");
  }

  return lines.join("\n");
}

function buildTaskPacket(
  input: string,
  objective: string,
  agent: string,
  targets: Array<{ name: string; path: string; sourceLabel: string; sourceKind: string }>,
) {
  return {
    schemaVersion: "skill-spark.task-packet.v1",
    createdAt: new Date().toISOString(),
    objective,
    agent,
    source: input,
    skills: targets.map((target) => {
      const parsed = parseSkillMarkdownFile(join(target.path, "SKILL.md"));
      return {
        name: parsed.frontmatter.name ?? target.name,
        description: parsed.frontmatter.description,
        source: target.sourceLabel,
        sourceKind: target.sourceKind,
        path: target.path,
        body: parsed.body,
        inspect: inspectSkillDirectory(target.path),
      };
    }),
  };
}

export async function runUse(input: string, options: UseOptions) {
  const resolved = await resolveSkillTargets(input, {
    branch: options.branch,
    skills: options.skill,
  });

  try {
    if (resolved.targets.length === 0) {
      throw new Error("No skills found to use.");
    }

    const objective = options.objective ?? "Use the selected skill(s) to help with the user's task.";
    const packet = buildTaskPacket(input, objective, options.agent ?? "manual", resolved.targets);
    const format = normalizedFormat(options.format, options.output);
    const output =
      format === "json"
        ? JSON.stringify(packet, null, 2)
        : format === "markdown"
          ? taskPacketText(packet)
          : taskPacketText(packet);

    if (options.output) {
      writeFileSync(options.output, `${output}\n`, "utf-8");
    } else {
      console.log(output);
    }
  } finally {
    await resolved.cleanup();
  }
}
