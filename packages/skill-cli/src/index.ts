#!/usr/bin/env node

import { Command } from "commander";
import packageJson from "../package.json" with { type: "json" };
import { type AddOptions, handleAddCommand } from "./commands/skill/add.ts";
import { type AgentAddOptions, runAgentAdd, runAgentList, runAgentRemove, runAgentSchema } from "./commands/agent/index.ts";
import { runDoctor } from "./commands/doctor/index.ts";
import { type InspectOptions, runInspect } from "./commands/skill/inspect.ts";
import { handleListCommand } from "./commands/skill/list.ts";
import { runMap } from "./commands/map-sync/map.ts";
import { runSync, type SyncCommandOptions } from "./commands/map-sync/sync.ts";
import { handleRemoveCommand, type RemoveOptions } from "./commands/skill/remove.ts";
import { runSearch } from "./commands/search/index.ts";
import { runValidate, type ValidateOptions } from "./commands/skill/validate.ts";
import { runDocxToMd, type DocxToMdOptions } from "./commands/docx/index.ts";

const logo = `
`;

const program = new Command();

async function runOrExit(action: () => Promise<void> | void) {
  try {
    await action();
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

program.addHelpText("beforeAll", logo);

program
  .name("skill-spark")
  .description("SkillOps CLI for installing, syncing, and governing AI coding agent skills")
  .version(packageJson.version)
  .showHelpAfterError()
  .showSuggestionAfterError();

program
  .command("search [query]")
  .alias("s")
  .description("Search skills from registry or browse interactively")
  .option("--registry <url>", "Registry base URL override")
  .option("--category <slug>", "Filter by category slug")
  .option("--limit <n>", "Results per page (max 100)", (value) => Number.parseInt(value, 10))
  .option("--offset <n>", "Pagination offset", (value) => Number.parseInt(value, 10))
  .option("--sort <value>", "Sort by: votes, recent, stars")
  .option("--sources <sources...>", "Search sources: registry,directory,local")
  .option("-i, --interactive", "Force interactive TUI browse mode")
  .option("-o, --output <path>", "Write results to file (JSON or markdown)")
  .option("-f, --format <type>", "Output format: json, markdown (default: auto-detect from extension)")
  .action(
    async (
      query: string | undefined,
      options: {
        registry?: string;
        category?: string;
        limit?: number;
        offset?: number;
        sort?: string;
        sources?: string[];
        interactive?: boolean;
        output?: string;
        format?: string;
      },
    ) => {
      await runSearch(query, options);
    },
  );

program
  .command("find [query]")
  .description("Find skills across local sources, registry, and directory")
  .option("--registry <url>", "Registry base URL override")
  .option("--category <slug>", "Filter by category slug")
  .option("--limit <n>", "Results per page (max 100)", (value) => Number.parseInt(value, 10))
  .option("--offset <n>", "Pagination offset", (value) => Number.parseInt(value, 10))
  .option("--sort <value>", "Sort by: votes, recent, stars")
  .option("--sources <sources...>", "Search sources: local,registry,directory", ["local", "registry", "directory"])
  .option("-i, --interactive", "Force interactive TUI browse mode")
  .option("-o, --output <path>", "Write results to file (JSON or markdown)")
  .option("-f, --format <type>", "Output format: json, markdown (default: auto-detect from extension)")
  .action(
    async (
      query: string | undefined,
      options: {
        registry?: string;
        category?: string;
        limit?: number;
        offset?: number;
        sort?: string;
        sources?: string[];
        interactive?: boolean;
        output?: string;
        format?: string;
      },
    ) => {
      await runSearch(query, options);
    },
  );

program
  .command("add <source>")
  .alias("a")
  .alias("install")
  .alias("i")
  .description("Install all skills from a source into detected agent directories")
  .option("-g, --global", "Install globally into system-level user folders")
  .option("-f, --force", "Skip confirmation prompt")
  .option("-a, --agent <agents...>", "Install only into the specified agent directories (e.g. workbuddy, claude-code)")
  .action(async (source: string, options: AddOptions) => {
    await handleAddCommand(source, options);
  });

program
  .command("remove [skills...]")
  .alias("r")
  .alias("rm")
  .alias("uninstall")
  .description("Remove installed skills. No args removes all. Use -g for global scope.")
  .option("-g, --global", "Remove from global scope only")
  .option("-f, --force", "Skip confirmation prompt")
  .action(async (skills: string[], options: RemoveOptions) => {
    await handleRemoveCommand(skills, options);
  });

program
  .command("list")
  .alias("l")
  .description("List installed skills and commands")
  .action(async () => {
    await handleListCommand();
  });

program
  .command("validate <path-or-source>")
  .description("Validate SKILL.md structure, metadata, references, and basic file safety")
  .option("--all", "Validate all skills discovered in the source")
  .option("--branch <branch>", "Git branch override")
  .option("-s, --skill <skills...>", "Validate specific skills by name")
  .option("-f, --format <type>", "Output format: text, json, markdown")
  .option("-o, --output <path>", "Write report to file")
  .option("--strict", "Treat warnings as failures")
  .action((input: string, options: ValidateOptions) => runOrExit(() => runValidate(input, options)));

program
  .command("inspect <path-or-source>")
  .description("Inspect skills with deterministic rule-based risk and quality checks")
  .option("--all", "Inspect all skills discovered in the source")
  .option("--branch <branch>", "Git branch override")
  .option("-s, --skill <skills...>", "Inspect specific skills by name")
  .option("--mode <mode>", "Inspection mode: rules", "rules")
  .option("--via-skill <name>", "Future advisory skill-assisted report mode")
  .option("-f, --format <type>", "Output format: text, json, markdown")
  .option("-o, --output <path>", "Write report to file")
  .option("--fail-on <level>", "Exit non-zero on risk level: low, medium, high, critical")
  .action((input: string, options: InspectOptions) => runOrExit(() => runInspect(input, options)));

program
  .command("map")
  .description("Map installed skills into target agent directory")
  .option("--target <target>", "Target environment (gemini, claude, codex, agent, qwen)")
  .option("--global", "Map from global skill-spark install")
  .option("--universal", "Map from universal (.agents/skills)")
  .option("--force-map", "Overwrite target mapping if it exists")
  .action(async (options: { target?: string; global?: boolean; universal?: boolean; forceMap?: boolean }) => {
    await runMap(options);
  });

program
  .command("sync")
  .description("Sync skills from a source directory to target AI agent skill folders")
  .option("-s, --source <path>", "Source directory or remote source (default: skills/base)")
  .option("-a, --agent <agents...>", "Target agents (default: codex, claude-code, opencode, trae, kimi-cli)")
  .option("--skill <names...>", "Only sync matching skill names")
  .option("--global", "Sync into global agent skill folders")
  .option("-y, --yes", "Accepted for script compatibility; sync is non-interactive")
  .option("-f, --force", "Overwrite existing target folders")
  .option("--no-symlink", "Copy files directly instead of symlinking from .agents/skills")
  .action(async (options: SyncCommandOptions) => {
    await runSync(options);
  });

const agentCommand = program
  .command("agent")
  .alias("agents")
  .description("Manage target AI agent directory configurations");

agentCommand
  .command("list")
  .description("List built-in and custom agent directory configurations")
  .option("--json", "Print JSON output")
  .action((options: { json?: boolean }) => {
    runAgentList(options);
  });

agentCommand
  .command("schema")
  .description("Print the skill-spark.agents.json standard format")
  .action(() => {
    runAgentSchema();
  });

agentCommand
  .command("add <name>")
  .description("Add a custom agent directory configuration")
  .option("--label <label>", "Human-readable agent label")
  .option("--skills-dir <path>", "Project-level skills directory, for example .my-agent/skills")
  .option("--global-skills-dir <path>", "Global skills directory, for example ~/.my-agent/skills")
  .option("--commands-dir <path>", "Project-level commands directory")
  .option("--global-commands-dir <path>", "Global commands directory")
  .option("--alias <aliases...>", "Additional names accepted by --agent")
  .option("--global", "Write to ~/.skill-spark/agents.json instead of ./skill-spark.agents.json")
  .option("--force", "Overwrite an existing custom config or built-in name")
  .action((name: string, options: AgentAddOptions) => {
    runAgentAdd(name, options);
  });

agentCommand
  .command("remove <name>")
  .description("Remove a custom agent directory configuration")
  .option("--global", "Remove from ~/.skill-spark/agents.json instead of ./skill-spark.agents.json")
  .action((name: string, options: { global?: boolean }) => {
    runAgentRemove(name, options);
  });

program
  .command("doctor")
  .description("Diagnose skill-spark environment")
  .action(async () => {
    await runDoctor();
  });

program
  .command("docx-to-md")
  .description("Convert a .docx file to Markdown")
  .requiredOption("-s, --source <path>", "Source .docx file path")
  .requiredOption("-o, --output <path>", "Output .md file path")
  .action(async (options: DocxToMdOptions) => {
    await runDocxToMd(options);
  });

program.parse(process.argv);
