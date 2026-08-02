import { cpSync, existsSync, lstatSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import {
  type AgentName,
  type AgentScope,
  getAgentConfig,
  getAgentNames,
  resolveAgentCommandsDir,
  resolveAgentSkillsDir,
} from "./agents";
import type { Installable, InstallableType } from "./discovery";
import type { TrackedItem } from "./state";

export interface InstallationRecord {
  agent: AgentName;
  scope: AgentScope;
  path: string;
}

export interface InstallationResult {
  success: boolean;
  path: string;
  error?: string;
}

const excludedSkillFiles = new Set(["README.md", "metadata.json", ".env", ".env.local", ".DS_Store"]);
const excludedSkillDirectories = new Set([".git", "node_modules", "__pycache__"]);

function toError(error: unknown) {
  return error instanceof Error ? error.message : "Unknown error";
}

function findMatchingEntry(directory: string, name: string, type: InstallableType) {
  try {
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
      const entryName = type === "command" ? entry.name.replace(/\.md$/i, "") : entry.name;
      if (entryName.toLowerCase() !== name.toLowerCase()) {
        continue;
      }

      const path = join(directory, entry.name);
      const stats = lstatSync(path);

      if (type === "skill" && (stats.isDirectory() || stats.isSymbolicLink())) {
        return path;
      }

      if (type === "command" && (stats.isFile() || stats.isSymbolicLink())) {
        return path;
      }
    }
  } catch {
    return null;
  }

  return null;
}

function isValidInstallation(path: string, type: InstallableType) {
  if (!existsSync(path)) {
    return false;
  }

  try {
    const stats = lstatSync(path);
    if (type === "skill") {
      return (stats.isDirectory() || stats.isSymbolicLink()) && existsSync(join(path, "SKILL.md"));
    }

    return (stats.isFile() || stats.isSymbolicLink()) && path.toLowerCase().endsWith(".md");
  } catch {
    return false;
  }
}

function copySkillDirectory(sourcePath: string, targetPath: string) {
  rmSync(targetPath, { recursive: true, force: true });
  mkdirSync(targetPath, { recursive: true });

  for (const entry of readdirSync(sourcePath, { withFileTypes: true })) {
    if (excludedSkillFiles.has(entry.name) || excludedSkillDirectories.has(entry.name) || entry.name.startsWith("_")) {
      continue;
    }

    const sourceEntry = join(sourcePath, entry.name);
    const targetEntry = join(targetPath, entry.name);

    if (entry.isDirectory()) {
      copySkillDirectory(sourceEntry, targetEntry);
      continue;
    }

    mkdirSync(dirname(targetEntry), { recursive: true });
    cpSync(sourceEntry, targetEntry, { recursive: true });
  }
}

export function findInstallations(name: string, type: InstallableType, scope: AgentScope, cwd: string = process.cwd()) {
  const installations: InstallationRecord[] = [];

  for (const agent of getAgentNames()) {
    const directory =
      type === "skill" ? resolveAgentSkillsDir(agent, scope, cwd) : resolveAgentCommandsDir(agent, scope, cwd);

    if (!directory || !existsSync(directory)) {
      continue;
    }

    const path = findMatchingEntry(directory, name, type);
    if (!path) {
      continue;
    }

    installations.push({
      agent,
      scope,
      path,
    });
  }

  return installations;
}

export function getValidInstallations(item: TrackedItem, cwd: string = process.cwd()) {
  return findInstallations(item.name, item.type, item.scope, cwd).filter((installation) =>
    isValidInstallation(installation.path, item.type),
  );
}

export function installInstallable(
  installable: Installable,
  agent: AgentName,
  scope: AgentScope,
  options?: { cwd?: string },
) {
  const cwd = options?.cwd ?? process.cwd();

  if (installable.type === "command") {
    const directory = resolveAgentCommandsDir(agent, scope, cwd);
    if (!directory) {
      return {
        success: false,
        path: "",
        error: `Agent ${getAgentConfig(agent, cwd)?.label ?? agent} does not support commands`,
      };
    }

    const targetPath = join(directory, `${installable.name}.md`);

    try {
      mkdirSync(dirname(targetPath), { recursive: true });
      rmSync(targetPath, { force: true });
      cpSync(installable.path, targetPath);
      return { success: true, path: targetPath };
    } catch (error) {
      return { success: false, path: targetPath, error: toError(error) };
    }
  }

  const targetPath = join(resolveAgentSkillsDir(agent, scope, cwd), installable.name);

  try {
    copySkillDirectory(installable.path, targetPath);
    // Normalize intra-skill path references for agents whose skills directory
    // differs from the universal `.agents/skills` convention used in many skill
    // sources (e.g. devops-skill). Currently scoped to WorkBuddy.
    rewriteSkillPathsForAgent(targetPath, agent, scope, cwd);
    return { success: true, path: targetPath };
  } catch (error) {
    return { success: false, path: targetPath, error: toError(error) };
  }
}

export function removeInstalledPath(path: string) {
  try {
    if (!existsSync(path)) {
      return { success: false, error: `Path does not exist: ${path}` };
    }
    rmSync(path, { recursive: true, force: true });
    return { success: true };
  } catch (error) {
    return { success: false, error: toError(error) };
  }
}

// ---------------------------------------------------------------------------
// Path normalization for agents that use a non-universal skills directory.
// Many skill sources (e.g. devops-skill) hardcode `.agents/skills/` or
// `~/.claude/skills/` in their SKILL.md / scripts. When installed into an
// agent whose skills directory differs (WorkBuddy uses ~/.workbuddy/skills),
// those references break. This rewrites them to the target agent's directory.
// ---------------------------------------------------------------------------

const REWRITABLE_TEXT_EXTENSIONS = new Set([".md", ".py", ".sh", ".ps1", ".mjs", ".ts", ".json"]);

function rewriteTextFilesRecursively(dir: string, replacements: Array<[RegExp, string]>) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) {
      rewriteTextFilesRecursively(path, replacements);
      continue;
    }

    const dotIndex = entry.name.lastIndexOf(".");
    const ext = dotIndex >= 0 ? entry.name.slice(dotIndex).toLowerCase() : "";
    if (!REWRITABLE_TEXT_EXTENSIONS.has(ext)) {
      continue;
    }

    try {
      const original = readFileSync(path, "utf-8");
      let updated = original;
      for (const [pattern, replacement] of replacements) {
        updated = updated.replace(pattern, replacement);
      }
      if (updated !== original) {
        writeFileSync(path, updated, "utf-8");
      }
    } catch {
      // Skip unreadable / binary files.
    }
  }
}

function rewriteSkillPathsForAgent(skillDir: string, agent: AgentName, scope: AgentScope, cwd: string = process.cwd()) {
  if (agent !== "workbuddy") {
    return;
  }

  const targetDir = resolveAgentSkillsDir(agent, scope, cwd);
  // Use the tilde form for global scope (portable in docs); relative form for project scope.
  const replacementDir = scope === "global" ? targetDir.replace(homedir(), "~") : ".workbuddy/skills";

  const replacements: Array<[RegExp, string]> = [
    [/\.agents\/skills\//g, `${replacementDir}/`],
    [/~\/\.claude\/skills\//g, `${replacementDir}/`],
    [/~\/\.codex\/skills\//g, `${replacementDir}/`],
    [/~\/\.trae\/skills\//g, `${replacementDir}/`],
    [/~\/\.trae-cn\/skills\//g, `${replacementDir}/`],
  ];

  try {
    rewriteTextFilesRecursively(skillDir, replacements);
  } catch {
    // Path rewriting is best-effort; never fail the install because of it.
  }
}
