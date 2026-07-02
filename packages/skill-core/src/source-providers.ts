import { existsSync } from "node:fs";
import { resolve } from "node:path";
import {
  cleanupSource,
  downloadSource,
  isDirectoryName,
  isWellKnownSource,
  resolveDirectorySource,
  type SourceBundle,
} from "./sources";

export type SourceProviderKind = "local" | "well-known" | "directory" | "git";

export interface ResolveSourceOptions {
  branch?: string;
}

export interface ResolvedSourceBundle {
  provider: SourceProviderKind;
  input: string;
  source: string;
  bundle: SourceBundle;
  cleanup(): Promise<void>;
}

export interface SourceProvider {
  kind: SourceProviderKind;
  label: string;
  canResolve(input: string): boolean | Promise<boolean>;
  resolve(input: string, options?: ResolveSourceOptions): Promise<ResolvedSourceBundle>;
}

function toResolved(
  provider: SourceProviderKind,
  input: string,
  source: string,
  bundle: SourceBundle,
): ResolvedSourceBundle {
  return {
    provider,
    input,
    source,
    bundle,
    cleanup: () => cleanupSource(bundle),
  };
}

export const localSourceProvider: SourceProvider = {
  kind: "local",
  label: "Local filesystem",
  canResolve(input: string) {
    return existsSync(resolve(input));
  },
  async resolve(input: string) {
    return toResolved("local", input, input, await downloadSource(input));
  },
};

export const wellKnownSourceProvider: SourceProvider = {
  kind: "well-known",
  label: "Well-known agent skills discovery",
  canResolve(input: string) {
    return isWellKnownSource(input);
  },
  async resolve(input: string) {
    return toResolved("well-known", input, input, await downloadSource(input));
  },
};

export const directorySourceProvider: SourceProvider = {
  kind: "directory",
  label: "Flins directory",
  canResolve(input: string) {
    return isDirectoryName(input);
  },
  async resolve(input: string, options?: ResolveSourceOptions) {
    const source = await resolveDirectorySource(input);
    if (!source) {
      throw new Error(`Skill ${input} was not found in the flins directory.`);
    }

    return toResolved("directory", input, source, await downloadSource(source, options?.branch));
  },
};

export const gitSourceProvider: SourceProvider = {
  kind: "git",
  label: "Git repository",
  canResolve() {
    return true;
  },
  async resolve(input: string, options?: ResolveSourceOptions) {
    return toResolved("git", input, input, await downloadSource(input, options?.branch));
  },
};

export const sourceProviders: SourceProvider[] = [
  localSourceProvider,
  wellKnownSourceProvider,
  directorySourceProvider,
  gitSourceProvider,
];

export async function resolveSourceBundle(input: string, options?: ResolveSourceOptions) {
  for (const provider of sourceProviders) {
    if (await provider.canResolve(input)) {
      return provider.resolve(input, options);
    }
  }

  return gitSourceProvider.resolve(input, options);
}
