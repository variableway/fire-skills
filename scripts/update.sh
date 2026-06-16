#!/usr/bin/env bash
# Wrapper script for skill-spark update
# Usage: ./scripts/update.sh [skill-names...] [--system|--project] [--force]

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

exec $CLI update "$@"
