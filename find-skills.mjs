#!/usr/bin/env node
/**
 * Unified skill search across configured sources (data/sources.yaml).
 *
 * Usage:
 *   node scripts/find-skills.mjs <query>
 *   node scripts/find-skills.mjs <query> --source skillsllm
 *   node scripts/find-skills.mjs <query> --json
 */
import { readFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { parse as parseYaml } from "yaml";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");
const SOURCES_FILE = join(ROOT, "data", "sources.yaml");
const MANIFEST_FILE = join(ROOT, "data", "manifest.json");

function loadSources() {
  const doc = parseYaml(readFileSync(SOURCES_FILE, "utf8"));
  return doc.sources ?? [];
}

function parseArgs(argv) {
  const flags = { json: false, source: null };
  const queryParts = [];
  for (const arg of argv) {
    if (arg === "--json") flags.json = true;
    else if (arg === "--source") continue;
    else if (argv[argv.indexOf(arg) - 1] === "--source") flags.source = arg;
    else if (arg.startsWith("--")) {
      /* skip unknown flags */
    } else queryParts.push(arg);
  }
  return { query: queryParts.join(" ").trim(), ...flags };
}

async function searchLocal(query) {
  if (!existsSync(MANIFEST_FILE)) return [];
  const { skills } = JSON.parse(readFileSync(MANIFEST_FILE, "utf8"));
  const q = query.toLowerCase();
  return skills
    .filter(
      (s) =>
        !q ||
        s.name.toLowerCase().includes(q) ||
        s.description.toLowerCase().includes(q) ||
        s.path.toLowerCase().includes(q),
    )
    .map((s) => ({
      source: "local",
      name: s.name,
      description: s.description,
      url: s.path,
      install: `skills/${s.path.replace(/^skills\//, "")}`,
      meta: { scope: s.scope },
    }));
}

async function searchApi(source, query) {
  const { search, limit = 10 } = source.api;
  const url = new URL(search);
  url.searchParams.set("q", query);
  url.searchParams.set("limit", String(limit));

  const res = await fetch(url);
  if (!res.ok) throw new Error(`${source.id}: HTTP ${res.status}`);

  const data = await res.json();
  const items = data.skills ?? data.results ?? data.items ?? [];

  return items.map((s) => ({
    source: source.id,
    name: s.name ?? s.slug,
    description: (s.description ?? "").slice(0, 200),
    url: s.repoUrl ?? s.url ?? `${source.browse}/${s.slug ?? s.name}`,
    install: s.repoUrl ? `git clone ${s.repoUrl}` : null,
    meta: {
      stars: s.stars,
      security: s.securityStatus,
      category: s.category?.name,
      hasSkillMd: s.hasSkillMd,
    },
  }));
}

function searchCli(source, query) {
  const cmd = source.cli?.search;
  if (!cmd) return { source: source.id, hits: [], raw: "" };

  const [bin, ...baseArgs] = cmd.split(/\s+/);
  const result = spawnSync(bin, [...baseArgs, query], {
    encoding: "utf8",
    shell: bin === "npx",
    timeout: 60_000,
  });

  if (result.error?.code === "ENOENT") {
    throw new Error(`${source.id}: command not found (${bin})`);
  }

  const raw = (result.stdout || result.stderr || "").trim();
  const hits = raw
    ? raw.split("\n").filter(Boolean).map((line) => ({
        source: source.id,
        name: line.trim(),
        description: "",
        url: source.browse,
        install: source.cli.install ?? null,
        meta: { line },
      }))
    : [];

  return { source: source.id, hits, raw, exitCode: result.status };
}

function printHuman(results, cliRaw) {
  const bySource = new Map();
  for (const r of results) {
    if (!bySource.has(r.source)) bySource.set(r.source, []);
    bySource.get(r.source).push(r);
  }

  for (const [sourceId, hits] of bySource) {
    console.log(`\n## ${sourceId} (${hits.length})`);
    for (const h of hits) {
      console.log(`  • ${h.name}`);
      if (h.description) console.log(`    ${h.description}`);
      if (h.url) console.log(`    ${h.url}`);
      if (h.meta?.stars != null)
        console.log(`    ⭐ ${h.meta.stars.toLocaleString()} · security: ${h.meta.security ?? "?"}`);
      if (h.install) console.log(`    install: ${h.install}`);
    }
  }

  for (const { source, raw } of cliRaw) {
    if (raw) {
      console.log(`\n## ${source} (raw CLI output)`);
      console.log(raw);
    }
  }
}

async function main() {
  const { query, json, source: onlySource } = parseArgs(process.argv.slice(2));

  if (!query) {
    console.error("Usage: pnpm find-skills <query> [--source <id>] [--json]");
    process.exit(1);
  }

  const sources = loadSources().filter(
    (s) => s.enabled && (!onlySource || s.id === onlySource),
  );

  const results = [];
  const cliRaw = [];
  const errors = [];

  for (const source of sources) {
    try {
      if (source.type === "local") {
        results.push(...(await searchLocal(query)));
      } else if (source.type === "api") {
        results.push(...(await searchApi(source, query)));
      } else if (source.type === "cli") {
        const out = searchCli(source, query);
        results.push(...out.hits);
        if (out.raw) cliRaw.push({ source: out.source, raw: out.raw });
      }
    } catch (e) {
      errors.push({ source: source.id, message: e instanceof Error ? e.message : String(e) });
    }
  }

  if (json) {
    console.log(JSON.stringify({ query, results, errors, cliRaw }, null, 2));
    return;
  }

  console.log(`Query: "${query}" · ${results.length} structured hit(s)`);
  if (results.length) printHuman(results, []);
  else if (cliRaw.length) printHuman([], cliRaw);
  else console.log("(no results)");

  if (errors.length) {
    console.log("\nSkipped sources:");
    for (const e of errors) console.log(`  • ${e.source}: ${e.message}`);
  }

  console.log("\nAdd sources in data/sources.yaml · browse signals on each hub's website.");
}

main();
