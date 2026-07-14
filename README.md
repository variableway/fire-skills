# fire-skills / skill-spark

Personal Skill Workspace + universal Skill manager for AI coding agents.

**Use this repo to:**

1. Keep curated personal / team skills (by category)
2. Test and iterate on skills
3. Install and sync skills across agents via **skill-spark** CLI

## Quick start

```bash
pnpm install
bun run build          # or: bun run build:install
skill-spark --help
skill-spark add skills/devops --agent codex
```

## Docs

| Doc | What |
|-----|------|
| [docs/README.md](docs/README.md) | Documentation index |
| [docs/skill-spark/overview.md](docs/skill-spark/overview.md) | Architecture & modules |
| [docs/skill-spark/install-and-run.md](docs/skill-spark/install-and-run.md) | Build, install, run CLI |
| [docs/usage/install-devops-skills.md](docs/usage/install-devops-skills.md) | DevOps skills install guide |
| [docs/install-skills.md](docs/install-skills.md) | Generic add / remove / update |
| [docs/projects/architecture-and-mvp.md](docs/projects/architecture-and-mvp.md) | Doc layout, status, MVP plan |

## Skill categories

| Category | Path |
|----------|------|
| Core | `skills/base` |
| DevOps | `skills/devops` |
| Meta | `skills/meta` |
| SDLC | `skills/sdlc` |
| Knowledge | `skills/knowledge` |
| Shared | `skills/skill-shared` |

See `skills/categories.json` and `skills/index.json` for the registry snapshot.
