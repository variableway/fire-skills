#!/usr/bin/env bash
# Clean up global AI Agent Skills
# Usage: ./clean-skills.sh [OPTIONS]
#
# Options:
#   --all           Clean all agent skills (default)
#   --agent <name>  Clean specific agent (claude-code, kimi, codex, opencode, trae, trae-solo, workbuddy)
#   --dry-run       Show what would be deleted without actually deleting
#   --list          List all skill directories that would be cleaned
#   -h, --help      Show this help message

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
LIST_ONLY=false
TARGET_AGENT=""
CLEAN_ALL=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print usage
usage() {
    sed -n '/^# Usage:/,/^$/p' "$0" | sed 's/^# //'
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                CLEAN_ALL=true
                shift
                ;;
            --agent)
                TARGET_AGENT="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --list)
                LIST_ONLY=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                echo -e "${RED}Error: Unknown option $1${NC}" >&2
                usage
                exit 1
                ;;
            *)
                echo -e "${RED}Error: Unexpected argument $1${NC}" >&2
                usage
                exit 1
                ;;
        esac
    done

    # Default to --all if no specific agent specified
    if [[ -z "$TARGET_AGENT" ]] && [[ "$CLEAN_ALL" == false ]]; then
        CLEAN_ALL=true
    fi
}

# Get skill directories for each agent
get_claude_skills_dir() {
    echo "$HOME/.claude/skills"
}

get_kimi_skills_dir() {
    echo "$HOME/.kimi/skills"
}

get_codex_skills_dir() {
    echo "$HOME/.codex/skills"
}

get_opencode_skills_dir() {
    echo "$HOME/.opencode/skills"
}

get_trae_skills_dir() {
    echo "$HOME/.trae/skills"
}

get_workbuddy_skills_dir() {
    echo "$HOME/.workbuddy/skills"
}

get_common_skills_dir() {
    echo "$HOME/.config/agents/skills"
}

# List skills in a directory
list_skills_in_dir() {
    local dir="$1"
    local agent_name="$2"

    if [[ ! -d "$dir" ]]; then
        return
    fi

    local skills=()
    for item in "$dir"/*; do
        if [[ -L "$item" ]] || [[ -d "$item" ]]; then
            if [[ -f "$item/SKILL.md" ]] || [[ -d "$item/skills" ]] || [[ -L "$item" ]]; then
                skills+=("$(basename "$item")")
            fi
        fi
    done

    if [[ ${#skills[@]} -gt 0 ]]; then
        echo -e "${BLUE}$agent_name${NC}: $dir"
        for skill in "${skills[@]}"; do
            local full_path="$dir/$skill"
            if [[ -L "$full_path" ]]; then
                local target=$(readlink "$full_path")
                echo "  📎 $skill -> $target"
            else
                echo "  📁 $skill"
            fi
        done
        echo ""
    fi
}

# Clean skills in a directory
clean_skills_in_dir() {
    local dir="$1"
    local agent_name="$2"

    if [[ ! -d "$dir" ]]; then
        return 0
    fi

    local count=0
    for item in "$dir"/*; do
        if [[ -L "$item" ]] || [[ -d "$item" ]]; then
            if [[ -f "$item/SKILL.md" ]] || [[ -d "$item/skills" ]] || [[ -L "$item" ]]; then
                count=$((count + 1))
                if [[ "$DRY_RUN" == true ]]; then
                    echo -e "  ${YELLOW}[DRY-RUN]${NC} Would delete: $item"
                else
                    rm -rf "$item"
                    echo -e "  ${GREEN}✓${NC} Deleted: $(basename "$item")"
                fi
            fi
        fi
    done

    if [[ $count -eq 0 ]]; then
        echo -e "  ${YELLOW}No skills found${NC}"
    fi

    return 0
}

# Main list function
list_skills() {
    echo -e "${BLUE}=== AI Agent Skills ===${NC}"
    echo ""

    list_skills_in_dir "$(get_claude_skills_dir)" "Claude Code"
    list_skills_in_dir "$(get_kimi_skills_dir)" "Kimi CLI"
    list_skills_in_dir "$(get_codex_skills_dir)" "Codex CLI"
    list_skills_in_dir "$(get_opencode_skills_dir)" "OpenCode"
    list_skills_in_dir "$(get_trae_skills_dir)" "Trae"
    list_skills_in_dir "$(get_workbuddy_skills_dir)" "WorkBuddy"
    list_skills_in_dir "$(get_common_skills_dir)" "Common"
}

# Clean specific agent
clean_agent() {
    local agent_name="$1"
    local skills_dir=""

    case "$agent_name" in
        claude-code)
            skills_dir=$(get_claude_skills_dir)
            ;;
        kimi)
            skills_dir=$(get_kimi_skills_dir)
            ;;
        codex)
            skills_dir=$(get_codex_skills_dir)
            ;;
        opencode)
            skills_dir=$(get_opencode_skills_dir)
            ;;
        trae)
            skills_dir=$(get_trae_skills_dir)
            ;;
        trae-solo)
            skills_dir=$(get_trae_skills_dir)
            ;;
        workbuddy)
            skills_dir=$(get_workbuddy_skills_dir)
            ;;
        *)
            echo -e "${RED}Error: Unknown agent '$agent_name'${NC}" >&2
            echo "Supported agents: claude-code, kimi, codex, opencode, trae, trae-solo, workbuddy" >&2
            return 1
            ;;
    esac

    echo -e "${BLUE}Cleaning $agent_name skills...${NC}"
    clean_skills_in_dir "$skills_dir" "$agent_name"
}

# Clean all agents
clean_all() {
    echo -e "${BLUE}=== Cleaning All Agent Skills ===${NC}"
    echo ""

    echo -e "${BLUE}Claude Code:${NC}"
    clean_skills_in_dir "$(get_claude_skills_dir)" "Claude Code"
    echo ""

    echo -e "${BLUE}Kimi CLI:${NC}"
    clean_skills_in_dir "$(get_kimi_skills_dir)" "Kimi CLI"
    echo ""

    echo -e "${BLUE}Codex CLI:${NC}"
    clean_skills_in_dir "$(get_codex_skills_dir)" "Codex CLI"
    echo ""

    echo -e "${BLUE}OpenCode:${NC}"
    clean_skills_in_dir "$(get_opencode_skills_dir)" "OpenCode"
    echo ""

    echo -e "${BLUE}Trae:${NC}"
    clean_skills_in_dir "$(get_trae_skills_dir)" "Trae"
    echo ""

    echo -e "${BLUE}WorkBuddy:${NC}"
    clean_skills_in_dir "$(get_workbuddy_skills_dir)" "WorkBuddy"
    echo ""

    echo -e "${BLUE}Common:${NC}"
    clean_skills_in_dir "$(get_common_skills_dir)" "Common"
}

# Main function
main() {
    parse_args "$@"

    if [[ "$LIST_ONLY" == true ]]; then
        list_skills
        exit 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}=== DRY RUN MODE ===${NC}"
        echo "No files will actually be deleted"
        echo ""
    fi

    if [[ -n "$TARGET_AGENT" ]]; then
        clean_agent "$TARGET_AGENT"
    else
        clean_all
    fi

    echo ""
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}Dry run complete. No files were deleted.${NC}"
    else
        echo -e "${GREEN}Cleanup complete.${NC}"
    fi
}

main "$@"
