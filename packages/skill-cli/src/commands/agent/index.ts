import {
  type AgentConfigSpec,
  type AgentScope,
  builtInAgents,
  getAgentConfigPath,
  getAgents,
  getCustomAgentSpecs,
  isValidAgentSlug,
  normalizeAgentSlug,
  readCustomAgentConfig,
  writeCustomAgentConfig,
} from "@skill-spark/skill-core/agents";
import { printJson } from "../../utils/json";
import { detectRoot } from "../../utils/root";

export const COMMAND_DESCRIPTION = "Manage target AI agent directory configurations";
export const COMMAND_EXAMPLES = [
  "skill-spark agent list",
  "skill-spark agent add my-agent --skills-dir .my-agent/skills --global",
  "skill-spark agent schema",
];
export const COMMAND_PREREQUISITES = [
  "Agent directory paths must be writable",
  "Custom agent names must use lowercase letters, numbers, and hyphens only",
];

export interface AgentAddOptions {
  label?: string;
  skillsDir?: string;
  globalSkillsDir?: string;
  commandsDir?: string;
  globalCommandsDir?: string;
  alias?: string[];
  global?: boolean;
  force?: boolean;
}

export interface AgentListOptions {
  json?: boolean;
}

export interface AgentRemoveOptions {
  global?: boolean;
}

function getRoot() {
  return detectRoot(process.cwd()).root;
}

function getScope(options: { global?: boolean }): AgentScope {
  return options.global ? "global" : "project";
}

function assertValidAgentName(name: string) {
  const slug = normalizeAgentSlug(name);
  if (!isValidAgentSlug(slug)) {
    console.error(`Error: invalid agent name '${name}'. Use lowercase letters, numbers, and hyphens.`);
    process.exit(1);
  }

  return slug;
}

export function runAgentSchema(): void {
  printJson({
    version: "1",
    agents: {
      "my-agent": {
        label: "My Agent",
        skillsDir: ".my-agent/skills",
        globalSkillsDir: "~/.my-agent/skills",
        commandsDir: ".my-agent/commands",
        globalCommandsDir: "~/.my-agent/commands",
        aliases: ["myagent"],
      },
    },
  });
}

export function runAgentList(options: AgentListOptions): void {
  const root = getRoot();
  const allAgents = getAgents(root);
  const customAgents = getCustomAgentSpecs(root);
  const rows = Object.entries(allAgents).map(([name, config]) => ({
    name,
    label: config.label,
    skillsDir: config.skillsDir,
    globalSkillsDir: config.globalSkillsDir,
    commandsDir: config.commandsDir,
    globalCommandsDir: config.globalCommandsDir,
    source: name in customAgents ? "custom" : "built-in",
  }));

  if (options.json) {
    printJson({
      schemaVersion: "1",
      projectConfig: getAgentConfigPath("project", root),
      globalConfig: getAgentConfigPath("global", root),
      agents: rows,
    });
    return;
  }

  console.log("Agent\tSource\tSkills Dir\tGlobal Skills Dir");
  for (const row of rows) {
    console.log(`${row.name}\t${row.source}\t${row.skillsDir}\t${row.globalSkillsDir}`);
  }
}

export function runAgentAdd(name: string, options: AgentAddOptions): void {
  const root = getRoot();
  const scope = getScope(options);
  const slug = assertValidAgentName(name);

  if (!options.skillsDir) {
    console.error("Error: --skills-dir is required");
    process.exit(1);
  }

  if (slug in builtInAgents && !options.force) {
    console.error(`Error: '${slug}' is a built-in agent. Use --force only if you intend to override it.`);
    process.exit(1);
  }

  const config = readCustomAgentConfig(scope, root);
  if (config.agents[slug] && !options.force) {
    console.error(`Error: custom agent '${slug}' already exists. Use --force to overwrite.`);
    process.exit(1);
  }

  const spec: AgentConfigSpec = {
    label: options.label ?? name,
    skillsDir: options.skillsDir,
    globalSkillsDir: options.globalSkillsDir ?? `~/.${slug}/skills`,
  };

  if (options.commandsDir) {
    spec.commandsDir = options.commandsDir;
  }

  if (options.globalCommandsDir) {
    spec.globalCommandsDir = options.globalCommandsDir;
  }

  if (options.alias && options.alias.length > 0) {
    spec.aliases = options.alias.map((alias) => normalizeAgentSlug(alias));
  }

  config.agents[slug] = spec;
  const path = writeCustomAgentConfig(scope, config, root);

  printJson({
    schemaVersion: "1",
    added: slug,
    scope,
    path,
    config: spec,
  });
}

export function runAgentRemove(name: string, options: AgentRemoveOptions): void {
  const root = getRoot();
  const scope = getScope(options);
  const slug = assertValidAgentName(name);
  const config = readCustomAgentConfig(scope, root);
  const existed = Boolean(config.agents[slug]);

  delete config.agents[slug];
  const path = writeCustomAgentConfig(scope, config, root);

  printJson({
    schemaVersion: "1",
    removed: existed ? slug : null,
    scope,
    path,
  });
}
