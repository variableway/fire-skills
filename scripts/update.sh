#!/usr/bin/env bash
# update.sh — Update installed skills using skill-spark CLI
#
# Usage:
#   ./scripts/update.sh [skill-names...] [options]
#
# Options:
#   --yes                 Auto-confirm prompts
#   --force               Skip confirmations
#   --silent              Suppress banner output
#
# Examples:
#   ./scripts/update.sh                         # Update all tracked skills
#   ./scripts/update.sh git-workflow            # Update specific skill
#   ./scripts/update.sh git-workflow local-workflow
#   ./scripts/update.sh --yes                   # Auto-confirm all updates

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Resolve skill-spark binary
if command -v skill-spark &>/dev/null; then
  CLI="skill-spark"
elif [ -f "$PROJECT_DIR/dist/index.js" ]; then
  CLI="node $PROJECT_DIR/dist/index.js"
elif command -v bun &>/dev/null; then
  CLI="bun run $PROJECT_DIR/src/index.ts"
else
  echo "Error: skill-spark not found." >&2
  echo "Run 'bun run build' or install skill-spark globally." >&2
  exit 1
fi

exec $CLI update "$@"
