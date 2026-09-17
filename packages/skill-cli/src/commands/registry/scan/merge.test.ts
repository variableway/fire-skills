import { describe, expect, test } from "bun:test";
import type { Project } from "../store/types.ts";
import { merge } from "./merge.ts";

describe("merge", () => {
  const old: Project = {
    name: "wip",
    repo: "https://github.com/acme/wip.git",
    path: "innate-apps/content/wip",
    desc: "kept desc",
    kind: "app",
    template: "app-content",
  };

  test("path match keeps name/desc/extra and refreshes repo", () => {
    const { final, changes } = merge(
      [old],
      [
        {
          name: "wip",
          repo: "https://github.com/acme/wip.git",
          path: "innate-apps/content/wip",
          desc: "",
        },
      ],
    );
    expect(final[0]).toMatchObject({
      name: "wip",
      desc: "kept desc",
      kind: "app",
      template: "app-content",
    });
    expect(changes.added).toEqual([]);
    expect(changes.missing).toEqual([]);
  });

  test("url match treats a path change as a move", () => {
    const { final, changes } = merge(
      [old],
      [
        {
          name: "wip",
          repo: "https://github.com/acme/wip.git",
          path: "innate-apps/sites/wip",
          desc: "",
        },
      ],
    );
    expect(final[0]?.path).toBe("innate-apps/sites/wip");
    expect(final[0]?.kind).toBe("app");
    expect(changes.moved).toEqual(["innate-apps/content/wip -> innate-apps/sites/wip"]);
  });

  test("missing directories are dropped unless keepMissing", () => {
    const dropped = merge([old], []);
    expect(dropped.final).toEqual([]);
    expect(dropped.changes.missing).toHaveLength(1);

    const kept = merge([old], [], true);
    expect(kept.final).toEqual([old]);
  });

  test("new repos are appended", () => {
    const { final, changes } = merge(
      [old],
      [
        old,
        {
          name: "feeds",
          repo: "https://github.com/acme/feeds.git",
          path: "innate-apps/content/feeds",
          desc: "",
        },
      ],
    );
    expect(changes.added.map((p) => p.name)).toEqual(["feeds"]);
    expect(final.map((p) => p.name)).toEqual(["wip", "feeds"]);
  });
});
