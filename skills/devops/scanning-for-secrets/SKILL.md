---
name: scanning-for-secrets
description: Use when about to commit or push code, or when GitHub push protection blocks a push. Scans staged files for accidentally included secrets, tokens, API keys, and credentials.
compatibility: Works with git. Prefer gitleaks or detect-secrets when available; grep fallback is included.
metadata:
  tags:
    - security
    - git
    - dev-workflow
---

# Scanning for Secrets

## Overview

Prevent secrets from reaching git history by scanning staged files for common credential patterns **before** committing or pushing.

## When to Use

- Before `git commit` or `git push`
- When GitHub push protection blocks a push
- When adding new config files, environment files, or permission settings
- When editing files that may contain tokens (`.env`, `settings*.json`, `config`)

## Secret Patterns

| Type | Pattern | Example |
|------|---------|---------|
| GitHub OAuth | `gho_[A-Za-z0-9]{36}` | `gho_ejXIzF1Bj...` |
| GitHub PAT (classic) | `ghp_[A-Za-z0-9]{36}` | `ghp_ABCdef123...` |
| GitHub PAT (fine-grained) | `github_pat_[A-Za-z0-9_]{82}` | `github_pat_abc123...` |
| GitHub App Token | `(ghu|ghs)_[A-Za-z0-9]{36}` | `ghu_ABCdef123...` |
| GitHub Refresh Token | `ghr_[A-Za-z0-9]{36}` | `ghr_ABCdef123...` |
| AWS Access Key | `AKIA[0-9A-Z]{16}` | `AKIAIOSFODNN7EXAMPLE` |
| AWS Secret Key | `[A-Za-z0-9/+=]{40}` near AWS context | ... |
| Google API Key | `AIza[0-9A-Za-z_-]{35}` | `AIzaSyD...` |
| Slack Token | `xox[baprs]-[0-9]{10,}` | `xoxb-123456...` |
| Private Key | `-----BEGIN (RSA\|EC\|DSA)? ?PRIVATE KEY-----` | ... |
| Generic Hex Token | 32+ char hex strings in assignment/arg context | `token=abcd1234...` |
| Bearer Token | `Bearer [A-Za-z0-9_\-.]+` in code | `Bearer eyJ...` |

## Quick Scan Command

Prefer a dedicated scanner when available:

```bash
gitleaks detect --source . --staged --redact
```

Fallback quick check for staged files:

Scan all staged files for secrets:

```bash
git diff --cached --diff-filter=ACMR -z -- | xargs -0 -I{} sh -c '
  echo "=== {} ===" && grep -n -E "(
    gho_[A-Za-z0-9]{30,}|
    ghp_[A-Za-z0-9]{30,}|
    github_pat_[A-Za-z0-9_]{30,}|
    ghu_[A-Za-z0-9]{30,}|
    ghs_[A-Za-z0-9]{30,}|
    ghr_[A-Za-z0-9]{30,}|
    AKIA[0-9A-Z]{16}|
    AIza[0-9A-Za-z_-]{35}|
    xox[baprs]-[0-9]{10,}|
    -----BEGIN [A-Z ]*PRIVATE KEY-----|
    (token|key|secret|password|credential|auth)[\"'"'"']?\s*[:=]\s*[\"'"'"']?[A-Za-z0-9_\-.]{20,}
  )" "{}" 2>/dev/null || true'
```

Or simpler one-liner for quick check:

```bash
git diff --cached --name-only -- | xargs grep -l -E "(gho_|ghp_|github_pat_|ghu_|ghs_|ghr_|AKIA|AIza|xox[baprs]-|BEGIN.*PRIVATE KEY)" 2>/dev/null
```

## Resolution Workflow

When a secret is found:

1. **Do NOT commit** - remove the secret first
2. **Unstage and edit safely**:
   ```bash
   git restore --staged <FILE>
   # edit the file, replace the secret with an env var or placeholder
   git add <FILE>
   ```
3. **Add ignore rules** for local settings files that may contain tokens.
4. **Rotate the secret** - assume it is compromised once it was written to disk or shown in logs.
5. **If already committed but not pushed**, prefer amending or interactive rebase after rotating the secret.
6. **If already pushed**, stop and coordinate before rewriting history. Prefer `git filter-repo` or BFG Repo-Cleaner over `git filter-branch`; back up the repo, notify collaborators, rotate the secret first, then force-push only with explicit approval.

## Files That Commonly Contain Secrets

- `.env`, `.env.local`, `.env.production`
- `settings.local.json`, `config.local.*`
- `credentials.json`, `service-account*.json`
- `.npmrc`, `.pypirc`, `netrc`
- Any file in `.claude/` with `local` in the name

## Pre-commit Hook

To automatically scan before every commit, add to `.git/hooks/pre-commit`:

```bash
#!/bin/sh
STAGED=$(git diff --cached --name-only --diff-filter=ACMR)
if [ -n "$STAGED" ]; then
  MATCHES=$(echo "$STAGED" | xargs grep -l -E "(gho_|ghp_|github_pat_|ghu_|ghs_|ghr_|AKIA|AIza|xox[baprs]-|BEGIN.*PRIVATE KEY)" 2>/dev/null)
  if [ -n "$MATCHES" ]; then
    echo "ERROR: Potential secrets found in staged files:"
    echo "$MATCHES"
    echo "Remove secrets before committing. Use /scanning-for-secrets for help."
    exit 1
  fi
fi
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| "Just testing" token in code | Use env vars or `gh auth token` |
| Token in git history | Rotate first, then use `git filter-repo` or BFG with explicit approval |
| Forgetting to gitignore local configs | Add `*.local.*` patterns proactively |
| Only scanning on push | Scan on commit - cheaper to fix earlier |
