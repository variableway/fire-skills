import * as p from "@clack/prompts";
import {
  type AgentName,
  type AgentScope,
  agents,
  detectInstalledAgents,
  getSharedDirectoryNotes,
  getUniversalAgents,
  getNonUniversalAgents,
  normalizeAgentNames,
} from "@skill-spark/skill-core/agents";
import { discoverInstallables, type Installable } from "@skill-spark/skill-core/discovery";
import { installInstallable } from "@skill-spark/skill-core/installations";
import { getError, plural, showIntro, showOutro } from "@skill-spark/skill-core/output";
import {
  cleanupSource,
  downloadSource,
  isDirectoryName,
  listDirectory,
  resolveDirectorySource,
} from "@skill-spark/skill-core/sources";
import { trackInstall } from "@skill-spark/skill-core/state";
import pc from "picocolors";

export const COMMAND_DESCRIPTION = "Install all skills from a source into detected agent directories";
export const COMMAND_EXAMPLES = [
  "skill-spark add skills/base",
  "skill-spark add skills/base -g",
  "skill-spark add skills/base -f",
];
export const COMMAND_PREREQUISITES = [
  "Target agent directories must be writable",
  "Source must contain valid SKILL.md files or command markdown files",
];

export interface AddOptions {
  global?: boolean;
  force?: boolean;
  agent?: string[];
}

interface InstallResult {
  name: string;
  type: Installable["type"];
  label: string;
  agent: string;
  path: string;
  success: boolean;
  error?: string;
}

async function resolveSourceInput(sourceInput: string) {
  if (!isDirectoryName(sourceInput)) {
    return sourceInput;
  }

  p.log.info(`Looking up ${pc.cyan(sourceInput)} in the flins directory...`);

  const source = await resolveDirectorySource(sourceInput);
  if (source) {
    return source;
  }

  p.log.error(`Skill ${pc.cyan(sourceInput)} was not found in the flins directory.`);
  const entries = await listDirectory();
  if (entries.length > 0) {
    p.log.info("Available skills:");
    for (const entry of entries) {
      p.log.message(`  ${pc.cyan(entry.name)} ${pc.dim(`- ${entry.description}`)}`);
    }
  }

  process.exit(1);
}

function resolveTargets(scope: AgentScope, options: AddOptions): AgentName[] {
  // When --agent is provided, restrict (and validate) targets to those agents.
  if (options.agent && options.agent.length > 0) {
    const { agents: requested, invalid } = normalizeAgentNames(options.agent);
    if (invalid.length > 0) {
      p.log.error(`Unknown agent: ${invalid.join(", ")}. Run 'skill-spark agent list' to see supported agents.`);
      process.exit(1);
    }
    return requested;
  }

  const installedAgents = detectInstalledAgents();

  if (scope === "project") {
    const targets: AgentName[] = ["universal"];
    for (const agent of getNonUniversalAgents()) {
      if (installedAgents.includes(agent)) {
        targets.push(agent);
      }
    }
    return targets;
  }

  if (installedAgents.length === 0) {
    p.log.info("No installed agents detected for global install. Use 'agent list' to see available agents.");
    process.exit(1);
  }

  return installedAgents;
}

async function confirmInstall(
  sourceLabel: string,
  scope: AgentScope,
  installables: Installable[],
  targets: AgentName[],
  options: AddOptions,
) {
  const scopeLabel = scope === "global" ? "Global" : "Local";

  p.log.step(pc.bold("Install Summary"));
  p.log.message(`${pc.bold("Source:")} ${sourceLabel}`);
  p.log.message(`${pc.bold("Scope:")} ${scopeLabel}`);
  p.log.message(`${pc.bold("Skills:")} ${installables.map((item) => item.name).join(", ")}`);
  p.log.message(`${pc.bold("Targets:")} ${targets.map((agent) => agents[agent].label).join(", ")}`);

  const sharedNotes = getSharedDirectoryNotes(targets, scope);
  if (sharedNotes.length > 0) {
    p.log.message(pc.bold("Shared folders:"));
    for (const note of sharedNotes) {
      p.log.message(`  ${pc.dim("•")} ${note}`);
    }
  }

  if (scope === "project") {
    p.log.message(
      `${pc.bold("Universal agents:")} ${getUniversalAgents()
        .map((agent) => agents[agent].label)
        .join(", ")}`,
    );
  }

  if (options.force) {
    return true;
  }

  const confirmed = await p.confirm({ message: "Ready to install?" });
  if (p.isCancel(confirmed) || !confirmed) {
    p.cancel("Installation cancelled");
    return false;
  }

  return true;
}

export async function handleAddCommand(sourceInput: string, options: AddOptions) {
  showIntro();

  try {
    const scope = options.global ? "global" : "project";
    const sourceValue = await resolveSourceInput(sourceInput);

    const source = await downloadSource(sourceValue);
    const results: InstallResult[] = [];

    try {
      const installables = discoverInstallables(source.root, source.subpath);
      if (installables.length === 0) {
        p.log.error("No skills or commands found. The source must contain SKILL.md files or command markdown files.");
        showOutro(pc.red("Installation failed"));
        process.exit(1);
      }

      const skills = installables.filter((item) => item.type === "skill").length;
      const commands = installables.filter((item) => item.type === "command").length;
      p.log.info(
        `Found ${pc.green(skills.toString())} ${plural(skills, "skill")}${commands > 0 ? ` and ${pc.yellow(commands.toString())} ${plural(commands, "command")}` : ""}`,
      );

      const targets = resolveTargets(scope, options);

      if (!(await confirmInstall(source.label, scope, installables, targets, options))) {
        return;
      }

      const spinner = p.spinner();
      spinner.start("Installing...");

      for (const installable of installables) {
        let installedCount = 0;

        for (const agent of targets) {
          const outcome = installInstallable(installable, agent, scope);
          results.push({
            name: installable.name,
            type: installable.type,
            label: `${installable.type}:${installable.name}`,
            agent: agents[agent].label,
            path: outcome.path,
            success: outcome.success,
            error: outcome.error,
          });

          if (outcome.success) {
            installedCount += 1;
          }
        }

        if (installedCount > 0) {
          trackInstall({
            name: installable.name,
            type: installable.type,
            scope,
            url: source.url,
            subpath: source.subpath,
            branch: source.branch,
            commit: source.commit,
          });
        }
      }

      spinner.stop("Install complete");

      const installed = results.filter((result) => result.success).length;
      const failed = results.filter((result) => !result.success).length;

      if (installed > 0) {
        p.log.success(pc.green(`Installed ${installed} ${plural(installed, "item")}.`));
        for (const result of results.filter((result) => result.success)) {
          p.log.message(`  ${pc.green("✓")} ${result.label} ${pc.dim(`→ ${result.agent}`)}`);
          p.log.message(`    ${pc.dim(result.path)}`);
        }
      }

      if (failed > 0) {
        p.log.error(pc.red(`Failed to install ${failed} ${plural(failed, "item")}.`));
        for (const result of results.filter((result) => !result.success)) {
          p.log.message(`  ${pc.red("✗")} ${result.label} ${pc.dim(`→ ${result.agent}`)}`);
          if (result.error) {
            p.log.message(`    ${pc.dim(result.error)}`);
          }
        }
      }

      if (failed > 0) {
        showOutro(pc.red("Installation finished with errors"));
        process.exit(1);
      }

      showOutro(
        installed > 0 ? pc.green("Done! Skills ready to use.") : pc.yellow("Nothing installed"),
      );
    } finally {
      await cleanupSource(source);
    }
  } catch (error) {
    p.log.error(getError(error, "Something went wrong. Try again or check your connection."));
    showOutro(pc.red("Installation failed"));
    process.exit(1);
  }
}
