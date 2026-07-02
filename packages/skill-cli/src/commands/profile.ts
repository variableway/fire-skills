import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { type SkillProfile, SkillProfileSchema } from "@skill-spark/skill-core/schemas";
import pc from "picocolors";
import { handleAddCommand } from "./add";

const profileRoot = ".skill-workspace/profiles";

export interface ProfileAddOptions {
  description?: string;
  source?: string;
  skill: string[];
  agent?: string[];
  force?: boolean;
}

export interface ProfileInstallOptions {
  agent?: string[];
  global?: boolean;
  yes?: boolean;
  force?: boolean;
  symlink?: boolean;
}

function ensureProfileRoot() {
  mkdirSync(profileRoot, { recursive: true });
}

function profilePath(name: string) {
  return join(profileRoot, `${name}.json`);
}

function readProfile(name: string): SkillProfile {
  const path = profilePath(name);
  if (!existsSync(path)) {
    throw new Error(`Profile not found: ${name}`);
  }

  return SkillProfileSchema.parse(JSON.parse(readFileSync(path, "utf-8")));
}

export function runProfileAdd(name: string, options: ProfileAddOptions) {
  ensureProfileRoot();

  if (!options.skill || options.skill.length === 0) {
    throw new Error("profile add requires at least one --skill.");
  }

  const profile = SkillProfileSchema.parse({
    name,
    description: options.description,
    skills: options.skill.map((skillName) => ({
      name: skillName,
      source: options.source ?? "skills",
    })),
    targetAgents: options.agent ?? [],
  });

  const path = profilePath(profile.name);
  if (existsSync(path) && !options.force) {
    throw new Error(`Profile already exists: ${profile.name}. Use --force to overwrite.`);
  }

  writeFileSync(path, `${JSON.stringify(profile, null, 2)}\n`, "utf-8");
  console.log(`${pc.green("saved")} ${path}`);
}

export function runProfileList() {
  ensureProfileRoot();
  const files = readdirSync(profileRoot).filter((file) => file.endsWith(".json"));

  if (files.length === 0) {
    console.log("No profiles found.");
    return;
  }

  for (const file of files) {
    const profile = SkillProfileSchema.parse(JSON.parse(readFileSync(join(profileRoot, file), "utf-8")));
    console.log(`${pc.cyan(profile.name)} ${pc.dim(`${profile.skills.length} skills`)}`);
    if (profile.description) {
      console.log(`  ${profile.description}`);
    }
  }
}

export function runProfileShow(name: string) {
  const profile = readProfile(name);
  console.log(JSON.stringify(profile, null, 2));
}

export async function runProfileInstall(name: string, options: ProfileInstallOptions) {
  const profile = readProfile(name);
  const agents = options.agent && options.agent.length > 0 ? options.agent : profile.targetAgents;

  for (const skill of profile.skills) {
    await handleAddCommand(skill.source, {
      agent: agents.length > 0 ? agents : undefined,
      global: options.global,
      skill: [skill.name],
      yes: options.yes ?? true,
      force: options.force,
      symlink: options.symlink,
      silent: false,
    });
  }
}
