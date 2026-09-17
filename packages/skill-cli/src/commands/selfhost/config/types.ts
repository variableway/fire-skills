export type Via = "open" | "smbfs";

export type ProfileConfig = {
  host?: string;
  share?: string;
  user?: string;
  mountPoint?: string;
  via?: Via;
};

export type FileConfig = {
  default?: string;
  profiles?: Record<string, ProfileConfig>;
};

export type ShareOverrides = {
  configPath?: string;
  profile?: string;
};

export type RuntimeShare = {
  name: string;
  host: string;
  share: string;
  user: string;
  password: string;
  mountPoint: string;
  via: Via;
};
