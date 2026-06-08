#!/usr/bin/env bash
# Create a GitHub release with validation and smart defaults.
# Usage: create-release.sh <tag> [options] [asset-files...]
#
# Options:
#   --title <title>         Release title (default: tag name)
#   --notes <notes>         Release notes (inline)
#   --notes-file <file>     Read notes from file
#   --changelog <file>      Extract notes from CHANGELOG for this tag's version
#   --generate-notes        Auto-generate notes from PRs/commits
#   --draft                 Create as draft
#   --prerelease            Mark as prerelease
#   --target <branch/sha>   Target commitish for the tag
#   --latest                Mark as latest (default unless --prerelease)
#   --verify-tag            Fail if tag already exists (default: create tag if missing)
#   --help                  Show this help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAG=""
TITLE=""
NOTES=""
NOTES_FILE=""
CHANGELOG=""
GENERATE_NOTES=false
DRAFT=false
PRERELEASE=false
TARGET=""
LATEST=""
VERIFY_TAG=false
ASSETS=()

show_help() {
    sed -n '/^# Usage:/,/^$/p' "$0" | sed 's/^# //'
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --title) TITLE="$2"; shift 2 ;;
        --notes) NOTES="$2"; shift 2 ;;
        --notes-file) NOTES_FILE="$2"; shift 2 ;;
        --changelog) CHANGELOG="$2"; shift 2 ;;
        --generate-notes) GENERATE_NOTES=true; shift ;;
        --draft) DRAFT=true; shift ;;
        --prerelease) PRERELEASE=true; shift ;;
        --target) TARGET="$2"; shift 2 ;;
        --latest) LATEST="--latest"; shift ;;
        --verify-tag) VERIFY_TAG=true; shift ;;
        --help) show_help ;;
        --*) echo "Unknown option: $1" >&2; exit 1 ;;
        *)
            if [[ -z "$TAG" ]]; then
                TAG="$1"
            else
                ASSETS+=("$1")
            fi
            shift
            ;;
    esac
done

if [[ -z "$TAG" ]]; then
    echo "Error: Tag is required." >&2
    show_help
fi

# Check gh auth
if ! gh auth status &>/dev/null; then
    echo "Error: gh CLI is not authenticated. Run 'gh auth login' first." >&2
    exit 1
fi

# Check git repo
if ! git rev-parse --git-dir &>/dev/null; then
    echo "Error: Not inside a git repository." >&2
    exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Warning: Working tree has uncommitted changes. Verify assets and generated notes before publishing." >&2
fi

if gh release view "$TAG" &>/dev/null; then
    echo "Error: Release '$TAG' already exists. Use 'gh release edit' or delete it explicitly if replacement is intended." >&2
    exit 1
fi

# Verify tag exists or will be created
TAG_EXISTS=$(git tag -l "$TAG" || true)
if [[ "$VERIFY_TAG" == true && -z "$TAG_EXISTS" ]]; then
    echo "Error: Tag '$TAG' does not exist and --verify-tag was set." >&2
    exit 1
fi

# Validate asset files exist
for asset in "${ASSETS[@]}"; do
    if [[ ! -f "$asset" ]]; then
        echo "Error: Asset file not found: $asset" >&2
        exit 1
    fi
done

# Build gh release create command
CMD=(gh release create "$TAG")

[[ -n "$TITLE" ]] && CMD+=(--title "$TITLE")
[[ "$DRAFT" == true ]] && CMD+=(--draft)
[[ "$PRERELEASE" == true ]] && CMD+=(--prerelease)
[[ -n "$TARGET" ]] && CMD+=(--target "$TARGET")
[[ -n "$LATEST" ]] && CMD+=($LATEST)

# Handle notes strategies (mutually exclusive in practice)
if [[ -n "$CHANGELOG" ]]; then
    if [[ ! -f "$CHANGELOG" ]]; then
        echo "Error: CHANGELOG file not found: $CHANGELOG" >&2
        exit 1
    fi
    NOTES=$("$SCRIPT_DIR/extract-changelog-notes.sh" "$CHANGELOG" "$TAG" 2>/dev/null || true)
    if [[ -z "$NOTES" ]]; then
        echo "Warning: Could not extract notes for '$TAG' from $CHANGELOG. Falling back to generate-notes." >&2
        GENERATE_NOTES=true
    fi
fi

if [[ -n "$NOTES_FILE" ]]; then
    if [[ ! -f "$NOTES_FILE" ]]; then
        echo "Error: Notes file not found: $NOTES_FILE" >&2
        exit 1
    fi
    CMD+=(--notes-file "$NOTES_FILE")
elif [[ -n "$NOTES" ]]; then
    CMD+=(--notes "$NOTES")
elif [[ "$GENERATE_NOTES" == true ]]; then
    CMD+=(--generate-notes)
fi

# Add assets
CMD+=("${ASSETS[@]}")

echo "Creating release: ${CMD[*]}"
"${CMD[@]}"
