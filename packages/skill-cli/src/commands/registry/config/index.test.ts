import { afterAll, describe, expect, test } from "bun:test";
import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, join, resolve } from "node:path";
import { resolveLayout, resolveOnDisk, resolveScanRoot } from "./index.ts";
import type { RuntimeLayout } from "./types.ts";

function layout(partial: Partial<RuntimeLayout>): RuntimeLayout {
  return {
    hubRoot: "/hub",
    hubName: "",
    worksRoot: "/works",
    appsRoot: "/works",
    appsPrefix: "",
    registry: "/hub/registry.yaml",
    refsRegistry: "",
    scanDirs: [],
    refsScanDirs: [],
    sectionSecondOnly: [],
    sectionKeepPrefix: [],
    defaultDescBySection: {},
    ignoreDirs: new Set(),
    ...partial,
  };
}

describe("resolveOnDisk", () => {
  test("maps appsPrefix onto appsRoot and leaves other paths on worksRoot", () => {
    const current = layout({
      worksRoot: "/works",
      appsRoot: "/elsewhere/apps",
      appsPrefix: "my-apps",
    });
    expect(resolveOnDisk(current, "my-apps/foo")).toBe("/elsewhere/apps/foo");
    expect(resolveOnDisk(current, "my-apps")).toBe("/elsewhere/apps");
    expect(resolveOnDisk(current, "base/x")).toBe("/works/base/x");
  });

  test("maps hubName paths onto hubRoot", () => {
    const current = layout({ hubRoot: "/hub", hubName: "my-hub", worksRoot: "/works" });
    expect(resolveOnDisk(current, "my-hub/base/x")).toBe("/hub/base/x");
    expect(resolveOnDisk(current, "my-hub")).toBe("/hub");
    expect(resolveOnDisk(current, "base/x")).toBe("/works/base/x");
  });

  test("appsPrefix wins when it collides with hubName", () => {
    const current = layout({
      hubRoot: "/hub",
      hubName: "shared",
      appsRoot: "/elsewhere/apps",
      appsPrefix: "shared",
    });
    expect(resolveOnDisk(current, "shared/foo")).toBe("/elsewhere/apps/foo");
  });
});

describe("resolveScanRoot", () => {
  test("routes hub-prefixed scan dirs into the hub with hub-relative paths", () => {
    const current = layout({ hubRoot: "/parent/my-hub", hubName: "my-hub", worksRoot: "/works" });
    expect(resolveScanRoot(current, "my-hub")).toEqual({ root: "/parent/my-hub", relBase: "/parent" });
    expect(resolveScanRoot(current, "my-hub/base")).toEqual({ root: "/parent/my-hub/base", relBase: "/parent" });
  });

  test("keeps plain dirs on worksRoot", () => {
    const current = layout({ hubRoot: "/parent/my-hub", hubName: "my-hub", worksRoot: "/works" });
    expect(resolveScanRoot(current, "base")).toEqual({ root: "/works/base", relBase: "/works" });
  });
});

describe("resolveLayout", () => {
  const hub = join(tmpdir(), `registry-cli-${Date.now()}`);
  mkdirSync(hub, { recursive: true });
  writeFileSync(
    join(hub, ".innate-registry-cli.yaml"),
    [
      "worksRoot: ../works-tree",
      "worksName: works-tree",
      "appsRoot: ../apps-tree",
      "appsPrefix: my-apps",
      "registry: tools/registry/apps.yaml",
      "refsRegistry: registry.yaml",
      "scanDirs:",
      "  - my-apps",
      "  - base",
      "",
    ].join("\n"),
  );

  test("resolves a fixture hub relative to its own config file", () => {
    const current = resolveLayout(hub);
    expect(current.hubRoot).toBe(hub);
    expect(current.hubName).toBe(basename(hub));
    expect(current.worksRoot).toBe(resolve(hub, "../works-tree"));
    expect(current.appsRoot).toBe(resolve(hub, "../apps-tree"));
    expect(current.appsPrefix).toBe("my-apps");
    expect(current.registry).toBe(resolve(hub, "tools/registry/apps.yaml"));
    expect(current.refsRegistry).toBe(resolve(hub, "../works-tree/registry.yaml"));
    expect(current.scanDirs).toEqual(["my-apps", "base"]);
  });

  test("CLI overrides win over the config file", () => {
    const current = resolveLayout(hub, {
      worksRoot: "/tmp/other-works",
      worksName: "ignored-when-root-set",
      appsPrefix: "pkgs",
      appsRoot: "/tmp/pkgs",
    });
    expect(current.worksRoot).toBe("/tmp/other-works");
    expect(current.appsPrefix).toBe("pkgs");
    expect(current.appsRoot).toBe("/tmp/pkgs");
  });

  test("an explicit missing config file is reported", () => {
    expect(() => resolveLayout(hub, { configPath: "nope.yaml" })).toThrow(/config file not found/);
  });

  afterAll(() => {
    rmSync(hub, { recursive: true, force: true });
  });
});
