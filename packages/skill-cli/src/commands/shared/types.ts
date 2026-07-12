// 通用选项
export interface YesForceOptions {
  yes?: boolean;
  force?: boolean;
}

export interface SilentOptions {
  silent?: boolean;
}

export interface FormatOutputOptions {
  format?: string;
  output?: string;
}

export interface BranchSkillOptions {
  branch?: string;
  skill?: string[];
}

export interface CommonOptions extends YesForceOptions, SilentOptions {}

// 命令描述接口
export interface CommandMeta {
  name: string;
  description: string;
  examples: string[];
  prerequisites: string[];
}
