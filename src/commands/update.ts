import * as p from "@clack/prompts";
import pc from "picocolors";
import { showIntro, showOutro, getError } from "../core/output";
import { scanTracked, hydrateTracked } from "../core/tracked";
import { discoverInstallables, type Installable } from "../core/discovery";
import { installInstallable } from "../core/installations";
import { cleanupSource, downloadSource } from "../core/sources";
import { updateTrackedCommit } from "../core/state";

export interface UpdateOptions {
  yes?: boolean;
  force?: boolean;
  silent?: boolean;
}

function findInstallable(installables: Installable[], item: { name: string; type: string }) {
  return installables.find(
    (installable) =>
      installable.type === item.type &&
      installable.name.toLowerCase() === item.name.toLowerCase(),
  );
}

function uniqueInstallations<T extends { path: string }>(installations: T[]) {
  const seen = new Set<string>();
  const unique: T[] = [];

  for (const installation of installations) {
    const key = process.platform === "win32" ? installation.path.toLowerCase() : installation.path;
    if (seen.has(key)) {
      continue;
    }

    seen.add(key);
    unique.push(installation);
  }

  return unique;
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

    let updated = 0;
    const failures: string[] = [];

    for (const item of outdated) {
      const source = await downloadSource(item.url, item.branch);

      try {
        const installable = findInstallable(
          discoverInstallables(source.root, item.subpath ?? source.subpath),
          item,
        );

        if (!installable) {
          failures.push(`${item.type}:${item.name} not found in ${item.url}`);
          continue;
        }

        let successCount = 0;
        for (const installation of uniqueInstallations(item.validInstallations)) {
          const outcome = installInstallable(installable, installation.agent, item.scope, {
            symlink: true,
          });

          if (outcome.success) {
            successCount += 1;
          } else {
            failures.push(
              `${item.type}:${item.name} failed for ${installation.agent}: ${outcome.error}`,
            );
          }
        }

        if (successCount > 0 && item.latestCommit) {
          updateTrackedCommit(item.scope, item.name, item.type, item.latestCommit);
          updated += 1;
        }
      } finally {
        await cleanupSource(source);
      }
    }

    spinner.stop("Update complete");

    if (failures.length > 0) {
      p.log.warn(pc.yellow("Some updates failed:"));
      for (const failure of failures) {
        p.log.message(`  ${pc.yellow("!")} ${failure}`);
      }
    }

    p.log.success(pc.green(`Updated ${updated} ${updated === 1 ? "item" : "items"}.`));

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
