#!/usr/bin/env bash
# remove.sh — Remove installed skills using skill-spark CLI
#
# Usage:
#   ./scripts/remove.sh <skill-name> [options]
#
# Options:
#   --yes                 Auto-confirm prompts
#   --force               Skip confirmations
#   --silent              Suppress banner output
#
# Examples:
#   ./scripts/remove.sh git-workflow
#   ./scripts/remove.sh skill:git-workflow
#   ./scripts/remove.sh git-workflow local-workflow
#   ./scripts/remove.sh git-workflow --yes

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

if [ $# -eq 0 ]; then
  echo "Usage: $0 <skill-name> [options]"
  echo ""
  echo "Examples:"
  echo "  $0 git-workflow                     # Remove single skill"
  echo "  $0 skill:git-workflow               # Remove with type prefix"
  echo "  $0 git-workflow local-workflow      # Remove multiple skills"
  echo "  $0 git-workflow --yes               # Auto-confirm"
  echo ""
  echo "Run '$CLI remove --help' for more options."
  exit 1
fi

exec $CLI remove "$@"
