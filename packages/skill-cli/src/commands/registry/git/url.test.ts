import { describe, expect, test } from "bun:test";
import { urlKey } from "./repo.ts";

describe("urlKey", () => {
  test("normalizes ssh and trailing .git", () => {
    expect(urlKey("git@github.com:acme/foo.git")).toBe("https://github.com/acme/foo");
    expect(urlKey("https://github.com/acme/foo.git/")).toBe("https://github.com/acme/foo");
  });
});
