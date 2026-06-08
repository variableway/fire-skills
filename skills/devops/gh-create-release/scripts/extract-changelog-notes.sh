#!/usr/bin/env bash
# Extract release notes for a specific version from a CHANGELOG file.
# Usage: extract-changelog-notes.sh <changelog-file> <version>
# Outputs clean markdown (without the version heading) to stdout.

set -euo pipefail

CHANGELOG_FILE="${1:-}"
VERSION="${2:-}"

if [[ -z "$CHANGELOG_FILE" || -z "$VERSION" ]]; then
    echo "Usage: $0 <changelog-file> <version>" >&2
    echo "Example: $0 CHANGELOG.md v1.2.3" >&2
    exit 1
fi

if [[ ! -f "$CHANGELOG_FILE" ]]; then
    echo "Error: File not found: $CHANGELOG_FILE" >&2
    exit 1
fi

# Normalize version (strip leading 'v' for matching flexibility)
VERSION_CLEAN="${VERSION#v}"

# Try multiple heading patterns:
# 1. Keep a Changelog: ## [1.2.3] or ## [1.2.3] - 2024-01-01
# 2. Simple: ## 1.2.3 or ## v1.2.3
# 3. With date: ## 1.2.3 (2024-01-01)

PATTERNS=(
    "^## \[${VERSION_CLEAN}\]"
    "^## \[${VERSION}\]"
    "^## ${VERSION_CLEAN}\b"
    "^## ${VERSION}\b"
)

START_LINE=""
for pattern in "${PATTERNS[@]}"; do
    START_LINE=$(grep -n -E "$pattern" "$CHANGELOG_FILE" | head -1 | cut -d: -f1 || true)
    if [[ -n "$START_LINE" ]]; then
        break
    fi
done

if [[ -z "$START_LINE" ]]; then
    echo "Error: Version '$VERSION' not found in $CHANGELOG_FILE" >&2
    exit 1
fi

# Find the next ## heading (or end of file)
END_LINE=$(tail -n +$((START_LINE + 1)) "$CHANGELOG_FILE" | grep -n -E '^## ' | head -1 | cut -d: -f1 || true)

if [[ -n "$END_LINE" ]]; then
    # END_LINE is relative to the tail output, convert to absolute
    END_LINE=$((START_LINE + END_LINE))
    # Extract lines between START_LINE+1 and END_LINE-1
    sed -n "$((START_LINE + 1)),$((END_LINE - 1))p" "$CHANGELOG_FILE"
else
    # No next heading, extract until end of file
    sed -n "$((START_LINE + 1)),\$p" "$CHANGELOG_FILE"
fi
