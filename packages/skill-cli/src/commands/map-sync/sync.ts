import { existsSync, readdirSync } from "node:fs";
import { join, resolve } from "node:path";
import {
  type AgentName,
  type AgentScope,
  agents,
  getAgentNames,
  normalizeAgentNames,
  resolveAgentSkillsDir,
} from "@skill-spark/skill-core/agents";
import { discoverInstallables } from "@skill-spark/skill-core/discovery";
import { installInstallable } from "@skill-spark/skill-core/installations";
import { cleanupSource, downloadSource } from "@skill-spark/skill-core/sources";
import { trackInstall } from "@skill-spark/skill-core/state";
import { printJson } from "../../utils/json";
import { detectRoot } from "../../utils/root";

export const COMMAND_DESCRIPTION = "Sync skills from a source directory to target AI agent skill folders";
export const COMMAND_EXAMPLES = [
  "skill-spark sync",
  "skill-spark sync --source skills/base --agent codex",
  "skill-spark sync --skill my-skill --global --no-symlink",
];
export const COMMAND_PREREQUISITES = [
  "Source directory must contain skills with valid SKILL.md files",
  "Target agents must be configured in skill-spark",
];

export interface SyncCommandOptions {
  source?: string;
  agent?: string[];
  skill?: string[];
  global?: boolean;
  yes?: boolean;
  force?: boolean;
  output?: string;
  symlink?: boolean;
}

const defaultSyncAgents: AgentName[] = ["codex", "claude-code", "opencode", "trae", "kimi-cli"];

function dedupeSkillTargets(targets: AgentName[], scope: AgentScope, root: string) {
  const seen = new Set<string>();
  const deduped: AgentName[] = [];

  for (const agent of targets) {
    const directory = resolve(resolveAgentSkillsDir(agent, scope, root));
    const key = process.platform === "win32" ? directory.toLowerCase() : directory;
    if (seen.has(key)) {
      continue;
    }

    seen.add(key);
    deduped.push(agent);
  }

  return deduped;
}

function resolveSyncSource(root: string, source?: string) {
  const value = source?.trim() || "skills/base";
  if (existsSync(value)) {
    return value;
  }

  const rootRelative = resolve(root, value);
  return existsSync(rootRelative) ? rootRelative : value;
}

export async function runSync(options: SyncCommandOptions): Promise<void> {
  const { root } = detectRoot(process.cwd());
  const sourceValue = resolveSyncSource(root, options.source);
  const targetValues = options.agent && options.agent.length > 0 ? options.agent : defaultSyncAgents;
  const parsed = normalizeAgentNames(targetValues);

  if (parsed.invalid.length > 0) {
    console.error(`Error: Invalid agents: ${parsed.invalid.join(", ")}`);
    console.error(`Supported agents: ${getAgentNames().join(", ")}`);
    process.exit(1);
  }

  const scope: AgentScope = options.global ? "global" : "project";
  const targetAgents = dedupeSkillTargets(parsed.agents, scope, root);
  const source = await downloadSource(sourceValue);

  try {
    const discovered = discoverInstallables(source.root, source.subpath);
    let skills = discovered.filter((item) => item.type === "skill");

    if (options.skill && options.skill.length > 0) {
      const wanted = new Set(options.skill.map((name) => name.toLowerCase()));
      skills = skills.filter((item) => wanted.has(item.name.toLowerCase()));

      if (skills.length === 0) {
        printJson({
          schemaVersion: "1",
          source: source.label,
          synced: 0,
          error: `No matching skills found for: ${options.skill.join(", ")}`,
          availableSkills: discovered.filter((item) => item.type === "skill").map((item) => item.name),
        });
        process.exit(1);
      }
    }

    if (skills.length === 0) {
      printJson({
        schemaVersion: "1",
        source: source.label,
        synced: 0,
        error: "No skills found in source",
      });
      process.exit(1);
    }

    const symlink = options.symlink ?? true;
    const results = [];

    for (const skill of skills) {
      let successCount = 0;

      for (const agent of targetAgents) {
        const outcome = installInstallable(skill, agent, scope, { symlink, cwd: root });
        results.push({
          skill: skill.name,
          agent,
          agentLabel: agents[agent].label,
          scope,
          path: outcome.path,
          success: outcome.success,
          error: outcome.error,
        });

        if (outcome.success) {
          successCount += 1;
        }
      }

      if (successCount > 0) {
        trackInstall(
          {
            name: skill.name,
            type: skill.type,
            scope,
            url: source.url,
            subpath: source.subpath,
            branch: source.branch,
            commit: source.commit,
          },
          root,
        );
      }
    }

    const failed = results.filter((result) => !result.success);
    printJson({
      schemaVersion: "1",
      source: source.label,
      scope,
      requestedTargets: parsed.agents,
      targets: targetAgents,
      skills: skills.map((skill) => skill.name),
      synced: results.length - failed.length,
      failed: failed.length,
      results,
    });

    if (failed.length > 0) {
      process.exit(1);
    }
  } finally {
    await cleanupSource(source);
  }
}
