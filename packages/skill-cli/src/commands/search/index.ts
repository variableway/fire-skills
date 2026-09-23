import { writeFileSync } from "node:fs";
import * as p from "@clack/prompts";
import { discoverInstallables } from "@skill-spark/skill-core/discovery";
import { getError, plural, showIntro, showOutro } from "@skill-spark/skill-core/output";
import { searchRegistry } from "@skill-spark/skill-core/registry";
import type { SkillListItem } from "@skill-spark/skill-core/types";
import pc from "picocolors";
import { handleAddCommand } from "../skill/add.js";

export const COMMAND_DESCRIPTION = "Search skills from registry or browse interactively";
export const COMMAND_EXAMPLES = [
  "skill-spark search my-skill",
  "skill-spark search --sources directory --dir factory/skills",
  "skill-spark find --interactive",
];
export const COMMAND_PREREQUISITES = [
  "Registry must be accessible for remote searches",
  "Local skills must have valid SKILL.md files",
];

export interface SearchCommandOptions {
  registry?: string;
  category?: string;
  limit?: number;
  offset?: number;
  sort?: string;
  interactive?: boolean;
  sources?: string[];
  dir?: string;
  depth?: number;
  output?: string;
  format?: string;
}

function mergeAndDedupe(registryItems: SkillListItem[], directoryItems: SkillListItem[]): SkillListItem[] {
  const seen = new Set<string>();
  const merged: SkillListItem[] = [];

  for (const item of [...registryItems, ...directoryItems]) {
    const key = item.slug || item.name.toLowerCase();
    if (!seen.has(key)) {
      seen.add(key);
      merged.push(item);
    }
  }

  return merged;
}

export const DEFAULT_DIRECTORY_DEPTH = 2;

export function searchDirectorySkills(query: string, dir = ".", depth = DEFAULT_DIRECTORY_DEPTH) {
  const items: SkillListItem[] = [];

  for (const installable of discoverInstallables(dir, undefined, depth)) {
    if (installable.type !== "skill") {
      continue;
    }

    const lowerQuery = query.toLowerCase();
    if (
      !installable.name.toLowerCase().includes(lowerQuery) &&
      !installable.description.toLowerCase().includes(lowerQuery)
    ) {
      continue;
    }

    items.push({
      schemaVersion: "1",
      slug: `dir:${installable.name.toLowerCase().replace(/\s+/g, "-")}`,
      name: installable.name,
      description: installable.description,
      repository: installable.path,
    });
  }

  return items;
}

const VALID_SOURCES = new Set(["registry", "directory"]);

function splitSources(sources: string[] | undefined): string[] {
  if (!sources || sources.length === 0) {
    return [];
  }

  return [
    ...new Set(
      sources
        .flatMap((source) => source.split(","))
        .map((source) => source.trim().toLowerCase())
        .filter(Boolean)
        .map((source) => (source === "local" || source === "flins" ? "directory" : source)),
    ),
  ];
}

function normalizeSources(sources: string[] | undefined) {
  const tokens = splitSources(sources);
  if (tokens.length === 0) {
    return new Set(["registry", "directory"]);
  }

  return new Set(tokens);
}

export function findUnknownSources(sources: string[] | undefined): string[] {
  return splitSources(sources).filter((source) => !VALID_SOURCES.has(source));
}

function warnUnknownSources(sources: string[] | undefined): void {
  const unknown = findUnknownSources(sources);
  if (unknown.length > 0) {
    p.log.warn(
      `Ignoring unknown source${unknown.length > 1 ? "s" : ""}: ${unknown.join(", ")}. Valid sources: registry, directory. The directory source scans --dir <path> (default: current directory, ${DEFAULT_DIRECTORY_DEPTH} levels deep).`,
    );
  }
}

function resolveDepth(depth: number | undefined): number {
  const value = depth ?? DEFAULT_DIRECTORY_DEPTH;
  if (!Number.isInteger(value) || value < 0) {
    throw new Error("--depth must be a non-negative integer");
  }
  return value;
}

function generateMarkdown(query: string, merged: SkillListItem[], counts: Record<string, number>): string {
  const lines: string[] = [];

  lines.push(`# Skill Search Results`);
  lines.push(``);
  lines.push(`**Query:** ${query}`);
  lines.push(
    `**Total:** ${merged.length} skills (${Object.entries(counts)
      .map(([source, count]) => `${source}: ${count}`)
      .join(", ")})`,
  );
  lines.push(`**Date:** ${new Date().toISOString()}`);
  lines.push(``);
  lines.push(`---`);
  lines.push(``);

  for (const item of merged) {
    lines.push(`## ${item.name}`);
    lines.push(``);

    if (item.author) {
      lines.push(`**Author:** ${item.author.name}`);
    }

    if (item.repository) {
      lines.push(`**Source:** ${item.repository}`);
    }

    if (item.tags && item.tags.length > 0) {
      lines.push(`**Tags:** ${item.tags.join(", ")}`);
    }

    lines.push(``);
    lines.push(item.description);
    lines.push(``);
    lines.push(`---`);
    lines.push(``);
  }

  return lines.join("\n");
}

export async function runSearch(query: string | undefined, options: SearchCommandOptions): Promise<void> {
  if (!query || options.interactive) {
    await handleInteractiveSearch(query, options);
    return;
  }

  showIntro(false);

  try {
    warnUnknownSources(options.sources);

    const spinner = p.spinner();
    spinner.start("Searching skills...");

    const searchParams = {
      q: query,
      category: options.category,
      limit: options.limit,
      offset: options.offset,
      sort: options.sort,
    };

    const sources = normalizeSources(options.sources);

    const [registryResult, directoryItems] = await Promise.all([
      sources.has("registry") ? searchRegistry(searchParams, options.registry) : Promise.resolve({ items: [] }),
      Promise.resolve(
        sources.has("directory")
          ? searchDirectorySkills(query, options.dir, resolveDepth(options.depth))
          : ([] as SkillListItem[]),
      ),
    ]);

    spinner.stop("Search complete");

    const merged = mergeAndDedupe(registryResult.items, directoryItems);
    const counts = {
      registry: registryResult.items.length,
      directory: directoryItems.length,
    };

    if (options.output) {
      const format =
        options.format ||
        (options.output.endsWith(".md") || options.output.endsWith(".markdown") ? "markdown" : "json");

      if (!["json", "markdown", "md"].includes(format)) {
        throw new Error(`Unsupported format: ${format}`);
      }

      if (format === "markdown" || format === "md") {
        const markdown = generateMarkdown(query, merged, counts);
        writeFileSync(options.output, markdown, "utf-8");
        p.log.info(pc.dim(`Results written to ${options.output} (markdown)`));
      } else {
        const output = {
          query,
          sources: counts,
          total: merged.length,
          skills: merged,
        };
        writeFileSync(options.output, JSON.stringify(output, null, 2), "utf-8");
        p.log.info(pc.dim(`Results written to ${options.output} (json)`));
      }
    }

    if (merged.length === 0) {
      p.log.warn("No skills found.");
      showOutro(pc.yellow("No results"));
      return;
    }

    const sourceNote = pc.dim(
      ` (${Object.entries(counts)
        .filter(([, count]) => count > 0)
        .map(([source, count]) => `${source}: ${count}`)
        .join(", ")})`,
    );

    p.log.step(pc.bold(`Found ${merged.length} skills${sourceNote}`));

    for (const item of merged.slice(0, 20)) {
      const desc = item.description.slice(0, 60);
      p.log.message(`  ${pc.cyan(item.name)} ${pc.dim(desc)}${item.description.length > 60 ? "..." : ""}`);
    }

    if (merged.length > 20) {
      p.log.info(pc.dim(`Showing 20 of ${merged.length} results. Use --limit to see more.`));
    }

    showOutro(pc.green(`Found ${merged.length} skills`));
  } catch (error) {
    p.log.error(getError(error, "Search failed."));
    showOutro(pc.red("Search failed"));
    process.exit(1);
  }
}

type InstallKind = "local" | "directory";

interface InstallPick {
  kind: InstallKind;
  ref: string;
}

interface BrowseOption {
  value: string;
  label: string;
  hint: string;
}

export function encodePickValue(kind: InstallKind, ref: string): string {
  return `${kind}:${ref}`;
}

export function decodePickValue(value: string): InstallPick | null {
  if (value.startsWith("local:")) {
    return { kind: "local", ref: value.slice("local:".length) };
  }
  if (value.startsWith("directory:")) {
    return { kind: "directory", ref: value.slice("directory:".length) };
  }
  return null;
}

function localItemMatches(item: SkillListItem, query: string): boolean {
  const lowerQuery = query.toLowerCase();
  return item.name.toLowerCase().includes(lowerQuery) || item.description.toLowerCase().includes(lowerQuery);
}

export function buildBrowseOptions(items: SkillListItem[], query?: string): BrowseOption[] {
  const trimmed = query?.trim().toLowerCase() ?? "";
  const filtered = trimmed ? items.filter((item) => localItemMatches(item, trimmed)) : items;

  return filtered.map((item) => ({
    value: encodePickValue("directory", item.repository || item.name),
    label: item.name,
    hint: item.repository ? `${item.repository} — ${item.description}` : item.description,
  }));
}

async function handleInteractiveSearch(query: string | undefined, options: SearchCommandOptions) {
  showIntro(false);

  try {
    if (!process.stdout.isTTY) {
      throw new Error("interactive mode requires a TTY; run it in a terminal without piping stdout");
    }

    warnUnknownSources(options.sources);

    const sources = normalizeSources(options.sources);
    const directoryItems = sources.has("directory")
      ? searchDirectorySkills("", options.dir, resolveDepth(options.depth))
      : [];

    const browseOptions = buildBrowseOptions(directoryItems, query);

    if (browseOptions.length === 0) {
      p.log.warn("No skills found to browse.");
      showOutro(pc.yellow("Nothing to browse"));
      return;
    }

    const selected = await p.autocompleteMultiselect({
      message: "Choose skills to install",
      placeholder: "Type to search...",
      options: browseOptions,
    });

    if (p.isCancel(selected)) {
      p.cancel("Search cancelled");
      return;
    }

    const values = Array.isArray(selected) ? selected : [selected];
    if (values.length === 0) {
      p.log.info("Nothing selected.");
      showOutro(pc.yellow("Nothing installed"));
      return;
    }

    const scopeChoice = await p.select({
      message: "Install scope",
      options: [
        { value: "project", label: "Project", hint: "./skills.lock + project agent directories" },
        { value: "global", label: "Global", hint: "~/.skill-spark/skills.lock + agent global directories" },
      ],
    });

    if (p.isCancel(scopeChoice)) {
      p.cancel("Search cancelled");
      return;
    }

    const global = scopeChoice === "global";

    let installed = 0;
    const failures: string[] = [];

    for (const [index, value] of values.entries()) {
      const pick = decodePickValue(value);
      if (!pick) {
        failures.push(value);
        continue;
      }

      p.log.step(pc.bold(`Installing ${index + 1}/${values.length}: ${pick.ref}`));
      try {
        await handleAddCommand(pick.ref, { global, force: true });
        installed += 1;
      } catch (error) {
        failures.push(`${pick.ref}: ${error instanceof Error ? error.message : String(error)}`);
      }
    }

    if (failures.length > 0) {
      for (const failure of failures) {
        p.log.error(failure);
      }
      showOutro(pc.yellow(`Installed ${installed}, failed ${failures.length}`));
      return;
    }

    showOutro(pc.green(`Installed ${installed} ${plural(installed, "skill")}.`));
  } catch (error) {
    p.log.error(getError(error, "Something went wrong. Try again or check your connection."));
    showOutro(pc.red("Search failed"));
    process.exit(1);
  }
}
