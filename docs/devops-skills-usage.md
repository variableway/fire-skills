# DevOps Skills Usage Guide

## Overview

The devops skills provide task execution workflows, GitHub CLI helpers, release management, and security scanning for AI coding agents.

| Skill | Purpose | Requires GitHub |
|-------|---------|-----------------|
| [git-workflow](#git-workflow) | Issue-based task lifecycle | Yes |
| [local-workflow](#local-workflow) | Local/offline task tracking | No |
| [github-cli-skill](#github-cli-skill) | Quick `gh` CLI commands | Yes |
| [gh-create-release](#gh-create-release) | GitHub release creation | Yes |
| [scanning-for-secrets](#scanning-for-secrets) | Pre-commit secret scanning | No |

---

## git-workflow

GitHub Issue-based task workflow. Creates an Issue, executes the task, then closes the Issue with structured results.

### When to Use

- "execute task", "run task", "Task 9"
- References to `@tasks/issues/`
- Any task that needs a GitHub Issue as the canonical record

### Commands

```bash
# Initialize: create GitHub Issue
python3 ~/.claude/skills/git-workflow/scripts/orchestrate.py init \
  --title "Task title" \
  --description "Task description"

# Finish: update Issue body and close
python3 ~/.claude/skills/git-workflow/scripts/orchestrate.py finish \
  --message "Completion summary"

# Check status
python3 ~/.claude/skills/git-workflow/scripts/orchestrate.py status

# Abort workflow
python3 ~/.claude/skills/git-workflow/scripts/orchestrate.py abort
```

### Standalone Scripts

```bash
# Create Issue only
python3 ~/.claude/skills/git-workflow/scripts/create_issue.py \
  --title "Bug report" \
  --description "Details" \
  --labels "bug,priority:high"

# Close Issue only
python3 ~/.claude/skills/git-workflow/scripts/close_issue.py \
  --message "Fixed in commit abc123"
```

### Git Hooks

```bash
# Install hooks (appends Refs: #N to commits)
cp ~/.claude/skills/git-workflow/hooks/prepare-commit-msg .git/hooks/
chmod +x .git/hooks/prepare-commit-msg
```

### Prerequisites

- `git` with a GitHub remote
- Authenticated `gh` CLI (`gh auth login`)

---

## local-workflow

Fully local/offline task workflow. Tracks tasks via files in `tasks/tracing/`, no GitHub needed.

### When to Use

- "local workflow", "offline", "no github"
- Private projects, air-gapped environments
- Quick local task tracking

### Commands

```bash
# Initialize: create local tracing record
python3 ~/.claude/skills/local-workflow/scripts/orchestrate.py init tasks/issues/my-task.md

# Finish: mark complete (optional commit/push)
python3 ~/.claude/skills/local-workflow/scripts/orchestrate.py finish
python3 ~/.claude/skills/local-workflow/scripts/orchestrate.py finish --commit
python3 ~/.claude/skills/local-workflow/scripts/orchestrate.py finish --commit --push

# Check status
python3 ~/.claude/skills/local-workflow/scripts/orchestrate.py status

# Abort workflow
python3 ~/.claude/skills/local-workflow/scripts/orchestrate.py abort
```

### Direct Tracing

```bash
# Initialize tracing directly
python3 ~/.claude/skills/local-workflow/scripts/tracing.py init --task tasks/issues/my-task.md

# Finish tracing
python3 ~/.claude/skills/local-workflow/scripts/tracing.py finish \
  --task tasks/issues/my-task.md \
  --summary "Task completed"

# View all records
python3 ~/.claude/skills/local-workflow/scripts/tracing.py status

# View specific task
python3 ~/.claude/skills/local-workflow/scripts/tracing.py show --task tasks/issues/my-task.md
```

### Prerequisites

- Python 3
- `git` (only for optional `--commit`/`--push`)

---

## github-cli-skill

Quick reference for `gh` CLI operations. Use for one-off commands without the full workflow lifecycle.

### When to Use

- "gh command", "create repo", "list issue"
- Quick GitHub operations
- One-off Issue/comment/PR tasks

### Common Commands

```bash
# Repos
gh repo create my-repo --public
gh repo view --web

# Issues
gh issue create --title "Bug" --body "Description"
gh issue list --state open
gh issue view 123
gh issue comment 123 --body "Update: fixed"
gh issue close 123

# PRs
gh pr create --title "Feature" --body "Description"
gh pr list
gh pr merge 456

# Releases
gh release create v1.0.0 --generate-notes
```

### Script

```bash
# Create Issue via script
python3 ~/.claude/skills/github-cli-skill/scripts/create_issue.py \
  --title "Issue title" \
  --body "Issue body" \
  --labels "bug" \
  --repo owner/repo
```

### Prerequisites

- Authenticated `gh` CLI (`gh auth login`)

---

## gh-create-release

Creates GitHub releases with tags, notes, and asset uploads.

### When to Use

- "create release", "draft release", "prerelease"
- "release note", "upload asset", "tag release"

### Workflows

```bash
# Simple release with auto-generated notes
gh release create v1.2.3 --generate-notes

# Release with custom notes
gh release create v1.2.3 --title "v1.2.3" --notes "Bug fixes and improvements"

# Draft release
gh release create v1.2.3 --draft --generate-notes

# Prerelease
gh release create v2.0.0-beta.1 --prerelease --generate-notes

# Release with assets
gh release create v1.2.3 dist/*.tar.gz dist/*.zip --generate-notes

# Release targeting specific branch
gh release create v1.2.3 --target main --generate-notes
```

### Scripts

```bash
# Extract notes from CHANGELOG.md
~/.claude/skills/gh-create-release/scripts/extract-changelog-notes.sh CHANGELOG.md v1.2.3

# Create release with validation
~/.claude/skills/gh-create-release/scripts/create-release.sh v1.2.3 \
  --title "Release v1.2.3" \
  dist/app.tar.gz dist/app.zip
```

### Prerequisites

- `git` with valid tags
- Authenticated `gh` CLI

---

## scanning-for-secrets

Scans staged files for secrets, tokens, and API keys before committing.

### When to Use

- "scan secret", "before commit"
- "gitleaks", "token", "api key"
- "push protection"

### Commands

```bash
# Using gitleaks (preferred)
gitleaks detect --source . --staged --redact

# Using grep fallback
git diff --cached --name-only -- | xargs grep -l -E "(gho_|ghp_|github_pat_|AKIA|AIza|xox[baprs]-)" || echo "No secrets found"

# Quick one-liner
git diff --cached --name-only -- | xargs grep -l -E "(gho_|ghp_|github_pat_|ghu_|ghs_|ghr_|AKIA|AIza|xox[baprs]-|PRIVATE KEY|Bearer )"
```

### Detected Patterns

| Pattern | Prefix |
|---------|--------|
| GitHub OAuth token | `gho_` |
| GitHub PAT | `ghp_`, `github_pat_` |
| GitHub App token | `ghu_`, `ghs_` |
| GitHub refresh token | `ghr_` |
| AWS access key | `AKIA` |
| Google API key | `AIza` |
| Slack token | `xox[baprs]-` |
| Private key | `-----BEGIN` |

### When a Secret is Found

1. **Do NOT commit**
2. Unstage: `git restore --staged <FILE>`
3. Replace secret with env var or placeholder
4. Re-add and commit
5. Rotate the secret (assume compromised)
6. If already pushed: use `git filter-repo` or BFG, notify collaborators

### Install Pre-commit Hook

```bash
cp ~/.claude/skills/scanning-for-secrets/hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
```

### Prerequisites

- `git`
- Optional: `gitleaks` or `detect-secrets` for thorough scanning

---

## Skill Comparison

| Feature | git-workflow | local-workflow | github-cli-skill |
|---------|-------------|----------------|------------------|
| GitHub Issues | ✅ Full lifecycle | ❌ | ✅ Individual commands |
| Local tracking | ❌ | ✅ `tasks/tracing/` | ❌ |
| Offline | ❌ | ✅ | ❌ |
| Task lifecycle | ✅ init→execute→finish | ✅ init→execute→finish | ❌ |
| Git hooks | ✅ | ❌ | ❌ |

### When to Use Which

- **Full task with GitHub**: Use `git-workflow`
- **Full task without GitHub**: Use `local-workflow`
- **Quick `gh` command**: Use `github-cli-skill`
- **Create release**: Use `gh-create-release`
- **Before commit**: Use `scanning-for-secrets`
