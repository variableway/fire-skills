#!/usr/bin/env bash
# Unified Skill Updater (macOS / Linux / WSL2)
# Re-installs skills from their source to update them.
#
# Usage: ./scripts/update.sh <source> [OPTIONS]
#
# Options:
#   --system              Update system skills (default)
#   --project             Update project skills
#   --global              Alias for --system
#   --agent <name>        Target agent(s), repeatable (default: all)
#   --skill <name>        Update specific skill(s) only, repeatable
#   --force               Remove existing before reinstalling
#   -h, --help            Show this help message
#
# Examples:
#   ./scripts/update.sh skills/devops --system --force
#   ./scripts/update.sh skills/base --system --skill anysearch --force

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_SPARK_HOME="${SKILL_SPARK_HOME:-$HOME/.skill-spark}"
CANONICAL_DIR="$SKILL_SPARK_HOME/.agents/skills"

SOURCE_PATH=""
INSTALL_MODE="system"
TARGET_AGENTS=""
SELECTED_SKILLS=""
FORCE_UPDATE=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ALL_AGENTS="claude-code kimi codex opencode trae trae-solo workbuddy"

is_valid_agent() {
    case "$1" in
        claude-code|kimi|codex|opencode|trae|trae-solo|workbuddy) return 0 ;;
        *) return 1 ;;
    esac
}

usage() {
    cat <<'EOF'
Unified Skill Updater (macOS / Linux / WSL2)
Re-installs skills from source to update them.

Usage: ./scripts/update.sh <source> [OPTIONS]

Options:
  --system              Update system skills (default)
  --project             Update project skills
  --global              Alias for --system
  --agent <name>        Target agent(s), repeatable (default: all)
  --skill <name>        Update specific skill(s) only, repeatable
  --force               Remove existing installations before reinstalling
  -h, --help            Show this help message

Examples:
  ./scripts/update.sh skills/devops --system --force
  ./scripts/update.sh skills/base --system --skill anysearch --force
EOF
}

log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}  [OK]${NC}   $*"; }

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --system|--global) INSTALL_MODE="system"; shift ;;
            --project)         INSTALL_MODE="project"; shift ;;
            --agent)
                [[ $# -lt 2 ]] && { echo "Error: --agent requires a value" >&2; exit 1; }
                TARGET_AGENTS="$TARGET_AGENTS $2"; shift 2 ;;
            --skill)
                [[ $# -lt 2 ]] && { echo "Error: --skill requires a value" >&2; exit 1; }
                SELECTED_SKILLS="$SELECTED_SKILLS $2"; shift 2 ;;
            --force)  FORCE_UPDATE=true; shift ;;
            -h|--help) usage; exit 0 ;;
            -*)
                echo "Error: Unknown option $1" >&2; usage; exit 1 ;;
            *)
                if [[ -z "$SOURCE_PATH" ]]; then
                    SOURCE_PATH="$1"; shift
                else
                    echo "Error: Unexpected argument $1" >&2; usage; exit 1
                fi ;;
        esac
    done

    if [[ -z "$SOURCE_PATH" ]]; then
        echo "Error: Source path required" >&2; usage; exit 1
    fi

    if [[ ! "$SOURCE_PATH" = /* ]]; then
        SOURCE_PATH="$PROJECT_ROOT/$SOURCE_PATH"
    fi

    if [[ ! -d "$SOURCE_PATH" ]]; then
        echo "Error: Source directory not found: $SOURCE_PATH" >&2; exit 1
    fi

    TARGET_AGENTS="${TARGET_AGENTS:-$ALL_AGENTS}"
    TARGET_AGENTS="$(echo "$TARGET_AGENTS" | xargs)"

    for agent in $TARGET_AGENTS; do
        if ! is_valid_agent "$agent"; then
            echo "Error: Unknown agent '$agent'" >&2; exit 1
        fi
    done
}

do_update() {
    log_info "Updating skills from: $SOURCE_PATH"
    echo ""

    # Build common args
    local agent_args=""
    for agent in $TARGET_AGENTS; do
        agent_args="$agent_args --agent $agent"
    done

    local skill_args=""
    if [[ -n "$SELECTED_SKILLS" ]]; then
        for skill in $SELECTED_SKILLS; do
            skill_args="$skill_args --skill $skill"
        done
    fi

    if $FORCE_UPDATE; then
        log_info "Force mode: removing existing installations first..."

        # Find skills in source and remove them
        for skill_md in "$SOURCE_PATH"/*/SKILL.md "$SOURCE_PATH"/*/*/SKILL.md; do
            [[ -f "$skill_md" ]] || continue
            local skill_dir
            skill_dir="$(dirname "$skill_md")"
            local name
            name="$(basename "$skill_dir")"

            # Check if should update
            if [[ -n "$SELECTED_SKILLS" ]]; then
                local found=false
                for s in $SELECTED_SKILLS; do
                    [[ "$s" == "$name" ]] && found=true && break
                done
                $found || continue
            fi

            # Run remove
            "$SCRIPT_DIR/remove.sh" "$name" "--$INSTALL_MODE" $agent_args --keep-canonical 2>/dev/null || true
        done
        echo ""
    fi

    log_info "Installing updated skills..."
    "$SCRIPT_DIR/install.sh" "$SOURCE_PATH" "--$INSTALL_MODE" $agent_args $skill_args --no-symlink

    echo ""
    echo -e "${GREEN}Update complete!${NC}"
}

main() {
    parse_args "$@"
    do_update
}

main "$@"
