import { describe, expect, test } from "bun:test";
import { mkdirSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { expandHome, listProfiles, readFileConfig, resolveShare } from "./index.ts";

describe("expandHome", () => {
  test("expands ~", () => {
    expect(expandHome("~/Desktop/disk")).toBe(join(homedir(), "Desktop/disk"));
  });
});

describe("config.json profiles", () => {
  const dir = join(tmpdir(), `selfhost-cli-${Date.now()}`);
  const path = join(dir, "config.json");

  mkdirSync(dir, { recursive: true });
  writeFileSync(
    path,
    JSON.stringify({
      default: "home",
      profiles: {
        home: {
          host: "192.168.1.5",
          share: "share",
          user: "admin",
          mountPoint: "/tmp/smbfs-home",
          via: "open",
        },
        office: {
          host: "nas.example",
          share: "media",
          user: "ops",
          mountPoint: "/tmp/smbfs-office",
          via: "smbfs",
        },
      },
    }),
  );

  test("reads named profiles from one json file", () => {
    const file = readFileConfig(path);
    expect(listProfiles(file)).toEqual(["home", "office"]);
    const home = resolveShare(dir, { configPath: path });
    expect(home.name).toBe("home");
    expect(home.host).toBe("192.168.1.5");
    expect(home.via).toBe("open");
    const office = resolveShare(dir, { configPath: path, profile: "office" });
    expect(office.name).toBe("office");
    expect(office.share).toBe("media");
    expect(office.via).toBe("smbfs");
  });

  test("password comes only from SELFHOST_CLI_PASSWORD", () => {
    const prev = process.env.SELFHOST_CLI_PASSWORD;
    process.env.SELFHOST_CLI_PASSWORD = "from-env";
    const share = resolveShare(dir, { configPath: path, profile: "home" });
    expect(share.password).toBe("from-env");
    if (prev === undefined) delete process.env.SELFHOST_CLI_PASSWORD;
    else process.env.SELFHOST_CLI_PASSWORD = prev;
  });
});
