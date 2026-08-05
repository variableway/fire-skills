import * as p from "@clack/prompts";
import { agents } from "@skill-spark/skill-core/agents";
import { getError, showIntro, showNoTrackedItems, showOutro } from "@skill-spark/skill-core/output";
import { scanTracked } from "@skill-spark/skill-core/tracked";
import pc from "picocolors";

export const COMMAND_DESCRIPTION = "List installed and registered skills with their status";
export const COMMAND_EXAMPLES = [
  "skill-spark list",
];
export const COMMAND_PREREQUISITES = [
  "skills.lock file must exist in project or global scope",
];

function statusIcon(item: { validInstallations: unknown[]; installed?: boolean }) {
  if (item.validInstallations.length > 0) return pc.green("✓ installed");
  return pc.yellow("○ registered");
}

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

    p.log.step(pc.bold("Skills"));

    if (global.length > 0) {
      p.log.message(pc.bold(pc.cyan("Global (~/.skill-spark/skills.lock)")));
      for (const item of global) {
        const installedIn = item.validInstallations.length > 0
          ? item.validInstallations.map((inst) => agents[inst.agent].label).join(", ")
          : "not installed";
        const icon = item.type === "command" ? pc.yellow("⚡") : pc.green("✓");
        p.log.message(
          `  ${icon} ${pc.cyan(`${item.type}:${item.name}`)} ${pc.dim(`[${statusIcon(item)}] — ${installedIn}`)}`,
        );
      }
    }

    if (local.length > 0) {
      p.log.message(pc.bold(pc.cyan("Project (./skills.lock)")));
      for (const item of local) {
        const installedIn = item.validInstallations.length > 0
          ? item.validInstallations.map((inst) => agents[inst.agent].label).join(", ")
          : "not installed";
        const icon = item.type === "command" ? pc.yellow("⚡") : pc.green("✓");
        p.log.message(
          `  ${icon} ${pc.cyan(`${item.type}:${item.name}`)} ${pc.dim(`[${statusIcon(item)}] — ${installedIn}`)}`,
        );
      }
    }

    const installedCount = scanned.filter((i) => i.validInstallations.length > 0).length;
    const registeredCount = scanned.filter((i) => i.validInstallations.length === 0).length;

    let summary = `${installedCount} installed`;
    if (registeredCount > 0) {
      summary += `, ${registeredCount} registered`;
    }
    showOutro(pc.green(summary));
  } catch (error) {
    p.log.error(getError(error, "Failed to load installed items."));
    showOutro(pc.red("List failed"));
    process.exit(1);
  }
}
