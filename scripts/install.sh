#!/usr/bin/env bash
# Wrapper script for skill-spark add
# Usage: ./scripts/install.sh <source> [--system|--project] [--agent <name>]

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

# Parse arguments
SOURCE=""
ARGS=()

for arg in "$@"; do
  case "$arg" in
    --system)
      ARGS+=("--global")
      ;;
    --project)
      # Default behavior, no flag needed
      ;;
    *)
      if [ -z "$SOURCE" ]; then
        SOURCE="$arg"
      else
        ARGS+=("$arg")
      fi
      ;;
  esac
done

if [ -z "$SOURCE" ]; then
  echo "Usage: $0 <source> [--system|--project] [--agent <name>]"
  echo ""
  echo "Examples:"
  echo "  $0 skills/devops --system"
  echo "  $0 skills/devops --project --agent codex"
  echo "  $0 github.com/user/repo --system"
  exit 1
fi

exec $CLI add "$SOURCE" "${ARGS[@]}"
