---
name: find-skills
description: Discover and install agent skills from local manifest, skills.sh, flins.tech, SkillsLLM, and other sources in data/sources.yaml.
---

# Find Skills

Help discover skills from the **open ecosystem** (not only this repo's `skills/` tree).

## Unified search (agentway)

Configured sources live in `data/sources.yaml`. Run:

```bash
pnpm find-skills <query>                  # all enabled sources
pnpm find-skills <query> --source skillsllm
pnpm find-skills <query> --json           # machine-readable
```

| type | source | how search works |
|------|--------|------------------|
| `local` | agentway | `data/manifest.json` |
| `api` | [SkillsLLM](https://skillsllm.com) | `GET /api/skills?q=` — stars + security scan |
| `cli` | [skills.sh](https://www.skills.sh) | `npx skills find` |
| `cli` | [flins.tech](https://flins.tech) | `flins search` |

**Add a new hub:** append an entry to `data/sources.yaml` (`type: api` or `type: cli`), set `enabled: true`.

## Marketplaces (detail)

| | [skills.sh](https://www.skills.sh) | [flins.tech](https://flins.tech) | [SkillsLLM](https://skillsllm.com) |
|---|-----|-----|-----|
| Search | `npx skills find` + site | `flins search` + curated | Site + **API** (`pnpm find-skills --source skillsllm`) |
| Install | `npx skills add <repo> --skill <name>` | `flins add <owner/repo>` | Clone `repoUrl` from API / skill page |
| Quality signals | Install count, audit badges | Curated / official | GitHub stars, Semgrep/npm/pip security PASS/FAIL |

## When to use this skill

- User asks "find a skill for X", "how do I do X with a skill", "is there a skill for…"
- User mentions skills.sh, flins, or installing third-party skills
- User wants capabilities beyond `skills/_shared/` in this repo

## Search workflow

1. **Unified** — `pnpm find-skills <query>` (reads `data/sources.yaml`).
2. **Local first** — included automatically; or `data/manifest.json`.
3. **Per-hub** — `--source skillsllm` | `skills-sh` | `flins` | `local`.
4. **Install** — see below; vendor into `skills/` if team-shared.

## Install workflow

### Via SkillsLLM

```bash
pnpm find-skills ui --source skillsllm
# → repoUrl, stars, securityStatus from API
git clone https://github.com/owner/repo   # or flins add / npx skills add
```

Browse [skillsllm.com](https://skillsllm.com); prefer high stars + `securityStatus: PASSED` on skill page.

### Via skills.sh (Vercel ecosystem)

```bash
# Example: install the find-skills meta-skill
npx skills add https://github.com/vercel-labs/skills --skill find-skills

# Search then add
npx skills find react
npx skills add <owner/repo> --skill <skill-name>
```

### Via flins

```bash
flins add expo/skills              # GitHub shorthand
flins add better-auth              # curated directory name
flins add https://github.com/org/repo --skill <name>
flins add developer.cloudflare.com --list   # RFC .well-known discovery
```

flins installs source under `.agents/skills/` and symlinks into `.cursor/skills/`, `.claude/skills/`, etc.

## Where skills should live in agentway

| Kind | Location | When |
|------|----------|------|
| Repo-owned, team-shared | `skills/_shared/<name>/` or `skills/apps/<app>/<name>/` | Workflow specific to this monorepo; commit to git |
| Third-party, machine-local | `.cursor/skills/` via `flins` or `npx skills` | Personal/global tooling; not committed |
| Third-party, pinned in repo | Copy `SKILL.md` into `skills/_shared/<name>/` or git submodule | Team must use exact same version |

After adding to `skills/`, run `pnpm manifest` to update `data/manifest.json`.

## Recommendation criteria (manual / Agent judgment)

These are **heuristics for you or the Agent when browsing** — neither `npx skills find` nor `flins search` auto-filters by install count or audit status today.

| Signal | skills.sh | flins | SkillsLLM |
|--------|-----------|-------|-----------|
| Volume | Install count on skill page | Curated list | GitHub **stars** |
| Security | Audit badges on skill page | Curated vetting | **securityStatus** PASS/WARNING/FAIL (daily scan) |

**How it actually works:** run CLI search → open top hits on the website → apply criteria above → then install. Low-install skills can still be fine for niche tasks.

## Using both marketplaces at once

**Yes — use both in parallel.** They are independent CLIs and catalogs; searching both improves coverage.

| Layer | Path | Role |
|-------|------|------|
| agentway repo | `skills/` | Team skills in git; Cursor reads via project rules / `@skills` |
| flins | `.agents/skills/` → symlinks to `.cursor/skills/`, etc. | Machine-local, multi-agent sync |
| skills CLI | Agent-specific dirs (often overlaps `.cursor/skills/`) | Machine-local installs from skills.sh |

**Coexistence tips:**

- Same skill from both CLIs → duplicate or version conflict; pick **one** package manager per skill (`flins list` / check `.cursor/skills/`).
- Repo `skills/` + external installs do not conflict — different purposes (pinned team vs personal).
- For team baseline: vendor into `skills/_shared/`; for experiments: `flins add` or `npx skills add` locally only.

## Recommendation checklist

- Match task domain (testing, deploy, UI, etc.)
- Official or reputable source (Vercel, Anthropic, Expo, Cloudflare, etc.)
- On skills.sh: when comparing options, prefer higher installs and better audit badges (see table above)
- On flins: prefer curated / official entries
- Read `SKILL.md` before install — avoid secrets or overly broad permissions

## Related

- Install find-skills from skills.sh: `npx skills add https://github.com/vercel-labs/skills --skill find-skills`
- agentway scaffold: `skills/_shared/scaffold-app/SKILL.md`
