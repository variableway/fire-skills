# Install Skills Guide

Use this guide to install, add, remove, and update skills based on the current project scripts and CLI behavior.

## Prerequisites

Build the CLI once before using scripts:

```bash
bun run build
```

If you want a compiled binary:

```bash
bun run build:exe
```

## Quick Start

```bash
# Install (add) skills globally
./scripts/install.sh skills/devops --system

# Install (add) skills to current project for a specific agent
./scripts/install.sh skills/devops --project --agent codex

# List installed skills
skill-spark list

# Remove one installed skill
./scripts/remove.sh git-workflow

# Update installed skills
./scripts/update.sh
```

## Install / Add Skills

The install wrapper calls:

```bash
skill-spark add <source> [options]
```

Wrapper usage:

```bash
./scripts/install.sh <source> [options]
```

### Supported sources

- Local directory: `skills/devops`, `./my-skill-collection`
- GitHub shorthand: `user/repo`
- GitHub URL: `github.com/user/repo`
- GitLab URL: `gitlab.com/user/repo`
- Well-known source: `well-known:example.com`

### Common options

- `--system`: install globally (mapped to `--global`)
- `--project`: install in current project (default behavior)
- `--agent <name>`: target one or more agents
- `--skill <name>`: install only specific skill(s) from source
- `--yes`: auto-confirm prompts
- `--force`: skip confirmations
- `--no-symlink`: copy files instead of symlinks
- `--silent`: suppress non-error output

### Examples

```bash
# Install all installables from local source globally
./scripts/install.sh skills/devops --system

# Install only selected skill from a source
./scripts/install.sh skills/devops --skill git-workflow --project

# Install for a specific agent
./scripts/install.sh skills/devops --project --agent codex

# Install from GitHub
./scripts/install.sh github.com/anthropic/claude-code-skills --system
```

## Remove Installed Skills

The remove wrapper calls:

```bash
skill-spark remove [skills...] [options]
```

Wrapper usage:

```bash
./scripts/remove.sh <skill-name> [options]
```

### Examples

```bash
# Remove one skill
./scripts/remove.sh git-workflow

# Remove multiple skills
./scripts/remove.sh git-workflow local-workflow

# Auto-confirm removal
./scripts/remove.sh git-workflow --yes
```

## Update Installed Skills

The update wrapper calls:

```bash
skill-spark update [skills...] [options]
```

Wrapper usage:

```bash
./scripts/update.sh [skill-names...] [options]
```

### Examples

```bash
# Update all tracked skills
./scripts/update.sh

# Update specific skills
./scripts/update.sh git-workflow local-workflow
```

## Useful Direct CLI Commands

```bash
# List installed skills
skill-spark list

# Show update status
skill-spark outdated

# Diagnose environment
skill-spark doctor

# Show options for adding skills
skill-spark add --help
```

## Installation Modes

### Symlink mode (default)

Skills are stored in canonical location and symlinked into agent folders.

```text
~/.skill-spark/.agents/skills/<name>/  ← canonical storage
        ↓
.claude/skills/<name>  → symlink
.cursor/skills/<name>  → symlink
```

### Copy mode (`--no-symlink`)

Skills are copied directly to target agent folders.

```text
.claude/skills/<name>/  ← direct copy
.cursor/skills/<name>/  ← direct copy
```

## Troubleshooting

### `skill-spark` not found

Build first:

```bash
bun run build
```

Or install binary:

```bash
bun run build:exe
```

Then retry your script command.
