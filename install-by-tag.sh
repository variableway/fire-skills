#!/usr/bin/env bash
# Tag-Based Skill Installer (macOS / Linux)
# Scans skill category directories for matching tags and installs them.
#
# Usage: ./install-by-tag.sh <tag> [--system | --project] [--agent <name>] [--dir <skills-dir>]...
#
# Options:
#   <tag>           Tag to match (e.g., dev-workflow, github, workflow, analysis)
#   --system        Install to system skill directories
#   --project       Install to current project directory
#   --agent <name>  Target specific agent (claude-code, kimi, codex, opencode, trae, trae-solo, workbuddy)
#   --dir <path>    Skills category directory to scan (repeatable;
#                   defaults: ./dev ./analysis ./fe-skills ./backend-skills ./product)
#   -h, --help      Show this help message
#
# Examples:
#   ./install-by-tag.sh dev-workflow --system
#   ./install-by-tag.sh analysis --system
#   ./install-by-tag.sh github --project
#   ./install-by-tag.sh workflow --system --agent kimi
#   ./install-by-tag.sh repo --system --dir ./analysis
#   ./install-by-tag.sh github --system --agent trae
#   ./install-by-tag.sh dev-workflow --project --agent workbuddy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAG=""
INSTALL_MODE=""
TARGET_AGENT=""
SCAN_DIRS=()
DEFAULT_SCAN_DIRS=(
    "$SCRIPT_DIR/dev"
    "$SCRIPT_DIR/analysis"
    "$SCRIPT_DIR/fe-skills"
    "$SCRIPT_DIR/backend-skills"
    "$SCRIPT_DIR/product"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    cat <<EOF
Tag-Based Skill Installer (macOS / Linux)
Scans SKILL.md frontmatter for matching 'tags' field and installs matching skills.

Usage: ./install-by-tag.sh <tag> [--system | --project] [--agent <name>] [--dir <path>]...

Options:
  <tag>           Tag to match in skill frontmatter (e.g., dev-workflow, github, analysis)
  --system        Install to system directories (~/.claude/skills/, etc.)
  --project       Install to current project directory (./.trae/skills/, ./.workbuddy/skills/, etc.)
  --agent <name>  Target specific agent (claude-code, kimi, codex, opencode, trae, trae-solo, workbuddy)
  --dir <path>    Skills category directory to scan (repeatable; defaults:
                  ./dev ./analysis ./fe-skills ./backend-skills ./product)
  -h, --help      Show this help message

Examples:
  ./install-by-tag.sh dev-workflow --system
  ./install-by-tag.sh analysis --system
  ./install-by-tag.sh github --project
  ./install-by-tag.sh workflow --system --agent kimi
  ./install-by-tag.sh repo --system --dir ./analysis
  ./install-by-tag.sh github --system --agent trae
  ./install-by-tag.sh dev-workflow --project --agent workbuddy

Supported agents:
  claude-code  - Claude Code (~/.claude/skills/)
  kimi         - Kimi CLI (~/.kimi/skills/)
  codex        - Codex (~/.codex/skills/)
  opencode     - OpenCode (~/.opencode/skills/)
  trae         - Trae IDE (~/.trae/skills/)
  trae-solo    - Trae Solo mode (~/.trae/skills/)
  workbuddy    - WorkBuddy (~/.workbuddy/skills/)

Common tag values (from skill frontmatter):
  dev-workflow  - Dev workflow skills (under ./dev)
  github        - GitHub-related skills
  workflow      - Task/workflow automation
  research      - Research skills
  analysis      - Code repo / project analysis (under ./analysis)
  codegraph     - CodeGraph-aware skills
  repo          - Repo-level analyzers
  security      - Security skills
  ai            - AI configuration skills
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --system)
                INSTALL_MODE="system"
                shift
                ;;
            --project)
                INSTALL_MODE="project"
                shift
                ;;
            --agent)
                TARGET_AGENT="$2"
                shift 2
                ;;
            --dir)
                SCAN_DIRS+=("$2")
                shift 2
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
                if [ -z "$TAG" ]; then
                    TAG="$1"
                    shift
                else
                    echo -e "${RED}Error: Unknown argument $1${NC}" >&2
                    usage
                    exit 1
                fi
                ;;
        esac
    done

    if [ -z "$TAG" ]; then
        echo -e "${RED}Error: Must specify a tag${NC}" >&2
        usage
        exit 1
    fi

    if [ -z "$INSTALL_MODE" ]; then
        echo -e "${RED}Error: Must specify --system or --project${NC}" >&2
        usage
        exit 1
    fi

    if [ "${#SCAN_DIRS[@]}" -eq 0 ]; then
        SCAN_DIRS=("${DEFAULT_SCAN_DIRS[@]}")
    fi
}

# Parse tags from SKILL.md frontmatter (YAML)
# Returns space-separated list of tags
get_skill_tags() {
    local skill_md="$1"
    local in_frontmatter=false
    local in_tags=false
    local tags=""

    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if $in_frontmatter; then
                break
            else
                in_frontmatter=true
                continue
            fi
        fi

        if $in_frontmatter; then
            if [[ "$line" =~ ^tags: ]]; then
                in_tags=true
                # Handle inline array: tags: [a, b, c]
                if [[ "$line" =~ \[.*\] ]]; then
                    tags=$(echo "$line" | sed 's/.*\[\(.*\)\].*/\1/' | tr ',' ' ' | tr -d ' ')
                    in_tags=false
                fi
                continue
            fi

            if $in_tags; then
                if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.+) ]]; then
                    tags="$tags ${BASH_REMATCH[1]}"
                elif [[ "$line" =~ ^[a-z] ]]; then
                    # New key, end of tags
                    in_tags=false
                fi
            fi
        fi
    done < "$skill_md"

    echo "$tags"
}

# Get skill name from frontmatter
get_skill_name() {
    local skill_md="$1"
    local in_frontmatter=false

    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if $in_frontmatter; then
                break
            else
                in_frontmatter=true
                continue
            fi
        fi

        if $in_frontmatter && [[ "$line" =~ ^name:[[:space:]]*(.+) ]]; then
            echo "${BASH_REMATCH[1]}"
            return
        fi
    done < "$skill_md"

    # Fallback: use directory name
    basename "$(dirname "$skill_md")"
}

# Scan one or more directories for skills matching the tag
find_matching_skills() {
    local target_tag="$1"
    shift
    local matches=()

    for scan_dir in "$@"; do
        [ -d "$scan_dir" ] || continue
        for skill_md in "$scan_dir"/*/SKILL.md; do
            [ -f "$skill_md" ] || continue

            local tags
            tags=$(get_skill_tags "$skill_md")

            for tag in $tags; do
                if [[ "$tag" == "$target_tag" ]]; then
                    local skill_root
                    skill_root="$(dirname "$skill_md")"
                    local skill_name
                    skill_name="$(basename "$skill_root")"
                    matches+=("$skill_name:$skill_root")
                    break
                fi
            done
        done
    done

    echo "${matches[@]}"
}

# Supported agents: claude-code, kimi, codex, opencode, trae, trae-solo
get_system_target_dirs() {
    local dirs=()
    case "$TARGET_AGENT" in
        "")
            dirs+=("$HOME/.config/agents/skills")
            dirs+=("$HOME/.claude/skills")
            dirs+=("$HOME/.kimi/skills")
            dirs+=("$HOME/.codex/skills")
            dirs+=("$HOME/.opencode/skills")
            dirs+=("$HOME/.trae/skills")
            dirs+=("$HOME/.workbuddy/skills")
            ;;
        claude-code)
            dirs+=("$HOME/.claude/skills")
            ;;
        kimi)
            dirs+=("$HOME/.kimi/skills")
            dirs+=("$HOME/.config/agents/skills")
            ;;
        codex)
            dirs+=("$HOME/.codex/skills")
            ;;
        opencode)
            dirs+=("$HOME/.opencode/skills")
            ;;
        trae)
            dirs+=("$HOME/.trae/skills")
            ;;
        trae-solo)
            dirs+=("$HOME/.trae/skills")
            ;;
        workbuddy)
            dirs+=("$HOME/.workbuddy/skills")
            ;;
        *)
            echo -e "${RED}Error: Unknown agent '$TARGET_AGENT'${NC}" >&2
            echo "Supported agents: claude-code, kimi, codex, opencode, trae, trae-solo, workbuddy" >&2
            exit 1
            ;;
    esac
    echo "${dirs[@]}"
}

get_project_target_dirs() {
    local dirs=()
    dirs+=("./.agents/skills")
    dirs+=("./.kimi/skills")
    dirs+=("./.claude/skills")
    dirs+=("./.trae/skills")
    dirs+=("./.workbuddy/skills")
    echo "${dirs[@]}"
}

install_skill_to_dir() {
    local skill_name="$1"
    local skill_root="$2"
    local target_dir="$3"
    local link_path="$target_dir/$skill_name"

    mkdir -p "$target_dir"

    if [ -e "$link_path" ] || [ -L "$link_path" ]; then
        echo -e "${YELLOW}  [SKIP]${NC} $skill_name already exists at $link_path"
        return 1
    fi

    ln -s "$skill_root" "$link_path"
    echo -e "${GREEN}  [OK]${NC}   $skill_name -> $link_path"
    return 0
}

install_skill() {
    local skill_name="$1"
    local skill_root="$2"

    echo -e "${BLUE}Installing $skill_name...${NC}"

    local target_dirs
    if [ "$INSTALL_MODE" = "system" ]; then
        target_dirs=($(get_system_target_dirs))
    else
        target_dirs=($(get_project_target_dirs))
    fi

    local installed=0
    local skipped=0

    for target_dir in "${target_dirs[@]}"; do
        if install_skill_to_dir "$skill_name" "$skill_root" "$target_dir"; then
            ((installed++)) || true
        else
            ((skipped++)) || true
        fi
    done

    echo -e "  ${GREEN}Installed: $installed, Skipped: $skipped${NC}"
}

main() {
    parse_args "$@"

    echo -e "${BLUE}Scanning for skills with tag: ${CYAN}$TAG${NC}"
    echo -e "${BLUE}Scan directories:${NC}"
    for d in "${SCAN_DIRS[@]}"; do
        if [ -d "$d" ]; then
            echo -e "  - $d"
        else
            echo -e "  - $d ${YELLOW}(missing, skipped)${NC}"
        fi
    done
    echo ""

    # Find matching skills across all scan dirs
    local matches
    matches=$(find_matching_skills "$TAG" "${SCAN_DIRS[@]}")

    if [ -z "$matches" ]; then
        echo -e "${YELLOW}No skills found with tag '$TAG'${NC}"
        echo ""
        echo "Available skills and tags:"
        for scan_dir in "${SCAN_DIRS[@]}"; do
            [ -d "$scan_dir" ] || continue
            for skill_md in "$scan_dir"/*/SKILL.md; do
                [ -f "$skill_md" ] || continue
                local name
                name=$(get_skill_name "$skill_md")
                local tags
                tags=$(get_skill_tags "$skill_md")
                if [ -n "$tags" ]; then
                    echo -e "  ${CYAN}$name${NC} ($(basename "$scan_dir")): $tags"
                fi
            done
        done
        exit 1
    fi

    # Count matches
    local count=0
    for match in $matches; do
        ((count++)) || true
    done

    echo -e "${GREEN}Found $count skill(s) with tag '$TAG':${NC}"
    for match in $matches; do
        local name="${match%%:*}"
        echo -e "  - ${CYAN}$name${NC}"
    done
    echo ""

    # Install each matching skill
    for match in $matches; do
        local name="${match%%:*}"
        local root="${match#*:}"
        install_skill "$name" "$root"
        echo ""
    done

    echo -e "${GREEN}Tag-based installation complete!${NC}"
}

main "$@"
