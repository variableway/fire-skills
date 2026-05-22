#!/usr/bin/env bash
# Dev Workflow Combined Installer (macOS / Linux)
# Installs all dev-workflow related skills: github-cli-skill, gh-create-release, git-workflow, local-workflow
#
# Usage: ./dev-workflow-install.sh [--system | --project] [--agent <name>] [--hooks]
#
# Options:
#   --system        Install to system skill directories (default: ~/.config/agents/skills/)
#   --project       Install to current project directory (./.agents/skills/)
#   --agent <name>  Target specific agent (claude-code, kimi, codex, opencode)
#   --hooks         Also install git hooks (git-workflow only)
#   -h, --help      Show this help message
#
# Examples:
#   ./dev-workflow-install.sh --system
#   ./dev-workflow-install.sh --system --agent kimi
#   ./dev-workflow-install.sh --project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_MODE=""
TARGET_AGENT=""
INSTALL_HOOKS=false

# Skills to install (relative to SCRIPT_DIR)
SKILLS=(
    "github-cli-skill"
    "gh-create-release"
    "git-workflow"
    "local-workflow"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Dev Workflow Combined Installer (macOS / Linux)
Installs: ${SKILLS[*]}

Usage: ./dev-workflow-install.sh [--system | --project] [--agent <name>] [--hooks]

Options:
  --system        Install to system directories (~/.config/agents/skills/)
  --project       Install to current project directory (./.agents/skills/)
  --agent <name>  Target specific agent (claude-code, kimi, codex, opencode)
  --hooks         Also install git hooks (git-workflow only)
  -h, --help      Show this help message

Examples:
  ./dev-workflow-install.sh --system
  ./dev-workflow-install.sh --system --agent kimi
  ./dev-workflow-install.sh --project
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
            --hooks)
                INSTALL_HOOKS=true
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
        esac
    done
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

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
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
                sudo apt-get update
                sudo apt-get install -y gh
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y gh
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm github-cli
            elif command -v zypper &>/dev/null; then
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
    local skill_root="$SCRIPT_DIR/$skill_name"

    if [ ! -d "$skill_root" ]; then
        echo -e "${RED}  [ERROR]${NC} Skill directory not found: $skill_root"
        return 1
    fi

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

install_git_hooks() {
    local git_workflow_root="$SCRIPT_DIR/git-workflow"

    if [ ! -d "$git_workflow_root/hooks" ]; then
        echo -e "${YELLOW}  [SKIP] git-workflow hooks not found${NC}"
        return
    fi

    echo -e "${BLUE}Installing git hooks...${NC}"

    if [ ! -d ".git/hooks" ]; then
        echo -e "${YELLOW}Warning: Not a git repository or .git/hooks not found.${NC}"
        return
    fi

    for hook in prepare-commit-msg post-commit; do
        local src="$git_workflow_root/hooks/$hook"
        local dst=".git/hooks/$hook"
        if [ -f "$src" ]; then
            if [ -e "$dst" ] && [ ! -L "$dst" ]; then
                echo -e "${YELLOW}  [SKIP]${NC} $dst already exists (not overwriting)"
            else
                cp "$src" "$dst"
                chmod +x "$dst"
                echo -e "${GREEN}  [OK]${NC}   $dst"
            fi
        fi
    done
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
    echo -e "${BLUE}Skills to install: ${SKILLS[*]}${NC}"
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

    for skill in "${SKILLS[@]}"; do
        install_skill "$skill"
        echo ""
    done

    if $INSTALL_HOOKS && [ "$INSTALL_MODE" = "project" ]; then
        install_git_hooks
        echo ""
    fi

    echo -e "${GREEN}Dev workflow installation complete!${NC}"
    echo "Skills installed: ${SKILLS[*]}"
}

main "$@"
