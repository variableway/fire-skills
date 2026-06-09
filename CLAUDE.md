# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**skill-spark** is a universal skill manager for AI coding agents, merging the best features of Fire-Skill and Flins. It provides a unified CLI for discovering, installing, and managing skills across 42+ AI coding agents.

## Build & Run Commands

```bash
bun install          # Install dependencies
bun run dev          # Run in development mode
bun run build        # Build for production
bun run build:exe    # Build standalone executable
bun run build:all    # Build all targets
bun run typecheck    # Type check with tsgo
```

## Scripts (scripts/)

统一的跨平台安装/删除/更新脚本，支持 macOS、Linux、Windows、WSL2：

```bash
# 一键安装 (使用 skill-spark CLI)
./scripts/install-devops.sh --system                        # devops → 全局
./scripts/install-base.sh --system                          # base → 全局
./scripts/install-devops.sh --project --agent codex         # devops → 项目/Codex

# 通用安装/删除/更新
./scripts/install.sh skills/devops --system
./scripts/remove.sh git-workflow --system
./scripts/update.sh skills/devops --system --force
```


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
│   │   ├── agent.ts         # Agent management
│   │   └── doctor.ts        # Environment diagnosis
│   ├── core/
│   │   ├── agents.ts        # 42+ Agent configurations
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
├── skills/                  # Skill definitions
│   ├── base/               # Base skills
│   ├── devops/             # DevOps skills
│   └── meta/               # Meta skills
├── docs/                   # Documentation
├── yorun-workflow/         # Yorun workflow integration
└── package.json
```

### Key Commands

| Command | Description |
|---------|-------------|
| `skill-spark search [query]` | Search skills from registry or browse interactively |
| `skill-spark add <source>` | Install skills from Git URLs, well-known endpoints, or flins directory |
| `skill-spark list` | List installed skills and commands |
| `skill-spark outdated [skills...]` | Check for updates and missing files |
| `skill-spark update [skills...]` | Update installed skills to latest versions |
| `skill-spark remove [skills...]` | Remove installed skills |
| `skill-spark map --target <agent>` | Map skills to target agent directory |
| `skill-spark agent list` | List built-in and custom agent directory configurations |
| `skill-spark doctor` | Diagnose skill-spark environment |

### Installation Modes

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

### Supported Sources

| Source | Example |
|--------|----------|
| flins directory | `skill-spark add better-auth` |
| GitHub shorthand | `skill-spark add user/repo` |
| GitHub URL | `skill-spark add github.com/user/repo` |
| GitLab URL | `skill-spark add gitlab.com/user/repo` |
| Well-Known | `skill-spark add well-known:example.com` |

## Task Execution Workflow

When the user asks to **execute a task**, **implement a task**, or **run a task** (e.g., "请执行Task 9", "execute Task 3"), you MUST use the `git-workflow` skill:

1. **INIT** — Create a GitHub Issue:
   ```bash
   python .claude/skills/git-workflow/scripts/orchestrate.py init --title "<task title>" --description "<task description>"
   ```

2. **IMPLEMENT** — Execute the task (code changes, tests, etc.)

3. **FINISH** — Append completion message and close the Issue:
   ```bash
   python .claude/skills/git-workflow/scripts/orchestrate.py finish --message "<completion summary>"
   ```

This applies to all tasks referenced from task files (e.g., `tasks/issues/dev-workflow.md`).

**Do NOT skip the workflow** — always create an Issue first, then close it after completion.

## Local Task Execution Workflow

When the user asks to **execute a task locally** or **use local-workflow** (no GitHub needed), follow:

1. **INIT** — Initialize local tracking:
   ```bash
   python .claude/skills/local-workflow/scripts/orchestrate.py init <task-file.md>
   ```

2. **IMPLEMENT** — Execute the task (code changes, tests, etc.)

3. **FINISH** — Mark task complete and commit:
   ```bash
   python .claude/skills/local-workflow/scripts/orchestrate.py finish
   ```

Tracking records are saved to `tasks/tracing/`. No GitHub Issues required.

## Configuration

### Environment Variables

- `FIRE_SKILL_REGISTRY_URL` — Override default registry URL
- `SKILL_SPARK_HOME` — Override skill-spark home directory (default: `~/.skill-spark`)

### skills.lock

Project-level and global-level skill tracking:

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

## Development Conventions

- **Runtime**: Bun (ESM module resolution)
- **TypeScript**: Strict mode with tsgo
- **Testing**: Bun test runner
- **UI**: @clack/prompts for interactive TUI, picocolors for colored output
- **Language**: Documentation primarily in Chinese

