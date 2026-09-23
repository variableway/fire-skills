import { describe, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { SkillListItem } from "@skill-spark/skill-core/types";
import {
  buildBrowseOptions,
  decodePickValue,
  encodePickValue,
  findUnknownSources,
  searchDirectorySkills,
} from "./index.ts";

const items: SkillListItem[] = [
  {
    schemaVersion: "1",
    slug: "dir:git-pr",
    name: "git-pr",
    description: "GitHub Pull Request 工作流",
    repository: "devops-skill/git-pr",
  },
  {
    schemaVersion: "1",
    slug: "dir:docmd",
    name: "docmd",
    description: "Scaffold and build a bilingual documentation site",
    repository: "devops-skill/docmd",
  },
];

describe("encodePickValue / decodePickValue", () => {
  test("round-trips directory picks with paths", () => {
    const value = encodePickValue("directory", "devops-skill/git-pr");
    expect(decodePickValue(value)).toEqual({ kind: "directory", ref: "devops-skill/git-pr" });
  });

  test("still decodes legacy local-prefixed values", () => {
    expect(decodePickValue("local:skills/devops-skill/git-pr")).toEqual({
      kind: "local",
      ref: "skills/devops-skill/git-pr",
    });
  });

  test("returns null for values without a known prefix", () => {
    expect(decodePickValue("git-pr")).toBeNull();
    expect(decodePickValue("registry:git-pr")).toBeNull();
  });
});

describe("buildBrowseOptions", () => {
  test("encodes installable refs into option values", () => {
    const options = buildBrowseOptions(items);
    expect(options.map((option) => option.label)).toEqual(["git-pr", "docmd"]);
    expect(options[0]?.value).toBe("directory:devops-skill/git-pr");
  });

  test("filters by name case-insensitively", () => {
    const options = buildBrowseOptions(items, "GIT-PR");
    expect(options.map((option) => option.label)).toEqual(["git-pr"]);
  });

  test("filters by description", () => {
    const options = buildBrowseOptions(items, "documentation");
    expect(options.map((option) => option.label)).toEqual(["docmd"]);
  });

  test("keeps everything when the query is blank", () => {
    const options = buildBrowseOptions(items, "   ");
    expect(options).toHaveLength(2);
  });

  test("exposes the source path in hints", () => {
    const options = buildBrowseOptions(items);
    expect(options[0]?.hint).toContain("devops-skill/git-pr");
  });
});

describe("findUnknownSources", () => {
  test("flags directory names passed as sources", () => {
    expect(findUnknownSources(["devops-skill"])).toEqual(["devops-skill"]);
  });

  test("accepts registry, directory and the legacy local/flins aliases", () => {
    expect(findUnknownSources(["registry", "directory"])).toEqual([]);
    expect(findUnknownSources(["local"])).toEqual([]);
    expect(findUnknownSources(["flins"])).toEqual([]);
  });

  test("splits comma-separated tokens and dedupes", () => {
    expect(findUnknownSources(["directory,devops-skill,devops-skill"])).toEqual(["devops-skill"]);
  });

  test("returns nothing when no sources are given", () => {
    expect(findUnknownSources(undefined)).toEqual([]);
    expect(findUnknownSources([])).toEqual([]);
  });
});

describe("searchDirectorySkills", () => {
  const fixture = mkdtempSync(join(tmpdir(), "skill-spark-dirscan-"));

  function makeSkill(path: string, name: string) {
    mkdirSync(join(fixture, path), { recursive: true });
    writeFileSync(
      join(fixture, path, "SKILL.md"),
      `---\nname: ${name}\ndescription: fixture skill ${name}\n---\n\nbody\n`,
    );
  }

  test("scans two levels below the root by default", () => {
    makeSkill("level-1", "one");
    makeSkill(join("level-1", "level-2"), "two");
    makeSkill(join("level-1", "level-2", "level-3"), "three");

    const found = searchDirectorySkills("", fixture).map((item) => item.name);
    expect(found).toContain("one");
    expect(found).toContain("two");
    expect(found).not.toContain("three");
  });

  test("honors a deeper --depth", () => {
    const found = searchDirectorySkills("", fixture, 3).map((item) => item.name);
    expect(found).toContain("three");
  });

  test("filters by query and reports the skill directory", () => {
    const found = searchDirectorySkills("one", fixture);
    expect(found).toHaveLength(1);
    expect(found[0]?.repository).toBe(join(fixture, "level-1"));
  });

  rmSync(fixture, { recursive: true, force: true });
});
