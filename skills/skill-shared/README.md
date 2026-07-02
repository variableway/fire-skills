# Skills

AI Agent Skills used for development workflows in this monorepo.

## Layout

| Path | Purpose |
|------|---------|
| `skills/_shared/` | Cross-app skills (git, release, testing, scaffolding, **find-skills**) |
| `skills/apps/<app-name>/` | App-specific skills |

Each skill is a directory containing a `SKILL.md` file (Cursor Agent Skill format).

## Search skills

### Unified (local + external hubs)

```bash
pnpm find-skills <query>
pnpm find-skills <query> --source skillsllm   # SkillsLLM API only
pnpm find-skills <query> --json
```

Sources are configured in `data/sources.yaml`:

| id | type | hub |
|----|------|-----|
| `local` | manifest | this repo `skills/` |
| `skillsllm` | api | [skillsllm.com](https://skillsllm.com) |
| `skills-sh` | cli | [skills.sh](https://www.skills.sh) |
| `flins` | cli | [flins.tech](https://flins.tech) |

**Add a hub:** edit `data/sources.yaml` (`type: api` with `api.search` URL, or `type: cli` with `cli.search` command).

### Local only

```bash
pnpm manifest
grep -r "keyword" skills/
```

## Add a skill to this repo

1. Create `skills/_shared/<skill-name>/SKILL.md` or `skills/apps/<app>/<skill-name>/SKILL.md`
2. Run `pnpm manifest`

Agent workflow: `skills/_shared/find-skills/SKILL.md`.
