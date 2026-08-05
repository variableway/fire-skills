import * as p from "@clack/prompts";
import { listDirectory, resolveDirectorySource } from "@skill-spark/skill-core/sources";
import pc from "picocolors";

/**
 * Resolves a source input to its canonical source value.
 * Handles directory name lookup (e.g. "my-skill" -> flins directory).
 * Non-directory-name inputs pass through unchanged.
 * Exits the process if the directory name is not found.
 */
export async function resolveSourceInput(sourceInput: string): Promise<string> {
  // Simple regex check: directory names are alphanumeric, no slashes, no colons
  if (!/^[a-z0-9-]+$/i.test(sourceInput) || sourceInput.includes("/") || sourceInput.includes(":")) {
    return sourceInput;
  }

  p.log.info(`Looking up ${pc.cyan(sourceInput)} in the flins directory...`);

  const source = await resolveDirectorySource(sourceInput);
  if (source) {
    return source;
  }

  p.log.error(`Skill ${pc.cyan(sourceInput)} was not found in the flins directory.`);
  const entries = await listDirectory();
  if (entries.length > 0) {
    p.log.info("Available skills:");
    for (const entry of entries) {
      p.log.message(`  ${pc.cyan(entry.name)} ${pc.dim(`- ${entry.description}`)}`);
    }
  }

  throw new Error(`Skill "${sourceInput}" not found in flins directory`);
}
