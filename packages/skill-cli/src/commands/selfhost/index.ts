import type { Command } from "commander";
import {
  findConfigFile,
  listProfiles,
  readFileConfig,
  type RuntimeShare,
  resolveShare,
  type ShareOverrides,
} from "./config/index.ts";
import { runMount, runOpen, runPath, runStatus, runUmount } from "./smb/mount.ts";

type SelfhostFlags = {
  config?: string;
  profile?: string;
};

type Guard = (action: () => Promise<void> | void) => void;

function overridesFrom(flags: SelfhostFlags): ShareOverrides {
  return { configPath: flags.config, profile: flags.profile };
}

function runProfiles(flags: SelfhostFlags): void {
  const configPath = findConfigFile(process.cwd(), flags.config);
  if (!configPath) {
    throw new Error("config.json not found");
  }
  const file = readFileConfig(configPath);
  const names = listProfiles(file);
  const current = flags.profile || file.default || names[0] || "";
  console.log(`==> ${configPath}`);
  for (const name of names) {
    const mark = name === current ? "*" : " ";
    const p = file.profiles?.[name];
    console.log(`${mark} ${name}  ${p?.user ?? ""}@${p?.host ?? ""}/${p?.share ?? ""}`);
  }
}

export function registerSelfhostCommands(program: Command, guard: Guard): Command {
  const selfhost = program
    .command("selfhost")
    .description("Mount or open a self-hosted SMB share (macOS)");

  const withShare = (name: string, description: string, run: (share: RuntimeShare) => number) =>
    selfhost
      .command(name)
      .description(description)
      .option("--config <path>", "config.json path (default: nearest config.json up the tree)")
      .option("--profile <name>", 'Profile name (default: config.json "default")')
      .action((flags: SelfhostFlags) =>
        guard(() => {
          const code = run(resolveShare(process.cwd(), overridesFrom(flags)));
          if (code !== 0) process.exit(code);
        }),
      );

  withShare("mount", "Mount with mount_smbfs, or open Finder when via=open", runMount);
  withShare("open", "Open smb://... in Finder (Keychain / Finder prompt)", runOpen);
  withShare("umount", "Unmount the share", runUmount).alias("unmount");
  withShare("status", "Show whether the mount point is active", runStatus);
  withShare("path", "Print the local path to use with cp / mv", runPath);

  selfhost
    .command("profiles")
    .description("List profiles in config.json")
    .option("--config <path>", "config.json path (default: nearest config.json up the tree)")
    .option("--profile <name>", 'Profile name (default: config.json "default")')
    .action((flags: SelfhostFlags) =>
      guard(() => {
        runProfiles(flags);
      }),
    );

  return selfhost;
}
