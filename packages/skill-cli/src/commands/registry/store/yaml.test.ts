import { afterAll, describe, expect, test } from "bun:test";
import { mkdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { extraFields, readExisting, sectionOf, writeRegistry, yamlScalar } from "./yaml.ts";

describe("yamlScalar", () => {
  test("quotes leading @ for npm scopes", () => {
    expect(yamlScalar("@innate/ui")).toBe('"@innate/ui"');
  });

  test("leaves plain tokens unquoted", () => {
    expect(yamlScalar("app")).toBe("app");
  });
});

describe("sectionOf", () => {
  const rules = { secondOnly: ["apps"], keepPrefix: ["refs"] };

  test("secondOnly uses the category folder", () => {
    expect(sectionOf("apps/content/feeds", rules)).toBe("content");
  });

  test("keepPrefix keeps the first two segments", () => {
    expect(sectionOf("refs/fe/foo", rules)).toBe("refs/fe");
  });

  test("other paths use the first segment", () => {
    expect(sectionOf("skills/wip-skills", rules)).toBe("skills");
  });
});

describe("extraFields", () => {
  test("keeps kind/template/deploy/publishes", () => {
    expect(
      extraFields({
        name: "innate-wip",
        repo: "https://example.com/wip.git",
        path: "innate-apps/content/innate-wip",
        desc: "flagship",
        kind: "app",
        template: "app-content",
        templateVersion: "v0",
        deploy: ["pages", "cloudflare"],
      }),
    ).toEqual({
      kind: "app",
      template: "app-content",
      templateVersion: "v0",
      deploy: ["pages", "cloudflare"],
    });
  });
});

describe("registry round-trip", () => {
  const dir = join(tmpdir(), `registry-store-${Date.now()}`);
  const registry = join(dir, "apps.yaml");
  mkdirSync(dir, { recursive: true });
  afterAll(() => {
    rmSync(dir, { recursive: true, force: true });
  });

  const projects = [
    {
      name: "sample-app",
      repo: "https://example.com/wip.git",
      path: "sample-apps/content/sample-app",
      desc: "flagship",
      kind: "app",
      template: "app-content",
      templateVersion: "v0",
      deploy: ["pages", "cloudflare"],
    },
    {
      name: "sample-fe-base",
      repo: "https://example.com/fe-templates.git",
      path: "my-hub/base/sample-fe-base",
      desc: "Hub-hosted shared base project",
      publishes: ["@innate/ui"],
    },
  ];

  test("write then read keeps every field", () => {
    expect(readExisting(registry)).toEqual([]);
    writeRegistry(projects, registry, "test scan", "test clone", { keepPrefix: ["my-hub"] });
    const again = readExisting(registry);
    expect(again).toEqual(projects);
  });
});
