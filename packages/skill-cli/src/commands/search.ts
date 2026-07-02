import { existsSync, writeFileSync } from "node:fs";
import * as p from "@clack/prompts";
import { discoverInstallables } from "@skill-spark/skill-core/discovery";
import { getError, plural, showIntro, showOutro } from "@skill-spark/skill-core/output";
import { searchRegistry } from "@skill-spark/skill-core/registry";
import type { DirectoryEntry } from "@skill-spark/skill-core/sources";
import { listDirectory } from "@skill-spark/skill-core/sources";
import type { SkillListItem } from "@skill-spark/skill-core/types";
import pc from "picocolors";
import { handleAddCommand } from "./add";

export interface SearchCommandOptions {
  registry?: string;
  category?: string;
  limit?: number;
  offset?: number;
  sort?: string;
  interactive?: boolean;
  sources?: string[];
  output?: string;
  format?: string;
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

function normalizeSources(sources: string[] | undefined) {
  if (!sources || sources.length === 0) {
    return new Set(["registry", "directory"]);
  }

  return new Set(
    sources
      .flatMap((source) => source.split(","))
      .map((source) => source.trim().toLowerCase())
      .filter(Boolean)
      .map((source) => (source === "flins" ? "directory" : source)),
  );
}

function searchLocalSkills(query: string) {
  const localRoots = ["skills", ".agents/skills"];
  const items: SkillListItem[] = [];

  for (const root of localRoots) {
    if (!existsSync(root)) {
      continue;
    }

    for (const installable of discoverInstallables(root)) {
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
        slug: `local:${root}:${installable.name}`,
        name: installable.name,
        description: installable.description,
        repository: installable.path,
      });
    }
  }

  return items;
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

    const sources = normalizeSources(options.sources);

    const [registryResult, directoryEntries] = await Promise.all([
      sources.has("registry") ? searchRegistry(searchParams, options.registry) : Promise.resolve({ items: [] }),
      sources.has("directory") ? listDirectory().catch(() => [] as DirectoryEntry[]) : Promise.resolve([]),
    ]);

    spinner.stop("Search complete");

    const matchedDirEntries = directoryEntries.filter((entry) => matchesQuery(entry, query));
    const dirItems = matchedDirEntries.map(directoryEntryToSkillItem);
    const localItems = sources.has("local") ? searchLocalSkills(query) : [];

    const merged = mergeAndDedupe(registryResult.items, [...dirItems, ...localItems]);
    const counts = {
      registry: registryResult.items.length,
      directory: dirItems.length,
      local: localItems.length,
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
