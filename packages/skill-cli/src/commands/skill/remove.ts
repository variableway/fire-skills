import * as p from "@clack/prompts";
import { getAgentNames, resolveAgentCommandsDir, resolveAgentSkillsDir } from "@skill-spark/skill-core/agents";
import { removeInstalledPath } from "@skill-spark/skill-core/installations";
import { getError, showIntro, showOutro } from "@skill-spark/skill-core/output";
import { removeTrackedItem } from "@skill-spark/skill-core/state";
import pc from "picocolors";

export const COMMAND_DESCRIPTION = "Remove installed skills and commands from agent directories";
export const COMMAND_EXAMPLES = [
  "skill-spark remove my-skill",
  "skill-spark remove skill:my-skill command:my-cmd --yes",
  "skill-spark remove my-skill --force --silent",
];
export const COMMAND_PREREQUISITES = [
  "Skills must be tracked in skills.lock",
  "Agent directories must be writable",
];

export interface RemoveOptions {
  yes?: boolean;
  force?: boolean;
  silent?: boolean;
}

export async function handleRemoveCommand(names: string[], options: RemoveOptions) {
  showIntro(Boolean(options.silent));

  try {
    if (names.length === 0) {
      p.log.error("No skills or commands specified.");
      showOutro(pc.red("Remove failed"), Boolean(options.silent));
      process.exit(1);
    }

    const isAutoConfirm = Boolean(options.yes || options.force);

    for (const name of names) {
      const [typeName, ...rest] = name.toLowerCase().split(":");
      const actualName = rest.join(":");
      const type = typeName === "command" ? "command" : "skill";

      const installedAgents = getAgentNames().filter((agent) => {
        const skillsDir = resolveAgentSkillsDir(agent, "project");
        const commandsDir = resolveAgentCommandsDir(agent, "project");
        return (type === "skill" && skillsDir) || (type === "command" && commandsDir);
      });

      if (!isAutoConfirm) {
        const confirmed = await p.confirm({
          message: `Remove ${type}:${actualName || name}?`,
        });
        if (p.isCancel(confirmed) || !confirmed) {
          p.log.info(`Skipped ${name}`);
          continue;
        }
      }

      let removed = false;
      for (const agent of installedAgents) {
        const directory =
          type === "skill" ? resolveAgentSkillsDir(agent, "project") : resolveAgentCommandsDir(agent, "project");

        if (!directory) continue;

        const path = type === "skill" ? `${directory}/${actualName || name}` : `${directory}/${actualName || name}.md`;

        const result = removeInstalledPath(path);
        if (result.success) {
          removed = true;
        }
      }

      removeTrackedItem("project", actualName || name, type);
      removeTrackedItem("global", actualName || name, type);

      if (removed) {
        p.log.success(pc.green(`Removed ${type}:${actualName || name}`));
      } else {
        p.log.warn(pc.yellow(`Not found: ${type}:${actualName || name}`));
      }
    }

    showOutro(pc.green("Remove complete"));
  } catch (error) {
    p.log.error(getError(error, "Something went wrong."));
    showOutro(pc.red("Remove failed"), Boolean(options.silent));
    process.exit(1);
  }
}
