#!/usr/bin/env bash
# Wrapper script for skill-spark remove
# Usage: ./scripts/remove.sh <skill-name> [--system|--project]

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
  echo "Error: skill-spark not found. Run 'bun run build' first." >&2
  exit 1
fi

if [ $# -eq 0 ]; then
  echo "Usage: $0 <skill-name> [--system|--project]"
  echo ""
  echo "Examples:"
  echo "  $0 git-workflow"
  echo "  $0 skill:git-workflow"
  exit 1
fi

exec $CLI remove "$@"
