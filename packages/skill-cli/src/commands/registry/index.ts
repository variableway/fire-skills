import type { Command } from "commander";
import { type LayoutOverrides, resolveLayout } from "./config/index.ts";
import { runClone } from "./git/index.ts";
import { DEFAULT_SCAN_DEPTH, runScan } from "./scan/index.ts";

const CLI = "skill-spark registry";

type Guard = (action: () => Promise<void> | void) => void;

type RegistryFlags = {
  config?: string;
  hubRoot?: string;
  worksRoot?: string;
  worksName?: string;
  appsRoot?: string;
  appsPrefix?: string;
  registry?: string;
};

type ScanFlags = RegistryFlags & {
  depth?: number;
  keepMissing?: boolean;
  regenerate?: boolean;
};

function layoutFrom(flags: RegistryFlags) {
  const overrides: LayoutOverrides = {
    configPath: flags.config,
    hubRoot: flags.hubRoot,
    worksRoot: flags.worksRoot,
    worksName: flags.worksName,
    appsRoot: flags.appsRoot,
    appsPrefix: flags.appsPrefix,
    registry: flags.registry,
  };
  return resolveLayout(process.cwd(), overrides);
}

function resolveDepth(flags: ScanFlags): number {
  const depth = flags.depth ?? DEFAULT_SCAN_DEPTH;
  if (!Number.isInteger(depth) || depth < 0) {
    throw new Error("--depth must be a non-negative integer");
  }
  return depth;
}

function addLayoutOptions(command: Command): Command {
  return command
    .option("--config <path>", "Config file. Env: REGISTRY_CLI_CONFIG")
    .option("--hub-root <path>", "Hub repo. Env: REGISTRY_CLI_HUB_ROOT")
    .option("--works-root <path>", "Works / clone root. Env: REGISTRY_CLI_WORKS_ROOT")
    .option("--works-name <name>", "Directory basename to search upward. Env: REGISTRY_CLI_WORKS_NAME")
    .option("--apps-root <path>", "Optional relocated apps tree. Env: REGISTRY_CLI_APPS_ROOT")
    .option("--apps-prefix <name>", "Registry path prefix mapped onto --apps-root")
    .option("--registry <path>", "Override the registry file");
}

function addScanOptions(command: Command): Command {
  return addLayoutOptions(command)
    .option(
      "--depth <n>",
      `Recursion depth (1 = direct children, 0 = unlimited). Default: ${DEFAULT_SCAN_DEPTH}`,
      (value) => Number.parseInt(value, 10),
    )
    .option("--keep-missing", "Keep registry rows whose directories disappeared")
    .option("--regenerate", "Rebuild registry from disk; drop extra fields");
}

export function registerRegistryCommands(program: Command, guard: Guard): Command {
  const registry = program
    .command("registry")
    .description("Scan and clone the git repos listed in a registry YAML");

  addScanOptions(registry.command("scan [dirs...]"))
    .description("Scan configured dirs into the hub registry")
    .action((dirs: string[], flags: ScanFlags) =>
      guard(async () => {
        const layout = layoutFrom(flags);
        const targets = dirs.length ? dirs : layout.scanDirs;
        if (!targets.length) {
          throw new Error("no scan dirs: pass them as arguments or set scanDirs in config");
        }
        await runScan({
          layout,
          registry: layout.registry,
          dirs: targets,
          depth: resolveDepth(flags),
          keepMissing: Boolean(flags.keepMissing),
          regenerate: Boolean(flags.regenerate),
          syncedBy: `${CLI} scan`,
          consumedBy: `${CLI} clone`,
        });
      }),
    );

  addScanOptions(registry.command("scan-refs [dirs...]"))
    .description("Scan configured refs dirs into the works registry")
    .action((dirs: string[], flags: ScanFlags) =>
      guard(async () => {
        const layout = layoutFrom(flags);
        const targets = dirs.length ? dirs : layout.refsScanDirs;
        if (!targets.length) {
          throw new Error("no refs scan dirs: pass them as arguments or set refsScanDirs in config");
        }
        const registry = flags.registry ?? layout.refsRegistry;
        if (!registry) {
          throw new Error("no works registry: set refsRegistry in config or pass --registry");
        }
        await runScan({
          layout,
          registry,
          dirs: targets,
          depth: resolveDepth(flags),
          keepMissing: Boolean(flags.keepMissing),
          regenerate: Boolean(flags.regenerate),
          syncedBy: `${CLI} scan-refs`,
          consumedBy: `${CLI} clone-refs`,
        });
      }),
    );

  addLayoutOptions(registry.command("clone"))
    .description("Clone / pull hub registry entries")
    .action((flags: RegistryFlags) =>
      guard(async () => {
        const layout = layoutFrom(flags);
        const code = await runClone({ layout, registry: layout.registry });
        if (code !== 0) process.exit(code);
      }),
    );

  addLayoutOptions(registry.command("clone-refs"))
    .description("Clone / pull works registry entries")
    .action((flags: RegistryFlags) =>
      guard(async () => {
        const layout = layoutFrom(flags);
        const registry = flags.registry ?? layout.refsRegistry;
        if (!registry) {
          throw new Error("no works registry: set refsRegistry in config or pass --registry");
        }
        const code = await runClone({ layout, registry });
        if (code !== 0) process.exit(code);
      }),
    );

  return registry;
}
