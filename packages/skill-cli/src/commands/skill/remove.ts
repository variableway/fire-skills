import { join } from "node:path";
import * as p from "@clack/prompts";
import { getAgentNames, resolveAgentCommandsDir, resolveAgentSkillsDir } from "@skill-spark/skill-core/agents";
import { removeInstalledPath } from "@skill-spark/skill-core/installations";
import { getError, plural, showIntro, showOutro } from "@skill-spark/skill-core/output";
import { listTrackedItems, removeTrackedItem } from "@skill-spark/skill-core/state";
import pc from "picocolors";

export const COMMAND_DESCRIPTION = "Remove installed skills from agent directories";
export const COMMAND_EXAMPLES = [
  "skill-spark remove                  # Remove all skills from all scopes",
  "skill-spark remove -g               # Remove all global skills",
  "skill-spark remove my-skill         # Remove specific skill",
  "skill-spark remove my-skill -g      # Remove specific skill from global only",
  "skill-spark remove -f               # Skip confirmation",
];
export const COMMAND_PREREQUISITES = [
  "Skills must be tracked in skills.lock",
  "Agent directories must be writable",
];

export interface RemoveOptions {
  global?: boolean;
  force?: boolean;
}

interface RemovalTarget {
  name: string;
  type: "skill" | "command";
  scope: "project" | "global";
}

function findTargets(names: string[], globalOnly: boolean): RemovalTarget[] {
  const allItems = listTrackedItems();

  // Filter by scope
  const scopedItems = globalOnly
    ? allItems.filter((item) => item.scope === "global")
    : allItems;

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
      }));
  }

  // Remove all
  return scopedItems.map((item) => ({
    name: item.name,
    type: item.type,
    scope: item.scope,
  }));
}

export async function handleRemoveCommand(names: string[], options: RemoveOptions) {
  showIntro();

  try {
    const targets = findTargets(names, Boolean(options.global));

    if (targets.length === 0) {
      p.log.warn("No tracked skills found to remove.");
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
    const scopeLabel = options.global ? "global" : "all scopes";

    p.log.info(
      `Found ${pc.green(displayList.length.toString())} ${plural(displayList.length, "item")} to remove (${scopeLabel}).`,
    );

    for (const target of displayList) {
      p.log.message(`  ${pc.cyan(`${target.type}:${target.name}`)} ${pc.dim(`[${target.scope}]`)}`);
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

      for (const agent of getAgentNames()) {
        const directory =
          target.type === "skill"
            ? resolveAgentSkillsDir(agent, target.scope)
            : resolveAgentCommandsDir(agent, target.scope);

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
        removeTrackedItem(target.scope, target.name, target.type);
        p.log.success(pc.green(`Removed ${target.type}:${target.name} [${target.scope}]`));
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
