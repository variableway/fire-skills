import { writeFileSync } from "node:fs";
import * as p from "@clack/prompts";
import pc from "picocolors";
import { searchRegistry } from "../core/registry";
import { showIntro, showOutro, plural, getError } from "../core/output";
import { listDirectory } from "../core/sources";
import type { DirectoryEntry } from "../core/sources";
import type { SkillListItem } from "../core/types";
import { handleAddCommand } from "./add";

export interface SearchCommandOptions {
  registry?: string;
  category?: string;
  limit?: number;
  offset?: number;
  sort?: string;
  interactive?: boolean;
  output?: string;
  format?: "json" | "markdown" | "md";
}

function matchesQuery(entry: DirectoryEntry, query: string): boolean {
  const lowerQuery = query.toLowerCase();
  return entry.name.toLowerCase().includes(lowerQuery) || entry.description.toLowerCase().includes(lowerQuery);
}

function directoryEntryToSkillItem(entry: DirectoryEntry): SkillListItem {
  return {
    schemaVersion: "1",
    slug: `dir:${entry.name.toLowerCase().replace(/\s+/g, "-")}`,
    name: entry.name,
    description: entry.description,
    repository: entry.source,
    author: entry.author ? { name: entry.author } : undefined,
  };
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

function generateMarkdown(
  query: string,
  merged: SkillListItem[],
  registryCount: number,
  directoryCount: number,
): string {
  const lines: string[] = [];

  lines.push(`# Skill Search Results`);
  lines.push(``);
  lines.push(`**Query:** ${query}`);
  lines.push(`**Total:** ${merged.length} skills (registry: ${registryCount}, directory: ${directoryCount})`);
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

export async function runSearch(query: string, options: SearchCommandOptions): Promise<void> {
  if (!query) {
    await handleInteractiveSearch();
    return;
  }

  showIntro(false);

  try {
    const spinner = p.spinner();
    spinner.start("Searching registry and directory...");

    const searchParams = {
      q: query,
      category: options.category,
      limit: options.limit,
      offset: options.offset,
      sort: options.sort,
    };

    const [registryResult, directoryEntries] = await Promise.all([
      searchRegistry(searchParams, options.registry),
      listDirectory().catch(() => [] as DirectoryEntry[]),
    ]);

    spinner.stop("Search complete");

    const matchedDirEntries = directoryEntries.filter((entry) => matchesQuery(entry, query));
    const dirItems = matchedDirEntries.map(directoryEntryToSkillItem);

    const merged = mergeAndDedupe(registryResult.items, dirItems);

    if (options.output) {
      const format =
        options.format ||
        (options.output.endsWith(".md") || options.output.endsWith(".markdown") ? "markdown" : "json");

      if (format === "markdown" || format === "md") {
        const markdown = generateMarkdown(query, merged, registryResult.items.length, dirItems.length);
        writeFileSync(options.output, markdown, "utf-8");
        p.log.info(pc.dim(`Results written to ${options.output} (markdown)`));
      } else {
        const output = {
          query,
          registry: registryResult.items.length,
          directory: dirItems.length,
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

    const regCount = registryResult.items.length;
    const dirCount = dirItems.length;
    let sourceNote = "";
    if (regCount > 0 && dirCount > 0) {
      sourceNote = pc.dim(` (registry: ${regCount}, directory: ${dirCount})`);
    } else if (regCount > 0) {
      sourceNote = pc.dim(` (registry: ${regCount})`);
    } else {
      sourceNote = pc.dim(` (directory: ${dirCount})`);
    }

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

async function handleInteractiveSearch() {
  showIntro(false);

  try {
    const spinner = p.spinner();
    spinner.start("Loading directory...");
    const entries = await listDirectory();
    spinner.stop("Directory loaded");

    if (entries.length === 0) {
      p.log.warn("The skill directory is empty.");
      showOutro(pc.yellow("Nothing to browse"));
      return;
    }

    const selected = await p.autocompleteMultiselect({
      message: "Choose skills to install",
      placeholder: "Type to search...",
      options: entries.map((entry) => ({
        value: entry.name,
        label: entry.name,
        hint: entry.author ? `${entry.author} • ${entry.description}` : entry.description,
      })),
    });

    if (p.isCancel(selected)) {
      p.cancel("Search cancelled");
      return;
    }

    const names = Array.isArray(selected) ? selected : [selected];
    if (names.length === 0) {
      p.log.info("Nothing selected.");
      showOutro(pc.yellow("Nothing installed"));
      return;
    }

    for (const name of names) {
      await handleAddCommand(name, { silent: true });
    }

    showOutro(pc.green(`Installed ${names.length} ${plural(names.length, "skill")}.`));
  } catch (error) {
    p.log.error(getError(error, "Something went wrong. Try again or check your connection."));
    showOutro(pc.red("Search failed"));
    process.exit(1);
  }
}
