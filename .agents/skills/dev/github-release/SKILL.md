---
name: github-release
description: >
  Create and manage GitHub releases. Use when the user asks to release,
  publish a version, create a tag, write release notes, or ship code via
  GitHub Releases. Triggers on "release", "tag", "publish version", or
  "ship to GitHub".
---

# /github-release — Create and Manage GitHub Releases

Manage the full release lifecycle: versioning, tagging, release notes, and artifacts.

## Workflow

### 1. Determine Version

Check existing tags to pick the next version:

```bash
gh release list --limit 10       # See recent releases
git tag --sort=-v:refname | head -10  # See recent tags
```

Follow the project's versioning scheme:
- **SemVer** (`v1.2.3`): `major.minor.patch`
- **CalVer** (`v2024.06.04`): `YYYY.MM.DD`
- **Project-specific**: Check `package.json`, `Cargo.toml`, or `pyproject.toml`

### 2. Prepare Release Notes

Generate notes automatically or write manually:

```bash
# Auto-generate from merged PRs
gh release create v1.2.3 --generate-notes --draft

# Preview generated notes without creating
gh api repos/{owner}/{repo}/releases/generate-notes \
  -f tag_name=v1.2.3 -f previous_tag_name=v1.2.2 \
  --jq '.body'
```

Manual notes structure:

```markdown
## What's New
- Feature A description (#123)
- Feature B description (#124)

## Bug Fixes
- Fixed issue with X (#125)

## Breaking Changes
- Deprecated API Y

## Contributors
@user1, @user2
```

### 3. Create the Release

```bash
# Simple release with auto-notes
gh release create v1.2.3 --generate-notes

# Release with custom notes file
gh release create v1.2.3 --notes-file RELEASE_NOTES.md

# Release with artifacts
gh release create v1.2.3 --generate-notes dist/*.tar.gz dist/*.zip

# Draft release (review before publishing)
gh release create v1.2.3 --draft --generate-notes

# Prerelease
gh release create v1.2.3-beta.1 --prerelease --generate-notes
```

### 4. Upload Assets (if not done at creation)

```bash
gh release upload v1.2.3 ./build/my-binary
gh release upload v1.2.3 ./dist/*
```

### 5. Publish (if drafted)

```bash
gh release edit v1.2.3 --draft=false
```

## Commands Reference

```bash
# List releases
gh release list
gh release list --limit 20

# View a release
gh release view v1.2.3
gh release view v1.2.3 --json url,assets,body

# Download assets
gh release download v1.2.3
gh release download v1.2.3 --pattern "*.tar.gz"

# Edit release
gh release edit v1.2.3 --title "New Title" --notes "Updated notes"

# Delete release (careful!)
gh release delete v1.2.3
```

## CI/CD Integration

### GitHub Actions — Auto-release on tag

```yaml
name: Release
on:
  push:
    tags: ['v*']
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: gh release create ${{ github.ref_name }} --generate-notes
        env:
          GH_TOKEN: ${{ github.token }}
```

### GitHub Actions — Release with artifacts

```yaml
- name: Create Release
  run: |
    gh release create ${{ github.ref_name }} \
      --generate-notes \
      ./dist/*.zip ./dist/*.tar.gz
  env:
    GH_TOKEN: ${{ github.token }}
```

## Rules

- Always verify the version doesn't already exist: `gh release view vX.Y.Z`
- Use `--draft` for releases that need human review before going live
- Generate notes from PRs when possible — it's accurate and saves time
- Upload build artifacts at creation time, not separately, when possible
- Tag and release in one step; avoid creating tags via `git tag` separately
- For monorepos, include the package name in the tag: `@scope/pkg@v1.2.3`
