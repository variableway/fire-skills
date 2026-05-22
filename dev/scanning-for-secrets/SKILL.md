---
name: scanning-for-secrets
description: Use when about to commit or push code, or when GitHub push protection blocks a push. Scans staged files for accidentally included secrets, tokens, API keys, and credentials.
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
2. **If already committed** - rewrite history:
   ```bash
   # Remove file from all history
   FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --force \
     --index-filter 'git rm --cached --ignore-unmatch <FILE>' \
     --prune-empty -- --all
   # Clean up
   rm -rf .git/refs/original/
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   ```
3. **Add to .gitignore** - local settings files that may contain tokens
4. **Force push** - `git push --force` after history rewrite
5. **Rotate the secret** - assume it's compromised, generate a new token

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
| Token in git history | Use `git filter-branch` to rewrite history |
| Forgetting to gitignore local configs | Add `*.local.*` patterns proactively |
| Only scanning on push | Scan on commit - cheaper to fix earlier |
