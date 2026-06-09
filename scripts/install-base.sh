#!/usr/bin/env bash
# One-click install base skills using skill-spark CLI
#
# Usage: ./scripts/install-base.sh [--system | --project] [--agent <name>]
#
# Examples:
#   ./scripts/install-base.sh --system
#   ./scripts/install-base.sh --project --agent claude-code

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$ROOT_DIR/dist/skill-spark"
SOURCE="$ROOT_DIR/skills/base"

MODE=""
AGENTS=()

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<'EOF'
One-click install base skills using skill-spark CLI

Usage: ./scripts/install-base.sh [--system | --project] [--agent <name>]

Options:
  --system        Install to system level (global, default)
  --project       Install to project level (local)
  --agent <name>  Target agent(s), repeatable (default: all)

Examples:
  ./scripts/install-base.sh --system
  ./scripts/install-base.sh --project --agent claude-code
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --system)  MODE="global"; shift ;;
        --project) MODE="local"; shift ;;
        --agent)   AGENTS+=("$2"); shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *)         echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if [[ -z "$MODE" ]]; then
    MODE="global"
fi

if [[ ! -x "$CLI" ]]; then
    echo -e "${RED}Error: skill-spark CLI not found. Run 'bun run build' first.${NC}" >&2
    exit 1
fi

echo -e "${BLUE}Installing base skills...${NC}"
echo "  Source: $SOURCE"
echo "  Mode: $MODE"
echo ""

CMD=("$CLI" add "$SOURCE")
[[ "$MODE" == "global" ]] && CMD+=("--global")
if [[ ${#AGENTS[@]} -gt 0 ]]; then
    for agent in "${AGENTS[@]}"; do
        CMD+=("--agent" "$agent")
    done
fi
CMD+=("--yes")

"${CMD[@]}"

echo ""
echo -e "${GREEN}Done!${NC}"
