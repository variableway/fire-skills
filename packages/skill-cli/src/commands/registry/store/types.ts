export type Project = {
  name: string;
  repo: string;
  path: string;
  desc?: string;
  [key: string]: unknown;
};

export const BASE_FIELDS = ["name", "repo", "path", "desc"] as const;
