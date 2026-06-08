import { basename, dirname, extname, join } from "node:path";
import { readdirSync, readFileSync } from "node:fs";

const skipDirectories = new Set(["node_modules", ".git", "dist", "build", "__pycache__"]);

export type InstallableType = "skill" | "command";

export interface Installable {
  type: InstallableType;
  name: string;
  description: string;
  path: string;
}

function readText(path: string) {
  try {
    return readFileSync(path, "utf-8");
  } catch {
    return null;
  }
}

function listEntries(path: string) {
  try {
    return readdirSync(path, { withFileTypes: true });
  } catch {
    return [];
  }
}

function readHeaders(path: string) {
  const content = readText(path);
  if (!content) {
    return null;
  }

  const frontmatter = content.match(/^---\n([\s\S]+?)\n---/)?.[1] || content;
  const headers = parseSimpleYamlHeaders(frontmatter);

  return {
    name: headers.name,
    description: headers.description,
  };
}

function unquoteYamlScalar(value: string) {
  const trimmed = value.trim();
  if (
    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
    (trimmed.startsWith("'") && trimmed.endsWith("'"))
  ) {
    return trimmed.slice(1, -1).trim();
  }

  return trimmed;
}

function parseBlockScalar(lines: string[], startIndex: number, folded: boolean) {
  const values: string[] = [];
  let index = startIndex + 1;

  while (index < lines.length) {
    const line = lines[index]!;
    if (/^\S[^:]*:\s*/.test(line)) {
      break;
    }

    if (line.trim() === "") {
      values.push("");
      index += 1;
      continue;
    }

    const match = line.match(/^\s+(.*)$/);
    if (!match) {
      break;
    }

    values.push(match[1]!);
    index += 1;
  }

  const text = folded ? values.join(" ").replace(/\s+/g, " ") : values.join("\n");
  return { value: text.trim(), nextIndex: index };
}

function parseSimpleYamlHeaders(frontmatter: string) {
  const headers: Record<string, string> = {};
  const lines = frontmatter.replace(/\r\n/g, "\n").split("\n");
  let index = 0;

  while (index < lines.length) {
    const line = lines[index]!;
    const match = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!match) {
      index += 1;
      continue;
    }

    const key = match[1]!;
    const rawValue = match[2]!.trim();

    if (rawValue === ">" || rawValue === ">-" || rawValue === ">+") {
      const parsed = parseBlockScalar(lines, index, true);
      headers[key] = parsed.value;
      index = parsed.nextIndex;
      continue;
    }

    if (rawValue === "|" || rawValue === "|-" || rawValue === "|+") {
      const parsed = parseBlockScalar(lines, index, false);
      headers[key] = parsed.value;
      index = parsed.nextIndex;
      continue;
    }

    headers[key] = unquoteYamlScalar(rawValue);
    index += 1;
  }

  return headers;
}

function parseSkill(path: string) {
  const headers = readHeaders(path);
  if (!headers?.name || !headers?.description) {
    return null;
  }

  return {
    type: "skill" as const,
    name: headers.name,
    description: headers.description,
    path: dirname(path),
  };
}

function parseCommand(path: string) {
  const headers = readHeaders(path);
  if (!headers) {
    return null;
  }

  return {
    type: "command" as const,
    name: headers.name || basename(path, ".md"),
    description: headers.description || `Command: ${basename(path, ".md")}`,
    path,
  };
}

function walk(
  root: string,
  depth: number,
  installables: Installable[],
  seenSkills: Set<string>,
  seenCommands: Set<string>,
) {
  if (depth > 5) {
    return;
  }

  const skill = parseSkill(join(root, "SKILL.md"));
  if (skill && !seenSkills.has(skill.name.toLowerCase())) {
    seenSkills.add(skill.name.toLowerCase());
    installables.push(skill);
  }

  for (const entry of listEntries(root)) {
    if (!entry.isDirectory()) {
      continue;
    }

    if (skipDirectories.has(entry.name)) {
      continue;
    }

    const path = join(root, entry.name);

    if (entry.name === "commands") {
      for (const file of listEntries(path)) {
        if (!file.isFile() || extname(file.name).toLowerCase() !== ".md") {
          continue;
        }

        const base = basename(file.name, ".md").toLowerCase();
        if (base === "readme" || file.name === ".DS_Store") {
          continue;
        }

        const command = parseCommand(join(path, file.name));
        if (!command || seenCommands.has(command.name.toLowerCase())) {
          continue;
        }

        seenCommands.add(command.name.toLowerCase());
        installables.push(command);
      }

      continue;
    }

    walk(path, depth + 1, installables, seenSkills, seenCommands);
  }
}

export function discoverInstallables(root: string, subpath?: string) {
  const installables: Installable[] = [];
  const seenSkills = new Set<string>();
  const seenCommands = new Set<string>();

  walk(subpath ? join(root, subpath) : root, 0, installables, seenSkills, seenCommands);

  return installables.sort((left, right) => {
    if (left.type !== right.type) {
      return left.type === "skill" ? -1 : 1;
    }

    return left.name.localeCompare(right.name);
  });
}
