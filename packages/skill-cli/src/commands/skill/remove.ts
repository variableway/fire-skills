import { join } from "node:path";
import * as p from "@clack/prompts";
import { getAgentNames, resolveAgentCommandsDir, resolveAgentSkillsDir } from "@skill-spark/skill-core/agents";
import { removeInstalledPath } from "@skill-spark/skill-core/installations";
import { getError, showIntro, showOutro } from "@skill-spark/skill-core/output";
import { removeTrackedItem } from "@skill-spark/skill-core/state";
import pc from "picocolors";

export const COMMAND_DESCRIPTION = "Remove installed skills and commands from agent directories";
export const COMMAND_EXAMPLES = [
  "skill-spark remove my-skill",
  "skill-spark remove skill:my-skill command:my-cmd -f",
  "skill-spark remove my-skill -f",
];
export const COMMAND_PREREQUISITES = [
  "Skills must be tracked in skills.lock",
  "Agent directories must be writable",
];

export interface RemoveOptions {
  force?: boolean;
}

export async function handleRemoveCommand(names: string[], options: RemoveOptions) {
  showIntro();

  try {
    if (names.length === 0) {
      p.log.error("No skills or commands specified.");
      showOutro(pc.red("Remove failed"));
      process.exit(1);
    }

    for (const name of names) {
      const [typeName, ...rest] = name.toLowerCase().split(":");
      const actualName = rest.join(":") || typeName;
      const type = name.includes(":") && typeName === "command" ? "command" : "skill";

      if (!options.force) {
        const confirmed = await p.confirm({
          message: `Remove ${type}:${actualName}?`,
        });
        if (p.isCancel(confirmed) || !confirmed) {
          p.log.info(`Skipped ${name}`);
          continue;
        }
      }

      let projectRemoved = false;
      let globalRemoved = false;

      for (const scope of ["project", "global"] as const) {
        for (const agent of getAgentNames()) {
          const directory =
            type === "skill"
              ? resolveAgentSkillsDir(agent, scope)
              : resolveAgentCommandsDir(agent, scope);

          if (!directory) continue;

          const targetPath =
            type === "skill"
              ? join(directory, actualName)
              : join(directory, `${actualName}.md`);

          const result = removeInstalledPath(targetPath);
          if (result.success) {
            if (scope === "project") projectRemoved = true;
            else globalRemoved = true;
          }
        }
      }

      if (projectRemoved) {
        removeTrackedItem("project", actualName, type);
      }
      if (globalRemoved) {
        removeTrackedItem("global", actualName, type);
      }

      if (projectRemoved || globalRemoved) {
        p.log.success(pc.green(`Removed ${type}:${actualName}`));
      } else {
        p.log.warn(pc.yellow(`Not found: ${type}:${actualName}`));
      }
    }

    showOutro(pc.green("Remove complete"));
  } catch (error) {
    p.log.error(getError(error, "Something went wrong."));
    showOutro(pc.red("Remove failed"));
    process.exit(1);
  }
}
