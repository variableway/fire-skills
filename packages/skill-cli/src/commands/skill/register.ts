import * as p from "@clack/prompts";
import { discoverInstallables } from "@skill-spark/skill-core/discovery";
import { getError, plural, showIntro, showOutro } from "@skill-spark/skill-core/output";
import { cleanupSource, downloadSource } from "@skill-spark/skill-core/sources";
import { registerTrackedItem } from "@skill-spark/skill-core/state";
import pc from "picocolors";
import { resolveSourceInput } from "./shared/register.js";

export const COMMAND_DESCRIPTION = "Register an external skill source for future installation";
export const COMMAND_EXAMPLES = [
  "skill-spark register https://github.com/user/my-skill        # Register from GitHub",
  "skill-spark register ./local/skill                            # Register from local path",
  "skill-spark register my-skill                                 # Register from flins directory",
  "skill-spark register user/repo --branch dev                   # GitHub shorthand with branch",
  "skill-spark register -g https://github.com/user/global-skill  # Register as global",
  "skill-spark register -f https://github.com/user/skill         # Skip confirmation",
];
export const COMMAND_PREREQUISITES = [
  "Source must contain valid SKILL.md files or command markdown files",
  "skill-spark will download the source to discover skill metadata",
];

export interface RegisterOptions {
  global?: boolean;
  force?: boolean;
  branch?: string;
}

export async function handleRegisterCommand(sourceInput: string, options: RegisterOptions) {
  showIntro();

  try {
    const scope = options.global ? "global" : "project";
    const sourceValue = await resolveSourceInput(sourceInput);

    const source = await downloadSource(sourceValue, options.branch);
    const scopeLabel = scope === "global" ? "global" : "project";

    try {
      const installables = discoverInstallables(source.root, source.subpath ?? undefined);
      if (installables.length === 0) {
        p.log.error("No skills or commands found. The source must contain SKILL.md files or command markdown files.");
        showOutro(pc.red("Registration failed"));
        process.exit(1);
      }

      const skills = installables.filter((item) => item.type === "skill").length;
      const commands = installables.filter((item) => item.type === "command").length;
      p.log.info(
        `Found ${pc.green(skills.toString())} ${plural(skills, "skill")}${commands > 0 ? ` and ${pc.yellow(commands.toString())} ${plural(commands, "command")}` : ""}`,
      );

      p.log.step(pc.bold("Register Summary"));
      p.log.message(`${pc.bold("Source:")} ${source.label}`);
      p.log.message(`${pc.bold("Scope:")} ${pc.bold(scopeLabel)}`);
      p.log.message(`${pc.bold("Skills:")} ${installables.map((item) => item.name).join(", ")}`);

      if (!options.force) {
        const confirmed = await p.confirm({
          message: `Register these ${installables.length} ${plural(installables.length, "item")} for later installation?`,
        });
        if (p.isCancel(confirmed) || !confirmed) {
          p.cancel("Registration cancelled");
          return;
        }
      }

      const spinner = p.spinner();
      spinner.start("Registering...");

      let registeredCount = 0;
      for (const installable of installables) {
        registerTrackedItem({
          name: installable.name,
          type: installable.type,
          scope,
          url: source.url,
          subpath: source.subpath ?? undefined,
          branch: source.branch,
          commit: source.commit,
        });
        registeredCount += 1;
      }

      spinner.stop("Registration complete");

      p.log.success(
        pc.green(`Registered ${registeredCount} ${plural(registeredCount, "item")}.`),
      );
      for (const installable of installables) {
        p.log.message(
          `  ${pc.green("✓")} ${pc.cyan(`${installable.type}:${installable.name}`)} ${pc.dim(`[${scopeLabel}]`)}`,
        );
      }

      p.log.info(
        `To install, run: ${pc.cyan(`skill-spark add ${sourceInput}`)}`,
      );

      showOutro(pc.green("Registration complete. Skills are ready to install."));
    } finally {
      await cleanupSource(source);
    }
  } catch (error) {
    p.log.error(getError(error, "Something went wrong. Try again or check your connection."));
    showOutro(pc.red("Registration failed"));
    process.exit(1);
  }
}
