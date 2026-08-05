import { join } from "node:path";
import * as p from "@clack/prompts";
import {
  type AgentName,
  getAgentNames,
  normalizeAgentNames,
  resolveAgentCommandsDir,
  resolveAgentSkillsDir,
} from "@skill-spark/skill-core/agents";
import { removeInstalledPath } from "@skill-spark/skill-core/installations";
import { getError, plural, showIntro, showOutro } from "@skill-spark/skill-core/output";
import { listTrackedItems, removeTrackedItem } from "@skill-spark/skill-core/state";
import pc from "picocolors";

export const COMMAND_DESCRIPTION = "Remove installed skills from agent directories";
export const COMMAND_EXAMPLES = [
  "skill-spark remove                       # Remove all GLOBAL skills (default scope)",
  "skill-spark remove my-skill              # Remove specific skill from GLOBAL scope",
  "skill-spark remove my-skill --project     # Remove from current directory's ./skills.lock",
  "skill-spark remove my-skill --path ./app  # Remove from ./app/skills.lock",
  "skill-spark remove my-skill --agent claude-code,codex  # Remove from specific agents only",
  "skill-spark remove -f                    # Skip confirmation",
];
export const COMMAND_PREREQUISITES = [
  "Skills must be tracked in skills.lock",
  "Agent directories must be writable",
];

export interface RemoveOptions {
  project?: boolean;
  path?: string;
  force?: boolean;
  agent?: string[];
}

interface RemovalTarget {
  name: string;
  type: "skill" | "command";
  scope: "project" | "global";
  cwd?: string;
}

function findTargets(names: string[], options: RemoveOptions): RemovalTarget[] {
  const allItems = listTrackedItems(options.path);

  // Determine scope filter: default global, --project or --path = project scope
  const projectCwd = options.path;
  const scopeTarget = options.project || options.path ? "project" : "global";

  const scopedItems = allItems.filter((item) => item.scope === scopeTarget);

  // Filter by name if provided
  if (names.length > 0) {
    return scopedItems
      .filter((item) =>
        names.some(
          (name) => item.name.toLowerCase() === name.toLowerCase(),
        ),
      )
      .map((item) => ({
        name: item.name,
        type: item.type,
        scope: item.scope,
        cwd: projectCwd,
      }));
  }

  // Remove all in scope
  return scopedItems.map((item) => ({
    name: item.name,
    type: item.type,
    scope: item.scope,
    cwd: projectCwd,
  }));
}

function resolveAgents(options: RemoveOptions): AgentName[] {
  if (options.agent && options.agent.length > 0) {
    const { agents: requested, invalid } = normalizeAgentNames(options.agent);
    if (invalid.length > 0) {
      p.log.error(
        `Unknown agent: ${invalid.join(", ")}. Run 'skill-spark agent list' to see supported agents.`,
      );
      process.exit(1);
    }
    return requested;
  }
  return getAgentNames();
}

export async function handleRemoveCommand(names: string[], options: RemoveOptions) {
  showIntro();

  try {
    const targets = findTargets(names, options);

    if (targets.length === 0) {
      const scopeLabel = options.project || options.path ? "project" : "global";
      p.log.warn(`No tracked skills found in ${scopeLabel} scope to remove.`);
      p.log.info(`Use ${pc.cyan("skill-spark list")} to see installed skills.`);
      showOutro(pc.yellow("Nothing to remove"));
      return;
    }

    // Deduplicate by name+scope
    const unique = new Map<string, RemovalTarget>();
    for (const target of targets) {
      const key = `${target.scope}:${target.type}:${target.name}`;
      if (!unique.has(key)) {
        unique.set(key, target);
      }
    }

    const displayList = [...unique.values()];
    const scopeLabel = options.project || options.path ? `project${options.path ? ` (${options.path})` : ""}` : "global";

    // Resolve target agents
    const targetAgents = resolveAgents(options);

    p.log.info(
      `Found ${pc.green(displayList.length.toString())} ${plural(displayList.length, "item")} to remove (${scopeLabel}).`,
    );

    for (const target of displayList) {
      p.log.message(`  ${pc.cyan(`${target.type}:${target.name}`)} ${pc.dim(`[${target.scope}]`)}`);
    }

    if (options.agent && options.agent.length > 0) {
      p.log.message(`Target agents: ${pc.cyan(targetAgents.join(", "))}`);
    }

    if (!options.force) {
      const confirmed = await p.confirm({
        message: `Remove ${displayList.length} ${plural(displayList.length, "item")}?`,
      });
      if (p.isCancel(confirmed) || !confirmed) {
        p.cancel("Remove cancelled");
        return;
      }
    }

    let totalRemoved = 0;
    let totalSkipped = 0;

    for (const target of displayList) {
      let removed = false;

      for (const agent of targetAgents) {
        const cwd = target.cwd ?? process.cwd();
        const directory =
          target.type === "skill"
            ? resolveAgentSkillsDir(agent, target.scope, cwd)
            : resolveAgentCommandsDir(agent, target.scope, cwd);

        if (!directory) continue;

        const targetPath =
          target.type === "skill"
            ? join(directory, target.name)
            : join(directory, `${target.name}.md`);

        const result = removeInstalledPath(targetPath);
        if (result.success) {
          removed = true;
        }
      }

      if (removed) {
        removeTrackedItem(target.scope, target.name, target.type, target.cwd ?? process.cwd());
        p.log.success(pc.green(`Removed ${target.type}:${target.name} [${target.scope}]${target.cwd ? ` (${target.cwd})` : ""}`));
        totalRemoved += 1;
      } else {
        p.log.warn(pc.yellow(`Not found on disk: ${target.type}:${target.name} [${target.scope}]`));
        totalSkipped += 1;
      }
    }

    if (totalRemoved > 0) {
      showOutro(
        pc.green(`Removed ${totalRemoved} ${plural(totalRemoved, "item")}${totalSkipped > 0 ? `, ${totalSkipped} skipped` : ""}`),
      );
    } else {
      showOutro(pc.yellow("Nothing was removed"));
    }
  } catch (error) {
    p.log.error(getError(error, "Something went wrong."));
    showOutro(pc.red("Remove failed"));
    process.exit(1);
  }
}
