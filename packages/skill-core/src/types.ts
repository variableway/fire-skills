export type TargetEnvironment = "codex" | "gemini" | "claude" | "agent" | "qwen";

export interface SkillListItem {
  schemaVersion: string;
  slug: string;
  name: string;
  description: string;
  repository: string;
  verified?: boolean;
  stars?: number;
  tags?: string[];
  author?: { name: string; url?: string };
  signals?: {
    lastUpdated?: string;
    license?: string;
    riskHints?: string[];
  };
}

export interface RegistrySearchResponse {
  items: SkillListItem[];
  raw?: unknown;
}

export interface RegistryInfoResponse {
  item: SkillListItem;
  raw?: unknown;
}

export interface SkillMappingRecord {
  target: TargetEnvironment;
  path: string;
  mode: "symlink" | "junction" | "copy";
  updatedAt: string;
}

export interface ManifestSummary {
  files: number;
  bytes: number;
  hasSymlinks: boolean;
}

export type SkillSource = "slug" | "repository" | "local";

export interface LockedSkill {
  id: string;
  name: string;
  source: SkillSource;
  installedAt: string;
  storePath: string;
  manifest: ManifestSummary;
  mappings: SkillMappingRecord[];
}

export interface LockFile {
  schemaVersion: string;
  root: string;
  fireSkillVersion: string;
  openskillsVersion: string;
  updatedAt: string;
  skills: Record<string, LockedSkill>;
}

export interface RootDetection {
  root: string;
  reason: string;
}

export interface InstallResult {
  root: string;
  skills: string[];
  target?: TargetEnvironment;
}
