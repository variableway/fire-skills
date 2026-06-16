#!/usr/bin/env bash
# install.sh — Install skills using skill-spark CLI
#
# Usage:
#   ./scripts/install.sh <source> [options]
#
# Options:
#   --system              Install globally (maps to --global)
#   --project             Install to project directory (default)
#   --agent <name>        Target specific agent (e.g., codex, claude, kimi)
#   --skill <name>        Install specific skill by name
#   --yes                 Auto-confirm prompts
#   --force               Skip confirmations
#   --no-symlink          Copy files instead of symlinks
#   --silent              Suppress banner output
#
# Examples:
#   ./scripts/install.sh skills/devops --system
#   ./scripts/install.sh skills/devops --project --agent codex
#   ./scripts/install.sh github.com/user/repo --system
#   ./scripts/install.sh skills/devops --skill git-workflow --system
#
# Source types:
#   Local directory       skills/devops, ./my-skill
#   GitHub shorthand      user/repo
#   GitHub URL            github.com/user/repo
#   GitLab URL            gitlab.com/user/repo
#   Well-Known            well-known:example.com

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
  echo "  $0 skills/devops --system                    # Install devops globally"
  echo "  $0 skills/devops --project --agent codex     # Install to project for codex"
  echo "  $0 github.com/user/repo --system             # Install from GitHub"
  echo ""
  echo "Run '$CLI add --help' for more options."
  exit 1
fi

exec $CLI add "$SOURCE" "${ARGS[@]}"
