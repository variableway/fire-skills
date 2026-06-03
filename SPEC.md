# skill-spark Specification

## Overview

**skill-spark** is a universal skill manager for AI coding agents, merging the best features of Fire-Skill and Flins. It provides a unified CLI for discovering, installing, and managing skills across 42+ AI coding agents.

## Project Goals

1. **Multi-registry support** — Query skills from multiple marketplaces via Fire-Skill's registry client
2. **TUI interactive experience** — Flins-style interactive browsing and installation with @clack/prompts
3. **Complete lifecycle management** — add, list, update, remove, outdated for skills and commands
4. **42+ Agent support** — Unified configuration for all major AI coding agents
5. **Flexible installation** — symlink (default) or copy mode for skill installation
6. **State tracking** — skills.lock for project and global scope
7. **Cross-agent mapping** — Map skills between different agent directories

## Architecture

### Directory Structure

```
skill-spark/
├── src/
│   ├── index.ts              # CLI entry point (Commander)
│   ├── commands/
│   │   ├── add.ts           # Install skills (Flins logic)
│   │   ├── list.ts          # List installed
│   │   ├── remove.ts        # Remove skills
│   │   ├── update.ts        # Update + outdated status
│   │   ├── search.ts        # Search + TUI browse
│   │   ├── map.ts           # Map to target agent
│   │   └── doctor.ts        # Environment diagnosis
│   ├── core/
│   │   ├── agents.ts        # 42 Agent configurations
│   │   ├── sources.ts       # Git + Well-Known sources
│   │   ├── discovery.ts     # SKILL.md parsing
│   │   ├── installations.ts # Installation engine
│   │   ├── state.ts         # skills.lock management
│   │   ├── tracked.ts       # State scanning
│   │   ├── registry.ts      # Multi-registry HTTP client
│   │   ├── mapping.ts       # symlink mapping engine
│   │   ├── output.ts        # TUI output utilities
│   │   └── types.ts        # Shared TypeScript types
│   └── utils/
│       ├── json.ts          # JSON output
│       └── root.ts          # Workspace detection
├── package.json
└── README.md
```

## Functionality Specification

### 1. Commands

#### search [query]
- **Purpose**: Search skills from registry or browse interactively
- **Sources**:
  - No query: TUI autocompleteMultiselect from flins directory
  - With query: REST search against configured registry
- **Registry override**: `--registry <url>` flag or `FIRE_SKILL_REGISTRY_URL` env
- **Output**: JSON to stdout for agent consumption, TUI for interactive

#### add <source>
- **Purpose**: Install skills from various sources
- **Source types**:
  - flins directory name: `skill-spark add better-auth`
  - Git URL: `skill-spark add github.com/user/skills`
  - Well-known: `skill-spark add well-known:developer.cloudflare.com`
- **Options**:
  - `--global`: User-level installation
  - `--agent <agents>`: Target specific agents
  - `--skill <names>`: Install specific skills only
  - `--list`: Show available without installing
  - `--no-symlink`: Use copy instead of symlink
- **Flow**:
  1. Resolve source input
  2. Download/discover installables
  3. Interactive selection (if not auto-confirmed)
  4. Target agent selection
  5. Install per (skill × agent)
  6. Track in skills.lock

#### list
- **Purpose**: Display installed skills from skills.lock
- **Output**: TUI grouped by local vs global scope
- **Shows**: skill:NAME or command:NAME with valid installations

#### outdated [skills...]
- **Purpose**: Check for updates and missing files
- **Flow**:
  1. Read skills.lock
  2. Scan filesystem for installations
  3. Check git remote for newer commits
  4. Report status: latest, update-available, orphaned, error

#### update [skills...]
- **Purpose**: Update installed skills to latest versions
- **Flow**:
  1. Find outdated items
  2. Confirm if not auto-confirmed
  3. Re-install each outdated item

#### remove [skills...]
- **Purpose**: Remove installed skills
- **Input**: `skill:NAME` or `command:NAME` format
- **Flow**:
  1. Confirm if not auto-confirmed
  2. Remove filesystem entries
  3. Remove from skills.lock

#### map --target <agent>
- **Purpose**: Map installed skills to target agent directory
- **Targets**: codex, gemini, claude, agent, qwen
- **Options**:
  - `--global`: Map from global install
  - `--universal`: Map from .agent/skills
  - `--force-map`: Overwrite existing
- **Flow**:
  1. Detect workspace root
  2. List skills in source directory
  3. Create symlinks/copies to target directory

#### doctor
- **Purpose**: Diagnose environment
- **Checks**:
  - Workspace root detection
  - Skill directories existence
  - skills.lock existence
  - Detected agents

### 2. Core Modules

#### agents.ts
- 42 AI coding agent configurations
- Each agent has:
  - `label`: Display name
  - `skillsDir`: Project-level skills directory
  - `globalSkillsDir`: Global skills directory
  - `commandsDir`: Commands directory (optional)
  - `detectInstalled()`: Detection predicate
- Helpers:
  - `getAgentNames()`: List all agent names
  - `getCommandAgents()`: Agents with commands support
  - `getUniversalAgents()`: Agents sharing `.agents/skills`
  - `detectInstalledAgents()`: Currently installed agents

#### sources.ts
- Git URL parsing (github, gitlab, shorthand)
- Well-Known schema support
- Archive extraction (tar.gz, zip)
- Source download with digest verification
- Directory listing from flins.tech

#### discovery.ts
- Walk directory tree (depth ≤ 5)
- Parse SKILL.md frontmatter for skills
- Parse `commands/*.md` for commands
- Deduplicate by name

#### installations.ts
- symlink mode: Copy to storage root, symlink to agent dirs
- copy mode: Copy directly to agent dirs
- Installation validation (SKILL.md presence)
- Removal with symlink resolution

#### state.ts
- skills.lock read/write
- Project scope: `./skills.lock`
- Global scope: `~/.skill-spark/skills.lock`
- Tracked items: name, type, scope, url, subpath, branch, commit

#### tracked.ts
- Scan installed items
- Validate installations on filesystem
- Check for updates via `git ls-remote`
- Status: latest, update-available, orphaned, error

#### registry.ts
- HTTP client for skill registries
- Multiple payload shape normalization
- Field fallbacks (stars, author, etc.)
- Environment variable override

#### mapping.ts
- Target directory mapping per agent type
- symlink with Windows junction support
- Copy fallback on permission errors
- Idempotent mapping (skip if already mapped)

### 3. Installation Modes

#### symlink (default)
```
~/.skill-spark/.agents/skills/<name>/  ← canonical storage
        ↓
.claude/skills/<name>  → symlink to canonical
.cursor/skills/<name>  → symlink to canonical
```

#### copy (--no-symlink)
```
.claude/skills/<name>/  ← direct copy
.cursor/skills/<name>/  ← direct copy
```

### 4. Supported Sources

| Source | Example |
|--------|----------|
| flins directory | `skill-spark add better-auth` |
| GitHub shorthand | `skill-spark add user/repo` |
| GitHub URL | `skill-spark add github.com/user/repo` |
| GitLab URL | `skill-spark add gitlab.com/user/repo` |
| Well-Known | `skill-spark add well-known:example.com` |

### 5. Data Structures

#### skills.lock
```json
{
  "version": "1",
  "skills": {
    "skill:better-auth": {
      "name": "better-auth",
      "type": "skill",
      "scope": "project",
      "url": "github.com/user/better-auth",
      "branch": "main",
      "commit": "abc123"
    }
  }
}
```

#### Installable
```typescript
interface Installable {
  type: "skill" | "command";
  name: string;
  description: string;
  path: string;
}
```

## Acceptance Criteria

### Core Commands
- [x] `search` — TUI browse when no query, REST search with query
- [x] `add` — Install from flins directory, git URL, well-known
- [x] `list` — Display skills from skills.lock grouped by scope
- [x] `outdated` — Check for updates and missing files
- [x] `update` — Update outdated skills
- [x] `remove` — Remove skills with confirmation
- [x] `map` — Map skills to target agent directory
- [x] `doctor` — Display environment diagnosis

### Installation
- [x] symlink mode (default) works correctly
- [x] copy mode (--no-symlink) works correctly
- [x] skills.lock tracks project-scoped installs
- [x] skills.lock tracks global-scoped installs

### Agents
- [x] 42 agents configured in agents.ts
- [x] Universal agents share `.agents/skills`
- [x] Agent detection works for installed agents
- [x] Command directories supported for 3 agents

### Registry
- [x] Default registry URL configurable
- [x] FIRE_SKILL_REGISTRY_URL environment variable
- [x] --registry CLI flag override
- [x] Multiple payload shape normalization

### TUI
- [x] @clack/prompts for interactive selection
- [x] picocolors for colored output
- [x] Spinner for loading states
- [x] Cancel handling with p.isCancel()

## Dependencies

```json
{
  "@clack/prompts": "^1.0.0-alpha.9",
  "commander": "^15.0.0",
  "picocolors": "^1.1.1",
  "tar-stream": "^3.1.8",
  "yauzl": "^3.3.0"
}
```

## Runtime

- **Required**: Bun (ESM module resolution)
- **Node compatibility**: Node 20+ with ESM