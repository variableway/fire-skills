import { existsSync, readdirSync } from "fs";
import { join, resolve } from "path";
import { homedir } from "os";
import {
  agents,
  getAgentNames,
  normalizeAgentNames,
  resolveAgentSkillsDir,
  type AgentName,
  type AgentScope,
} from "../core/agents";
import { discoverInstallables } from "../core/discovery";
import { installInstallable } from "../core/installations";
import { printJson } from "../utils/json";
import { detectRoot } from "../utils/root";
import { mapSkill } from "../core/mapping";
import { cleanupSource, downloadSource } from "../core/sources";
import { trackInstall } from "../core/state";
import type { TargetEnvironment } from "../core/types";

export interface MapCommandOptions {
  target?: string;
  global?: boolean;
  universal?: boolean;
  forceMap?: boolean;
}

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

export async function runMap(options: MapCommandOptions): Promise<void> {
  if (!options.target) {
    console.error("Error: --target is required");
    process.exit(1);
  }

  const target = options.target as TargetEnvironment;
  if (!["codex", "gemini", "claude", "agent", "qwen"].includes(target)) {
    console.error(`Error: Invalid target '${target}'. Valid options: codex, gemini, claude, agent, qwen`);
    process.exit(1);
  }

  const { root } = detectRoot(process.cwd());

  let sourceBase: string;
  if (options.global) {
    sourceBase = join(homedir(), ".skill-spark/skills");
  } else if (options.universal) {
    sourceBase = join(root, ".agents/skills");
  } else {
    sourceBase = join(root, ".claude/skills");
  }

  if (!existsSync(sourceBase)) {
    printJson({ schemaVersion: "1", mapped: 0, sourceBase, targetRoot: "" });
    return;
  }

  const entries = readdirSync(sourceBase, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name);

  let mapped = 0;
  const targetRoot = join(root, target === "codex" ? ".codex/skills" : `.${target}/skills`);

  for (const skillName of entries) {
    const sourcePath = join(sourceBase, skillName);
    try {
      mapSkill(root, target, skillName, sourcePath, { forceMap: options.forceMap });
      mapped++;
    } catch {
      // Skip already mapped or errors
    }
  }

  printJson({ schemaVersion: "1", mapped, sourceBase, targetRoot });
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
