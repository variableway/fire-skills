#!/usr/bin/env bash
# GitHub CLI Skill Installer (macOS / Linux)
# Usage: ./install.sh [--system | --project] [--agent <name>]
#
# Options:
#   --system        Install to system skill directories (default: ~/.config/agents/skills/)
#   --project       Install to current project directory (./.agents/skills/)
#   --agent <name>  Target specific agent (claude-code, kimi, codex, opencode)
#   -h, --help      Show this help message
#
# Examples:
#   ./install.sh --system                     # Install to all system agent dirs
#   ./install.sh --system --agent kimi        # Install to kimi system dir only
#   ./install.sh --project                    # Install to current project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_NAME="$(basename "$SKILL_ROOT")"
SKILL_SPARK_HOME="${SKILL_SPARK_HOME:-$HOME/.skill-spark}"
CANONICAL_DIR="$SKILL_SPARK_HOME/.agents/skills"
INSTALL_MODE=""
TARGET_AGENT=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    sed -n '/^# GitHub CLI Skill Installer/,/^# Examples:/p' "$0" | sed 's/^# //'
    echo ""
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
                echo -e "${RED}Error: Unknown argument $1${NC}" >&2
                usage
                exit 1
                ;;
        esac
    done
}

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

check_gh() {
    if command -v gh &>/dev/null; then
        local version
        version="$(gh --version | head -n1)"
        echo -e "${GREEN}[OK]${NC} GitHub CLI found: $version"
        return 0
    else
        echo -e "${YELLOW}[WARN]${NC} GitHub CLI (gh) is not installed."
        return 1
    fi
}

install_gh() {
    local os="$1"
    echo -e "${BLUE}Installing GitHub CLI...${NC}"
    case "$os" in
        macos)
            if command -v brew &>/dev/null; then
                brew install gh
            else
                echo -e "${RED}Error: Homebrew is required to install gh on macOS.${NC}" >&2
                echo "Please install Homebrew first: https://brew.sh" >&2
                exit 1
            fi
            ;;
        linux)
            if command -v apt-get &>/dev/null; then
                # Debian/Ubuntu
                sudo apt-get update
                sudo apt-get install -y gh
            elif command -v dnf &>/dev/null; then
                # Fedora/RHEL
                sudo dnf install -y gh
            elif command -v pacman &>/dev/null; then
                # Arch
                sudo pacman -S --noconfirm github-cli
            elif command -v zypper &>/dev/null; then
                # openSUSE
                sudo zypper install -y gh
            else
                echo -e "${RED}Error: Unable to auto-install gh. Please install manually:${NC}" >&2
                echo "  https://github.com/cli/cli#installation" >&2
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}Error: Unsupported OS. Please install gh manually:${NC}" >&2
            echo "  https://github.com/cli/cli#installation" >&2
            exit 1
            ;;
    esac
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
        *)
            echo -e "${RED}Error: Unknown agent '$TARGET_AGENT'${NC}" >&2
            echo "Supported agents: claude-code, kimi, codex, opencode" >&2
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
    echo "${dirs[@]}"
}

copy_to_canonical() {
    local source="$1"
    local name="$2"
    local target="$CANONICAL_DIR/$name"

    if [[ -d "$target" ]]; then
        rm -rf "$target"
    fi
    mkdir -p "$target"

    for entry in "$source"/*; do
        local b
        b="$(basename "$entry")"
        case "$b" in .git|node_modules|__pycache__|.DS_Store|.env|.env.local) continue ;; esac
        cp -R "$entry" "$target/"
    done
    for entry in "$source"/.*; do
        [[ -e "$entry" ]] || continue
        local b
        b="$(basename "$entry")"
        case "$b" in .|..|.git|.env|.env.local|.DS_Store) continue ;; esac
        cp -R "$entry" "$target/" 2>/dev/null || true
    done
}

install_skill_to_dir() {
    local target_dir="$1"
    local link_path="$target_dir/$SKILL_NAME"

    mkdir -p "$target_dir"

    if [ -e "$link_path" ] || [ -L "$link_path" ]; then
        echo -e "${YELLOW}  [SKIP]${NC} $SKILL_NAME already exists at $link_path"
        return 1
    fi

    # Copy to canonical storage first, then symlink from there
    copy_to_canonical "$SKILL_ROOT" "$SKILL_NAME"
    ln -s "$CANONICAL_DIR/$SKILL_NAME" "$link_path"
    echo -e "${GREEN}  [OK]${NC}   $SKILL_NAME -> $link_path"
    return 0
}

install_system() {
    echo -e "${BLUE}Installing $SKILL_NAME to system directories...${NC}"
    local target_dirs=($(get_system_target_dirs))
    local installed=0
    local skipped=0

    for target_dir in "${target_dirs[@]}"; do
        if install_skill_to_dir "$target_dir"; then
            ((installed++)) || true
        else
            ((skipped++)) || true
        fi
    done

    echo ""
    echo -e "${GREEN}System installation complete.${NC}"
    echo "  Installed: $installed"
    echo "  Skipped: $skipped"
}

install_project() {
    echo -e "${BLUE}Installing $SKILL_NAME to project directories...${NC}"

    if [ ! -d ".git" ]; then
        echo -e "${YELLOW}Warning: Current directory is not a git repository.${NC}"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    local target_dirs=($(get_project_target_dirs))
    local installed=0
    local skipped=0

    for target_dir in "${target_dirs[@]}"; do
        if install_skill_to_dir "$target_dir"; then
            ((installed++)) || true
        else
            ((skipped++)) || true
        fi
    done

    echo ""
    echo -e "${GREEN}Project installation complete.${NC}"
    echo "  Installed: $installed"
    echo "  Skipped: $skipped"
}

main() {
    parse_args "$@"

    if [ -z "$INSTALL_MODE" ]; then
        echo -e "${RED}Error: Must specify --system or --project${NC}" >&2
        usage
        exit 1
    fi

    local os
    os=$(detect_os)
    echo -e "${BLUE}Detected OS: $os${NC}"
    echo ""

    if ! check_gh; then
        read -p "Install GitHub CLI (gh) now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_gh "$os"
        else
            echo -e "${YELLOW}Skipping gh installation. Some features may not work.${NC}"
        fi
    fi

    echo ""
    case "$INSTALL_MODE" in
        system)
            install_system
            ;;
        project)
            install_project
            ;;
    esac

    echo ""
    echo "Skill installed: $SKILL_NAME"
}

main "$@"
