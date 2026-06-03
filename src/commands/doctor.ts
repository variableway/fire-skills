import * as p from "@clack/prompts";
import pc from "picocolors";
import { join } from "path";
import { detectRoot } from "../utils/root";
import { showIntro, showOutro, getError } from "../core/output";

export async function runDoctor(): Promise<void> {
  showIntro(false);

  try {
    const { root, reason } = detectRoot(process.cwd());

    p.log.step(pc.bold("Environment Diagnosis"));

    p.log.message(`${pc.bold("Workspace root:")} ${pc.cyan(root)}`);
    p.log.message(`${pc.bold("Root detection:")} ${pc.dim(reason)}`);

    const { existsSync } = await import("fs");
    const cwd = process.cwd();

    const checks = [
      { name: ".claude/skills", path: ".claude/skills" },
      { name: ".agents/skills", path: ".agents/skills" },
      { name: ".gemini/skills", path: ".gemini/skills" },
      { name: "skills.lock", path: "skills.lock", isFile: true },
    ];

    p.log.step(pc.bold("Directories"));

    for (const check of checks) {
      const fullPath = check.isFile ? check.path : join(cwd, check.path);
      const exists = existsSync(check.isFile ? fullPath : fullPath);
      p.log.message(
        `  ${exists ? pc.green("✓") : pc.yellow("✗")} ${check.name} ${pc.dim(`(${check.path})`)}`,
      );
    }

    const { agents, detectInstalledAgents } = await import("../core/agents");
    const installedAgents = detectInstalledAgents();

    p.log.step(pc.bold("Detected Agents"));
    if (installedAgents.length === 0) {
      p.log.message(`  ${pc.dim("No known agents detected")}`);
    } else {
      for (const agent of installedAgents) {
        p.log.message(`  ${pc.green("✓")} ${pc.cyan(agents[agent].label)}`);
      }
    }

    showOutro(pc.green("Diagnosis complete"));
  } catch (error) {
    p.log.error(getError(error, "Diagnosis failed."));
    showOutro(pc.red("Doctor failed"));
    process.exit(1);
  }
}