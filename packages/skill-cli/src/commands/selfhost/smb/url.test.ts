import { describe, expect, test } from "bun:test";
import type { RuntimeShare } from "../config/types.ts";
import { finderSmbUrl, smbfsTarget, volumePath } from "./url.ts";

const share: RuntimeShare = {
  name: "home",
  host: "192.168.1.5",
  share: "share",
  user: "admin",
  password: "p@ss:word",
  mountPoint: "/tmp/disk",
  via: "open",
};

describe("smb urls", () => {
  test("open url never embeds the password", () => {
    expect(finderSmbUrl(share)).toBe("smb://admin@192.168.1.5/share");
    expect(finderSmbUrl(share)).not.toContain("p@ss");
  });

  test("mount_smbfs url encodes reserved password characters", () => {
    expect(smbfsTarget(share, true)).toBe("//admin:p%40ss%3Aword@192.168.1.5/share");
  });

  test("volume path uses the last share segment", () => {
    expect(volumePath(share)).toBe("/Volumes/share");
    expect(volumePath({ ...share, share: "disk/media" })).toBe("/Volumes/media");
  });
});
