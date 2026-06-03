import * as p from "@clack/prompts";
import pc from "picocolors";
import { agents } from "../core/agents";
import { showIntro, showOutro, showNoTrackedItems, getError } from "../core/output";
import { scanTracked, type TrackedItemStatus } from "../core/tracked";

export async function handleListCommand() {
  showIntro(false);

  try {
    const scanned = scanTracked();
    if (scanned.length === 0) {
      showNoTrackedItems();
      return;
    }

    const local = scanned.filter((item) => item.scope === "project");
    const global = scanned.filter((item) => item.scope === "global");

    p.log.step(pc.bold("Installed Skills and Commands"));

    if (local.length > 0) {
      p.log.message(pc.bold(pc.cyan("Local (./skills.lock)")));
      for (const item of local) {
        const installedIn = item.validInstallations
          .map((installation) => agents[installation.agent].label)
          .join(", ");
        const icon = item.type === "command" ? pc.yellow("⚡") : pc.green("✓");
        p.log.message(
          `  ${icon} ${pc.cyan(`${item.type}:${item.name}`)} ${pc.dim(`(${installedIn || "missing files"})`)}`,
        );
      }
    }

    if (global.length > 0) {
      p.log.message(pc.bold(pc.cyan("Global (~/.skill-spark/skills.lock)")));
      for (const item of global) {
        const installedIn = item.validInstallations
          .map((installation) => agents[installation.agent].label)
          .join(", ");
        const icon = item.type === "command" ? pc.yellow("⚡") : pc.green("✓");
        p.log.message(
          `  ${icon} ${pc.cyan(`${item.type}:${item.name}`)} ${pc.dim(`(${installedIn || "missing files"})`)}`,
        );
      }
    }

    showOutro(pc.green("Showing installed items"));
  } catch (error) {
    p.log.error(getError(error, "Failed to load installed items."));
    showOutro(pc.red("List failed"));
    process.exit(1);
  }
}