# Scripts Usage Guide

Wrapper scripts for the `skill-spark` CLI, providing a simpler shell interface for common operations.

## Quick Start

```bash
# Install a skill globally
./scripts/install.sh skills/devops --system

# Install a skill to project for specific agent
./scripts/install.sh skills/devops --project --agent codex

# List installed skills
skill-spark list

# Update all skills
./scripts/update.sh

# Remove a skill
./scripts/remove.sh git-workflow
```

## Scripts

### install.sh

Install skills from various sources.

```bash
./scripts/install.sh <source> [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--system` | Install globally (into `~/.skill-spark/`) |
| `--project` | Install to project directory (default) |
| `--agent <name>` | Target specific agent (e.g., `codex`, `claude`, `kimi`) |
| `--skill <name>` | Install specific skill by name |
| `--yes` | Auto-confirm prompts |
| `--force` | Skip confirmations |
| `--no-symlink` | Copy files instead of symlinks |
| `--silent` | Suppress banner output |

**Source Types:**

| Type | Example |
|------|---------|
| Local directory | `skills/devops`, `./my-skill` |
| GitHub shorthand | `user/repo` |
| GitHub URL | `github.com/user/repo` |
| GitLab URL | `gitlab.com/user/repo` |
| Well-Known | `well-known:example.com` |

**Examples:**

```bash
# Install devops skills globally
./scripts/install.sh skills/devops --system

# Install for specific agent
./scripts/install.sh skills/devops --project --agent codex

# Install from GitHub
./scripts/install.sh github.com/anthropic/claude-code-skills --system

# Install specific skill only
./scripts/install.sh skills/devops --skill git-workflow --system
```

### remove.sh

Remove installed skills.

```bash
./scripts/remove.sh <skill-name> [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--yes` | Auto-confirm prompts |
| `--force` | Skip confirmations |
| `--silent` | Suppress banner output |

**Examples:**

```bash
# Remove a single skill
./scripts/remove.sh git-workflow

# Remove with type prefix
./scripts/remove.sh skill:git-workflow

# Remove multiple skills
./scripts/remove.sh git-workflow local-workflow

# Auto-confirm removal
./scripts/remove.sh git-workflow --yes
```

### update.sh

Update installed skills to latest versions.

```bash
./scripts/update.sh [skill-names...] [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--yes` | Auto-confirm prompts |
| `--force` | Skip confirmations |
| `--silent` | Suppress banner output |

**Examples:**

```bash
# Update all tracked skills
./scripts/update.sh

# Update specific skill
./scripts/update.sh git-workflow

# Update multiple skills
./scripts/update.sh git-workflow local-workflow

# Auto-confirm updates
./scripts/update.sh --yes
```

## CLI Equivalents

These scripts wrap the `skill-spark` CLI. You can also use the CLI directly:

| Script | CLI Command |
|--------|-------------|
| `./scripts/install.sh skills/devops --system` | `skill-spark add skills/devops --global` |
| `./scripts/remove.sh git-workflow` | `skill-spark remove git-workflow` |
| `./scripts/update.sh` | `skill-spark update` |

## Installation Modes

### Symlink (default)

Skills are stored in canonical location and symlinked to agent directories:

```
~/.skill-spark/.agents/skills/<name>/  ← canonical storage
        ↓
.claude/skills/<name>  → symlink
.cursor/skills/<name>  → symlink
```

### Copy (--no-symlink)

Files are copied directly to agent directories:

```
.claude/skills/<name>/  ← direct copy
.cursor/skills/<name>/  ← direct copy
```

## Troubleshooting

### "skill-spark not found"

Build the CLI first:

```bash
bun run build
```

Or install globally:

```bash
bun run build:exe
```

### Check installation status

```bash
# List installed skills
skill-spark list

# Check for updates
skill-spark outdated

# Diagnose environment
skill-spark doctor
```
