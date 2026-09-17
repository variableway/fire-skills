import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync } from "node:fs";
import type { RuntimeShare } from "../config/types.ts";
import { finderSmbUrl, smbfsTarget, volumePath } from "./url.ts";

function run(cmd: string[], opts: { inherit?: boolean } = {}): { ok: boolean; stdout: string; stderr: string } {
  const result = spawnSync(cmd[0]!, cmd.slice(1), {
    stdio: opts.inherit ? "inherit" : "pipe",
    encoding: "utf8",
  });
  return {
    ok: result.status === 0,
    stdout: (result.stdout ?? "").trim(),
    stderr: (result.stderr ?? "").trim(),
  };
}

export function assertDarwin(command: string): void {
  if (process.platform !== "darwin") {
    throw new Error(`${command} uses macOS SMB helpers (mount_smbfs / open / umount). This platform is ${process.platform}.`);
  }
}

export function isMounted(mountPoint: string): boolean {
  const result = run(["mount"]);
  if (!result.ok) return false;
  return result.stdout.split("\n").some((line) => line.includes(` on ${mountPoint} `) || line.endsWith(` on ${mountPoint}`));
}

export function runOpen(share: RuntimeShare): number {
  assertDarwin("open");
  const url = finderSmbUrl(share);
  console.log(`==> open ${url}`);
  const result = run(["open", url], { inherit: true });
  if (!result.ok) {
    console.error("[ERROR] open failed");
    return 1;
  }
  console.log(`==> Finder will mount under ${volumePath(share)} after you confirm the password`);
  return 0;
}

export function runMount(share: RuntimeShare): number {
  assertDarwin("mount");
  if (share.via === "open") return runOpen(share);

  if (!share.password) {
    console.error("[ERROR] mount_smbfs needs SELFHOST_CLI_PASSWORD, or set via=open in config.json.");
    return 1;
  }
  mkdirSync(share.mountPoint, { recursive: true });
  if (isMounted(share.mountPoint)) {
    console.log(`==> already mounted: ${share.mountPoint}`);
    return 0;
  }
  const target = smbfsTarget(share, true);
  console.log(`==> mount_smbfs //${share.user}@${share.host}/${share.share} ${share.mountPoint}`);
  const result = run(["mount_smbfs", target, share.mountPoint], { inherit: true });
  if (!result.ok) {
    console.error("[ERROR] mount_smbfs failed");
    return 1;
  }
  console.log(`==> mounted ${share.mountPoint}`);
  return 0;
}

export function runUmount(share: RuntimeShare): number {
  assertDarwin("umount");
  const candidates = [share.mountPoint, volumePath(share)].filter((path) => existsSync(path));
  if (!candidates.length) {
    console.log("==> nothing to unmount");
    return 0;
  }
  let failed = 0;
  for (const path of candidates) {
    if (!isMounted(path) && path === share.mountPoint) continue;
    console.log(`==> umount ${path}`);
    const result = run(["umount", path], { inherit: true });
    if (!result.ok) {
      console.error(`[ERROR] umount failed: ${path}`);
      failed += 1;
    }
  }
  return failed ? 1 : 0;
}

export function runStatus(share: RuntimeShare): number {
  const paths = [share.mountPoint, volumePath(share)];
  for (const path of paths) {
    const mounted = existsSync(path) && isMounted(path);
    console.log(`${mounted ? "[on] " : "[off]"} ${path}`);
  }
  return 0;
}

export function runPath(share: RuntimeShare): number {
  const preferred = share.via === "open" ? volumePath(share) : share.mountPoint;
  const actual = [preferred, share.mountPoint, volumePath(share)].find((path) => existsSync(path) && isMounted(path));
  console.log(actual ?? preferred);
  return 0;
}
