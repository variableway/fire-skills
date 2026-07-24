# Fire-Skills Mono-repo Decomposition Plan

## Current State Analysis

### Dependency Chain (packages/)
```
skill-schemas (zod only)
    ↑
skill-core (depends on skill-schemas)
    ↑
skill-cli (depends on skill-core + skill-schemas)
```
These 3 packages form one tightly-coupled distributable tool → **one repo: `skill-spark`**.

### Skills Inventory (Post-restructure)

| Category | Skill | Path | Type |
|----------|-------|------|------|
| **base** | anysearch | `skills/base/anysearch/` | First-party |
| **base** | skill-spark | `skills/base/skill-spark/` | Meta (for CLI) |
| **devops** | gh-create-release | `skills/devops/gh-create-release/` | First-party |
| **devops** | git-workflow | `skills/devops/git-workflow/` | First-party |
| **devops** | github-cli-skill | `skills/devops/github-cli-skill/` | First-party |
| **devops** | local-workflow | `skills/devops/local-workflow/` | First-party |
| **devops** | scanning-for-secrets | `skills/devops/scanning-for-secrets/` | First-party |
| **meta** | skill-creator | `skills/meta/skill-creator/` | First-party |
| **qa** | test-case-generator | `skills/qa/test-case-generator/` | First-party |
| **shared** | find-skills | `skills/shared/find-skills/` | Shared util |
| **shared** | scaffold-app | `skills/shared/scaffold-app/` | Shared util |
| **content** | design | `skills/content/design/` | First-party (large) |
| **content** | baoyu-design | `skills/content/baoyu-design/` | Fork (has .git) |
| **figures** | thought-distiller | `skills/figures/thought-distiller/` | First-party |
| **sdlc-1p** | backend, frontend-*, integration, etc. | `skills/sdlc-first-party/` | First-party |
| **sdlc-3p** | 15 third-party repos | `skills/sdlc/` | Third-party (have .git) |

### Key Findings
- **No inter-skill code dependencies** — each skill is self-contained
- **One cross-reference**: `git-workflow/SKILL.md` references `github-cli-skill` (doc-only)
- **dev-workflow-install.sh** bundles 4 devops skills as a meta-installer
- **skill-shared** → now `skills/shared/` (flattened)
- **sdlc/** contains third-party repos (have their own .git)

---

## Target Architecture

### Independent Repos

```
github.com/variableway/
│
├── skill-spark/                    ← CLI tool (packages/* + src/ + dist/)
├── skill-anysearch/                ← skills/base/anysearch/
├── skill-gh-create-release/        ← skills/devops/gh-create-release/
├── skill-git-workflow/             ← skills/devops/git-workflow/
├── skill-github-cli/               ← skills/devops/github-cli-skill/
├── skill-local-workflow/           ← skills/devops/local-workflow/
├── skill-scanning-secrets/         ← skills/devops/scanning-for-secrets/
├── skill-creator/                  ← skills/meta/skill-creator/
├── skill-test-case-generator/      ← skills/qa/test-case-generator/
├── skill-find-skills/              ← skills/shared/find-skills/
├── skill-scaffold-app/             ← skills/shared/scaffold-app/
├── skill-thought-distiller/        ← skills/figures/thought-distiller/
├── skill-design/                   ← skills/content/design/
├── skill-baoyu-design/             ← skills/content/baoyu-design/ (already has .git)
│
├── fire-skills/                    ← MONO-REPO (this repo)
│   ├── packages/                   ← skill-spark CLI
│   ├── skills/                     ← all skills via subtrees
│   ├── apps/                       ← standalone apps
│   ├── docs/
│   └── scripts/
│
├── lifeos/                         ← apps/LifeOS/ (already independent)
├── qling/                          ← apps/qling/ (already independent)
└── skill-feed-manager/             ← apps/skill-feed-manager/
```

---

## Execution Steps

### Phase 1: Restructure Current Repo ✅ DONE
- [x] Flatten `skills/skill-shared/_shared/` → `skills/shared/`
- [x] Move `content-creation/skills/*` → `skills/content/`
- [x] Move `notable-figures/thought-distiller/` → `skills/figures/thought-distiller/`
- [x] Move first-party sdlc skills → `skills/sdlc-first-party/`
- [x] Keep `skills/sdlc/` as third-party subtree imports

### Phase 2: Create Individual Skill Repos
For each first-party skill:
1. Create new GitHub repo under `variableway/`
2. Initialize with skill contents at root
3. Add README.md with install instructions
4. Push to GitHub

### Phase 3: Set Up Subtree Sync (scripts/sync-subtrees.sh)
```bash
# Add each skill repo as subtree
git subtree add --prefix=skills/base/anysearch \
  git@github.com:variableway/skill-anysearch.git main --squash
```

### Phase 4: CI/CD
- Each skill repo: validate SKILL.md format
- Mono-repo: subtree sync workflow
- skill-spark: npm publish workflow

---

## Subtree Commands Reference

```bash
# === Adding a subtree (first time) ===
git subtree add --prefix=skills/base/anysearch \
  git@github.com:variableway/skill-anysearch.git main --squash

# === Syncing FROM individual repo TO mono-repo ===
git subtree pull --prefix=skills/base/anysearch \
  git@github.com:variableway/skill-anysearch.git main --squash

# === Pushing FROM mono-repo TO individual repo ===
git subtree push --prefix=skills/base/anysearch \
  git@github.com:variableway/skill-anysearch.git main

# === Extract a subtree into its own branch (for initial repo creation) ===
git subtree split --prefix=skills/base/anysearch -b skill-anysearch-main
```

---

## Migration Priority

1. **skill-spark** (CLI) — highest value, most reusability
2. **devops group** (5 skills) — most used by teams
3. **base skills** (anysearch, skill-spark meta)
4. **content-creation** (design skills)
5. **Third-party** (sdlc) — leave as subtree imports
