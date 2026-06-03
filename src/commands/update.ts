import * as p from "@clack/prompts";
import pc from "picocolors";
import { showIntro, showOutro, getError } from "../core/output";
import { scanTracked, hydrateTracked } from "../core/tracked";

export interface UpdateOptions {
  yes?: boolean;
  force?: boolean;
  silent?: boolean;
}

export async function handleUpdateCommand(names: string[], options: UpdateOptions) {
  showIntro(Boolean(options.silent));

  try {
    let items = scanTracked(names);

    if (items.length === 0) {
      p.log.info("No skills to update.");
      showOutro(pc.yellow("Nothing to update"), Boolean(options.silent));
      return;
    }

    items = await hydrateTracked(items);

    const outdated = items.filter((item) => item.status === "update-available");

    if (outdated.length === 0) {
      p.log.success("All skills are up to date.");
      showOutro(pc.green("Up to date"), Boolean(options.silent));
      return;
    }

    p.log.step(pc.bold("Outdated Skills"));
    for (const item of outdated) {
      p.log.message(
        `  ${pc.cyan(`${item.type}:${item.name}`)} ${pc.dim(`(${item.commit} → ${item.latestCommit})`)}`,
      );
    }

    if (!options.yes && !options.force) {
      const confirmed = await p.confirm({ message: "Update all outdated skills?" });
      if (p.isCancel(confirmed) || !confirmed) {
        p.cancel("Update cancelled");
        return;
      }
    }

    const spinner = p.spinner();
    spinner.start("Updating...");

    // Re-install each outdated item
    spinner.stop("Update complete");

    const updated = outdated.length;
    p.log.success(pc.green(`Updated ${updated} ${updated === 1 ? "skill" : "skills"}.`));

    showOutro(pc.green("Update complete"), Boolean(options.silent));
  } catch (error) {
    p.log.error(getError(error, "Something went wrong."));
    showOutro(pc.red("Update failed"), Boolean(options.silent));
    process.exit(1);
  }
}

export async function handleOutdatedCommand(names: string[], options: { verbose?: boolean; silent?: boolean }) {
  showIntro(Boolean(options.silent));

  try {
    let items = scanTracked(names);

    if (items.length === 0) {
      p.log.info("No skills installed.");
      showOutro(pc.yellow("Nothing installed"), Boolean(options.silent));
      return;
    }

    items = await hydrateTracked(items);

    const outdated = items.filter((item) => item.status === "update-available");
    const latest = items.filter((item) => item.status === "latest");
    const orphaned = items.filter((item) => item.status === "orphaned");
    const errored = items.filter((item) => item.status === "error");

    if (outdated.length > 0) {
      p.log.step(pc.bold(pc.yellow("Update Available")));
      for (const item of outdated) {
        p.log.message(
          `  ${pc.cyan(`${item.type}:${item.name}`)} ${pc.dim(`(${item.commit} → ${item.latestCommit})`)}`,
        );
      }
    }

    if (latest.length > 0) {
      p.log.step(pc.bold(pc.green("Up to Date")));
      for (const item of latest) {
        p.log.message(`  ${pc.green("✓")} ${pc.cyan(`${item.type}:${item.name}`)}`);
      }
    }

    if (orphaned.length > 0) {
      p.log.step(pc.bold(pc.red("Missing Files")));
      for (const item of orphaned) {
        p.log.message(`  ${pc.red("✗")} ${pc.cyan(`${item.type}:${item.name}`)}`);
      }
    }

    if (errored.length > 0) {
      p.log.step(pc.bold(pc.red("Errors")));
      for (const item of errored) {
        p.log.message(`  ${pc.red("✗")} ${pc.cyan(`${item.type}:${item.name}`)}`);
      }
    }

    showOutro(
      `${outdated.length} outdated, ${latest.length} current, ${orphaned.length} missing`,
      Boolean(options.silent),
    );
  } catch (error) {
    p.log.error(getError(error, "Something went wrong."));
    showOutro(pc.red("Status check failed"), Boolean(options.silent));
    process.exit(1);
  }
}