---
name: gh-create-release
description: Create GitHub releases using the gh CLI tool. Use when the user wants to (1) create a new GitHub release for a tag, (2) draft or publish a release with notes, (3) upload release assets/binaries, (4) create a prerelease, (5) generate release notes automatically, or (6) extract release notes from a CHANGELOG.md file. Covers workflows from simple tag-based releases to complex releases with multiple assets and custom notes.
compatibility: Requires git and authenticated GitHub CLI gh.
metadata:
  tags:
    - github
    - release
    - dev-workflow
---

# GitHub Release Creation Skill

Create GitHub releases efficiently using the `gh release create` command.

## Prerequisites

- `gh` CLI authenticated (`gh auth status`)
- Inside a git repository with a remote pointing to GitHub

## Quick Workflows

Before creating a release, inspect the repo state:

```bash
gh auth status
git status --short
git tag --list v1.2.3
gh release view v1.2.3
```

If `gh release view <tag>` already succeeds, do not create a duplicate release; edit or delete the existing release only if the user asks.

### 1. Create a Simple Release

```bash
gh release create v1.2.3 --generate-notes
```

### 2. Create a Release with Custom Notes

```bash
gh release create v1.2.3 --title "Version 1.2.3" --notes "Bug fixes and improvements"
```

### 3. Create a Draft or Prerelease

```bash
gh release create v2.0.0-beta.1 --prerelease --generate-notes
gh release create v1.2.3 --draft --title "Draft Release"
```

### 4. Release with Asset Uploads

```bash
gh release create v1.2.3 dist/*.tar.gz dist/*.zip --generate-notes
```

### 5. Release with Notes from CHANGELOG

```bash
# Extract notes for version v1.2.3 from CHANGELOG.md
notes=$(scripts/extract-changelog-notes.sh CHANGELOG.md v1.2.3)
gh release create v1.2.3 --notes "$notes"
```

### 6. Create Release and Tag in One Command

```bash
gh release create v1.2.3 --target main --generate-notes
```

> If the tag doesn't exist, `gh` creates it at the current commit (or specified `--target`).

## Release Notes Strategies

| Strategy | When to Use | Command |
|----------|-------------|---------|
| Auto-generate | Quick releases, PR history is sufficient | `--generate-notes` |
| Inline notes | Short, custom notes | `--notes "..."` |
| File notes | Long, pre-written notes | `--notes-file release-notes.md` |
| CHANGELOG | Following Keep a Changelog format | Use `scripts/extract-changelog-notes.sh` |

## Scripts

### Extract CHANGELOG Notes

`scripts/extract-changelog-notes.sh <changelog-file> <version>`

Extracts the release notes section for a given version. Supports:
- Keep a Changelog format (`## [1.2.3]`)
- Simple heading format (`## 1.2.3` or `## v1.2.3`)

Returns clean markdown (no heading) suitable for `--notes`.

### Create Release with Validation

`scripts/create-release.sh <tag> [options] [assets...]`

Validates tag, assets, and repo state before creating the release. Run with `--help` for options.

## Reference

For complete flag reference and advanced patterns, see [references/gh-release-flags.md](references/gh-release-flags.md).

## Common Gotchas

- **Tag must be a valid git ref name** — no spaces, avoid special characters
- **Assets are uploaded after release creation** — if upload fails, the release may exist without assets
- **Draft releases are not visible publicly** — must publish manually or omit `--draft`
- **`--generate-notes` and `--notes` conflict** — don't use both together
- **Existing releases are not overwritten** — check `gh release view <tag>` before creating
- **Dirty worktrees are risky** — warn the user if uncommitted changes may affect generated notes or assets

## Installation

Prefer installing with `skill-spark`:

```bash
./dist/skill-spark add skills/devops --skill gh-create-release --agent codex claude-code opencode trae kimi --yes
```

The bundled install scripts are legacy fallbacks for environments that do not use `skill-spark`:

```bash
./scripts/install.sh --system
.\scripts\install.ps1 -System
```
