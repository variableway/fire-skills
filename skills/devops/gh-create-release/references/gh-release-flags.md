# gh release create — Flag Reference

Complete reference for `gh release create` flags and patterns.

## Basic Syntax

```bash
gh release create <tag> [<files>...] [flags]
```

## Core Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--draft` | | Save as draft, don't publish |
| `--prerelease` | | Mark as prerelease |
| `--latest` | | Mark as latest (default for non-prerelease) |
| `--target <branch>` | `-t` | Commitish target for the tag |
| `--title <string>` | | Release title |

## Notes Flags (mutually exclusive)

| Flag | Description |
|------|-------------|
| `--notes <string>` | Inline release notes |
| `--notes-file <file>` | Read notes from file |
| `--generate-notes` | Auto-generate from PRs/commits |

## Discussion Flags

| Flag | Description |
|------|-------------|
| `--discussion-category <name>` | Create discussion in category |

## Verification Flags

| Flag | Description |
|------|-------------|
| `--verify-tag` | Abort if tag doesn't exist |
| `--repo <owner/repo>` | Target repository (overrides current) |

## Examples

### Minimal release with auto-generated notes

```bash
gh release create v1.0.0 --generate-notes
```

### Draft release with custom title

```bash
gh release create v2.0.0-rc.1 \
  --draft \
  --prerelease \
  --title "Version 2.0 RC 1" \
  --generate-notes
```

### Full release with assets and notes file

```bash
gh release create v1.2.3 \
  --title "Version 1.2.3" \
  --notes-file ./RELEASE_NOTES.md \
  --target main \
  dist/*.tar.gz \
  checksums.txt
```

### Create tag at specific commit and release

```bash
gh release create v1.2.3 \
  --target abc1234 \
  --generate-notes
```

## Related Commands

```bash
gh release list              # List releases
gh release view <tag>        # View release details
gh release delete <tag>      # Delete a release
gh release upload <tag> <file>  # Upload assets to existing release
gh release download <tag>    # Download release assets
```
