#!/usr/bin/env bash
# Python UV Env Skill Installer (macOS / Linux)
# Usage: ./install.sh [--system | --project] [--agent <name>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_NAME="$(basename "$SKILL_ROOT")"
INSTALL_MODE=""
TARGET_AGENT=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Python UV Env Skill Installer (macOS / Linux)
Usage: ./install.sh [--system | --project] [--agent <name>]

Options:
  --system        Install to system directories
  --project       Install to current project directory
  --agent <name>  Target specific agent (claude-code, kimi, codex, opencode, trae, trae-solo)
  -h, --help      Show this help message

Examples:
  ./install.sh --system
  ./install.sh --system --agent trae
  ./install.sh --project
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --system) INSTALL_MODE="system"; shift ;;
            --project) INSTALL_MODE="project"; shift ;;
            --agent) TARGET_AGENT="$2"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            -*) echo -e "${RED}Error: Unknown option $1${NC}" >&2; usage; exit 1 ;;
        esac
    done
}

check_deps() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    if ! command -v uv &>/dev/null; then
        echo -e "${YELLOW}[WARN]${NC} uv not found."
        echo "  Install: brew install uv (macOS) or curl -LsSf https://astral.sh/uv/install.sh | sh (Linux)"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    else
        echo -e "${GREEN}[OK]${NC} uv $(uv --version)"
    fi
}

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
            ;;
        claude-code) dirs+=("$HOME/.claude/skills") ;;
        kimi) dirs+=("$HOME/.kimi/skills" "$HOME/.config/agents/skills") ;;
        codex) dirs+=("$HOME/.codex/skills") ;;
        opencode) dirs+=("$HOME/.opencode/skills") ;;
        trae|trae-solo) dirs+=("$HOME/.trae/skills") ;;
        *) echo -e "${RED}Error: Unknown agent '$TARGET_AGENT'${NC}" >&2; exit 1 ;;
    esac
    echo "${dirs[@]}"
}

get_project_target_dirs() {
    echo "./.agents/skills ./.kimi/skills ./.claude/skills"
}

install_skill_to_dir() {
    local target_dir="$1"
    local link_path="$target_dir/$SKILL_NAME"
    mkdir -p "$target_dir"
    if [ -e "$link_path" ] || [ -L "$link_path" ]; then
        echo -e "${YELLOW}  [SKIP]${NC} $SKILL_NAME already exists at $link_path"
        return 1
    fi
    ln -s "$SKILL_ROOT" "$link_path"
    echo -e "${GREEN}  [OK]${NC}   $SKILL_NAME -> $link_path"
    return 0
}

install_system() {
    echo -e "${BLUE}Installing $SKILL_NAME to system directories...${NC}"
    local target_dirs=($(get_system_target_dirs))
    local installed=0 skipped=0
    for target_dir in "${target_dirs[@]}"; do
        if install_skill_to_dir "$target_dir"; then ((installed++)) || true; else ((skipped++)) || true; fi
    done
    echo -e "\n${GREEN}System installation complete.${NC}\n  Installed: $installed\n  Skipped: $skipped"
}

install_project() {
    echo -e "${BLUE}Installing $SKILL_NAME to project directories...${NC}"
    if [ ! -d ".git" ]; then
        echo -e "${YELLOW}Warning: Not a git repository.${NC}"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo; [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi
    local target_dirs=($(get_project_target_dirs))
    local installed=0 skipped=0
    for target_dir in "${target_dirs[@]}"; do
        if install_skill_to_dir "$target_dir"; then ((installed++)) || true; else ((skipped++)) || true; fi
    done
    echo -e "\n${GREEN}Project installation complete.${NC}\n  Installed: $installed\n  Skipped: $skipped"
}

main() {
    parse_args "$@"
    if [ -z "$INSTALL_MODE" ]; then
        echo -e "${RED}Error: Must specify --system or --project${NC}" >&2
        usage; exit 1
    fi
    echo -e "${BLUE}Detected OS: $(uname -s)${NC}\n"
    check_deps
    echo ""
    case "$INSTALL_MODE" in
        system) install_system ;;
        project) install_project ;;
    esac
    echo -e "\nSkill installed: $SKILL_NAME"
}

main "$@"
