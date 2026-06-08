#!/usr/bin/env bash
# Unified Skill Remover (macOS / Linux / WSL2)
# Removes skills from agent directories and canonical storage.
#
# Usage: ./scripts/remove.sh <skill-name> [OPTIONS]
#
# Options:
#   --system              Remove from system directories (default)
#   --project             Remove from project directories
#   --global              Alias for --system
#   --agent <name>        Target agent(s), repeatable (default: all)
#   --keep-canonical      Don't remove from canonical storage
#   --dry-run             Show what would be removed
#   -h, --help            Show this help message
#
# Examples:
#   ./scripts/remove.sh git-workflow --system
#   ./scripts/remove.sh anysearch --project --agent claude-code
#   ./scripts/remove.sh git-workflow --system --dry-run

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SPARK_HOME="${SKILL_SPARK_HOME:-$HOME/.skill-spark}"
CANONICAL_DIR="$SKILL_SPARK_HOME/.agents/skills"

SKILL_NAME=""
INSTALL_MODE="system"
TARGET_AGENTS=""
KEEP_CANONICAL=false
DRY_RUN=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ALL_AGENTS="claude-code kimi codex opencode trae trae-solo workbuddy"

get_system_target() {
    case "$1" in
        claude-code) echo "$HOME/.claude/skills" ;;
        kimi)        echo "$HOME/.kimi/skills" ;;
        codex)       echo "$HOME/.codex/skills" ;;
        opencode)    echo "$HOME/.opencode/skills" ;;
        trae)        echo "$HOME/.trae/skills" ;;
        trae-solo)   echo "$HOME/.trae/skills" ;;
        workbuddy)   echo "$HOME/.workbuddy/skills" ;;
        *)           echo ""; return 1 ;;
    esac
}

get_project_target() {
    case "$1" in
        claude-code) echo ".claude/skills" ;;
        kimi)        echo ".kimi/skills" ;;
        codex)       echo ".codex/skills" ;;
        opencode)    echo ".opencode/skills" ;;
        trae)        echo ".trae/skills" ;;
        trae-solo)   echo ".trae/skills" ;;
        workbuddy)   echo ".workbuddy/skills" ;;
        common)      echo ".agents/skills" ;;
        *)           echo ""; return 1 ;;
    esac
}

is_valid_agent() {
    case "$1" in
        claude-code|kimi|codex|opencode|trae|trae-solo|workbuddy) return 0 ;;
        *) return 1 ;;
    esac
}

usage() {
    cat <<'EOF'
Unified Skill Remover (macOS / Linux / WSL2)
Removes skills from agent directories and canonical storage.

Usage: ./scripts/remove.sh <skill-name> [OPTIONS]

Options:
  --system              Remove from system directories (default)
  --project             Remove from project directories
  --global              Alias for --system
  --agent <name>        Target agent(s), repeatable (default: all)
  --keep-canonical      Don't remove from canonical storage
  --dry-run             Show what would be removed without deleting
  -h, --help            Show this help message

Examples:
  ./scripts/remove.sh git-workflow --system
  ./scripts/remove.sh anysearch --project --agent claude-code
  ./scripts/remove.sh git-workflow --system --dry-run
EOF
}

log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}  [OK]${NC}   $*"; }
log_skip()  { echo -e "${YELLOW}  [SKIP]${NC} $*"; }
log_dry()   { echo -e "${YELLOW}  [DRY]${NC}  would remove: $*"; }
log_detail(){ echo -e "         $*"; }

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --system|--global) INSTALL_MODE="system"; shift ;;
            --project)         INSTALL_MODE="project"; shift ;;
            --agent)
                [[ $# -lt 2 ]] && { echo "Error: --agent requires a value" >&2; exit 1; }
                TARGET_AGENTS="$TARGET_AGENTS $2"; shift 2 ;;
            --keep-canonical) KEEP_CANONICAL=true; shift ;;
            --dry-run)        DRY_RUN=true; shift ;;
            -h|--help)        usage; exit 0 ;;
            -*)
                echo "Error: Unknown option $1" >&2; usage; exit 1 ;;
            *)
                if [[ -z "$SKILL_NAME" ]]; then
                    SKILL_NAME="$1"; shift
                else
                    echo "Error: Unexpected argument $1" >&2; usage; exit 1
                fi ;;
        esac
    done

    if [[ -z "$SKILL_NAME" ]]; then
        echo "Error: Skill name required" >&2; usage; exit 1
    fi

    TARGET_AGENTS="${TARGET_AGENTS:-$ALL_AGENTS}"
    TARGET_AGENTS="$(echo "$TARGET_AGENTS" | xargs)"

    for agent in $TARGET_AGENTS; do
        if ! is_valid_agent "$agent"; then
            echo "Error: Unknown agent '$agent'" >&2; exit 1
        fi
    done
}

remove_path() {
    local path="$1"
    local label="$2"

    if [[ ! -e "$path" ]] && [[ ! -L "$path" ]]; then
        log_skip "$label (not found)"
        return 0
    fi

    if $DRY_RUN; then
        log_dry "$label -> $path"
        return 0
    fi

    rm -rf "$path"
    log_ok "Removed $label"
    log_detail "$path"
}

do_remove() {
    local mode_label="system"
    [[ "$INSTALL_MODE" == "project" ]] && mode_label="project"

    if $DRY_RUN; then
        echo -e "${YELLOW}=== DRY RUN ===${NC}"
    fi

    log_info "Removing '$SKILL_NAME' from $mode_label directories..."
    echo ""

    for agent in $TARGET_AGENTS; do
        local agent_dir
        if [[ "$INSTALL_MODE" == "system" ]]; then
            agent_dir="$(get_system_target "$agent")"
        else
            agent_dir="$(get_project_target "$agent")"
        fi
        remove_path "$agent_dir/$SKILL_NAME" "$agent"
    done

    # Remove from canonical storage
    if ! $KEEP_CANONICAL && [[ "$INSTALL_MODE" == "system" ]]; then
        echo ""
        remove_path "$CANONICAL_DIR/$SKILL_NAME" "canonical storage"
    fi

    echo ""
    if $DRY_RUN; then
        log_info "Dry run complete. No files were deleted."
    else
        echo -e "${GREEN}Removal complete.${NC}"
    fi
}

main() {
    parse_args "$@"
    do_remove
}

main "$@"
