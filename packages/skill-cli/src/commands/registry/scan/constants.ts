import type { RuntimeLayout } from "../config/types.ts";
import type { Project } from "../store/types.ts";

export type MergeStats = {
  moved: string[];
  missing: Project[];
  added: Project[];
  dup: string[];
};

export type ScanOptions = {
  layout: RuntimeLayout;
  registry: string;
  dirs: string[];
  depth: number;
  keepMissing: boolean;
  regenerate: boolean;
  syncedBy: string;
  consumedBy: string | null;
};

export const DEFAULT_SCAN_DEPTH = 3;
