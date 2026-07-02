import { join } from "node:path";
import * as p from "@clack/prompts";
import { agents, detectInstalledAgents } from "@skill-spark/skill-core/agents";
import { getError, showIntro, showOutro } from "@skill-spark/skill-core/output";
import pc from "picocolors";
import { detectRoot } from "../utils/root";

interface DirectoryCheck {
  name: string;
  path: string;
  isFile?: boolean;
  exists: boolean;
  canRepair: boolean;
}

export async function runDoctor(): Promise<void> {
  showIntro(false);

  try {
    const { root, reason } = detectRoot(process.cwd());

    p.log.step(pc.bold("Environment Diagnosis"));

    p.log.message(`${pc.bold("Workspace root:")} ${pc.cyan(root)}`);
    p.log.message(`${pc.bold("Root detection:")} ${pc.dim(reason)}`);

    const { existsSync, mkdirSync } = await import("node:fs");
    const cwd = process.cwd();

    const checks: DirectoryCheck[] = [
      { name: ".claude/skills", path: ".claude/skills", exists: false, canRepair: true },
      { name: ".agents/skills", path: ".agents/skills", exists: false, canRepair: true },
      { name: ".gemini/skills", path: ".gemini/skills", exists: false, canRepair: true },
      { name: "skills.lock", path: "skills.lock", isFile: true, exists: false, canRepair: false },
    ];

    // Check existence
    for (const check of checks) {
      check.exists = existsSync(check.isFile ? check.path : join(cwd, check.path));
    }

    // Display directory status
    p.log.step(pc.bold("Directories"));

    for (const check of checks) {
      const status = check.exists ? pc.green("✓") : pc.yellow("✗");
      const type = check.isFile ? "file" : "dir";
      p.log.message(`  ${status} ${check.name} ${pc.dim(`(${check.path}) [${type}]`)}`);
    }

    // Detect installed agents
    const installedAgents = detectInstalledAgents();

    p.log.step(pc.bold("Detected Agents"));
    if (installedAgents.length === 0) {
      p.log.message(`  ${pc.dim("No known agents detected")}`);
    } else {
      for (const agent of installedAgents) {
        p.log.message(`  ${pc.green("✓")} ${pc.cyan(agents[agent].label)}`);
      }
    }

    // Check for missing agent directories
    p.log.step(pc.bold("Agent Directories"));

    const missingDirs: { agent: string; label: string; dir: string; scope: "project" | "global" }[] = [];

    for (const agentName of installedAgents) {
      const agent = agents[agentName];
      if (!agent) continue;

      // Check project-level skills dir
      const projectSkillsPath = join(cwd, agent.skillsDir);
      if (!existsSync(projectSkillsPath)) {
        missingDirs.push({
          agent: agentName,
          label: agent.label,
          dir: agent.skillsDir,
          scope: "project",
        });
      }

      // Check project-level commands dir
      if (agent.commandsDir) {
        const projectCommandsPath = join(cwd, agent.commandsDir);
        if (!existsSync(projectCommandsPath)) {
          missingDirs.push({
            agent: agentName,
            label: agent.label,
            dir: agent.commandsDir,
            scope: "project",
          });
        }
      }
    }

    if (missingDirs.length === 0) {
      p.log.message(`  ${pc.green("✓")} All detected agent directories exist`);
    } else {
      p.log.message(`  ${pc.yellow("✗")} ${pc.bold(String(missingDirs.length))} missing directories:`);
      for (const dir of missingDirs) {
        p.log.message(`    ${pc.yellow("•")} ${pc.cyan(dir.label)}: ${pc.dim(dir.dir)} (${dir.scope})`);
      }

      // Offer to repair
      p.log.step(pc.bold("Auto-Repair"));

      const shouldRepair = await p.confirm({
        message: `Create ${missingDirs.length} missing directories?`,
        initialValue: true,
      });

      if (p.isCancel(shouldRepair)) {
        p.log.info("Repair cancelled");
        showOutro(pc.yellow("Diagnosis complete (repair cancelled)"));
        return;
      }

      if (shouldRepair) {
        let created = 0;
        let failed = 0;

        for (const dir of missingDirs) {
          try {
            const fullPath = join(cwd, dir.dir);
            mkdirSync(fullPath, { recursive: true });
            p.log.message(`  ${pc.green("✓")} Created ${pc.cyan(dir.dir)}`);
            created++;
          } catch (error) {
            p.log.message(`  ${pc.red("✗")} Failed to create ${pc.cyan(dir.dir)}: ${getError(error, "Unknown error")}`);
            failed++;
          }
        }

        p.log.step(pc.bold("Repair Summary"));
        p.log.message(`  ${pc.green("✓")} Created: ${pc.bold(String(created))}`);
        if (failed > 0) {
          p.log.message(`  ${pc.red("✗")} Failed: ${pc.bold(String(failed))}`);
        }
      } else {
        p.log.info("Skipping directory creation");
      }
    }

    // Summary
    p.log.step(pc.bold("Summary"));

    const totalChecks = checks.length + installedAgents.length;
    const passedChecks = checks.filter((c) => c.exists).length + installedAgents.length;
    const missingCount = missingDirs.length;

    p.log.message(`  Checks: ${pc.bold(String(passedChecks))}/${pc.bold(String(totalChecks))} passed`);
    if (missingCount > 0) {
      p.log.message(`  Missing: ${pc.yellow(pc.bold(String(missingCount)))} directories`);
    }

    showOutro(pc.green("Diagnosis complete"));
  } catch (error) {
    p.log.error(getError(error, "Diagnosis failed."));
    showOutro(pc.red("Doctor failed"));
    process.exit(1);
  }
}
