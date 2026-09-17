import type { RuntimeShare } from "../config/types.ts";

function encodeShare(share: string): string {
  return share
    .split("/")
    .filter((part) => part.length > 0)
    .map((part) => encodeURIComponent(part))
    .join("/");
}

export function smbfsTarget(share: RuntimeShare, includePassword: boolean): string {
  const user = encodeURIComponent(share.user);
  const path = encodeShare(share.share);
  if (includePassword && share.password) {
    return `//${user}:${encodeURIComponent(share.password)}@${share.host}/${path}`;
  }
  return `//${user}@${share.host}/${path}`;
}

export function finderSmbUrl(share: RuntimeShare): string {
  return `smb:${smbfsTarget(share, false)}`;
}

export function volumePath(share: RuntimeShare): string {
  const name = share.share.split("/").filter(Boolean).at(-1) || share.share;
  return `/Volumes/${name}`;
}
