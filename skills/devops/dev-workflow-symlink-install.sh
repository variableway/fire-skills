#!/usr/bin/env bash
# Dev Workflow Symlink Installer (macOS / Linux)
# Installs all dev-workflow skills via symlinks: github-cli-skill, gh-create-release, git-workflow, local-workflow, scanning-for-secrets
#
# Usage: ./dev-workflow-symlink-install.sh [--system | --project] [--agent <name>]
#
# Options:
#   --system          Install to system skill directories
#   --project         Install to current project directory
#   --agent <name>    Target specific agent (claude-code, kimi, codex, opencode, trae)
#                     If omitted, installs to all supported agents.
#   --hooks           Also install git hooks (git-workflow only, project mode only)
#   -h, --help        Show this help message
#
# Examples:
#   ./dev-workflow-symlink-install.sh --system
#   ./dev-workflow-symlink-install.sh --system --agent trae
#   ./dev-workflow-symlink-install.sh --project
#   ./dev-workflow-symlink-install.sh --project --hooks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_MODE=""
TARGET_AGENT=""
INSTALL_HOOKS=false

SKILLS=(
    "github-cli-skill"
    "gh-create-release"
    "git-workflow"
    "local-workflow"
    "scanning-for-secrets"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Dev Workflow Symlink Installer (macOS / Linux)
Installs via symlinks: ${SKILLS[*]}

Usage: ./dev-workflow-symlink-install.sh [--system | --project] [--agent <name>] [--hooks]

Options:
  --system          Install to system directories
  --project         Install to current project directory
  --agent <name>    Target specific agent (claude-code, kimi, codex, opencode, trae)
  --hooks           Also install git hooks (git-workflow only)
  -h, --help        Show this help message

Examples:
  ./dev-workflow-symlink-install.sh --system
  ./dev-workflow-symlink-install.sh --system --agent trae
  ./dev-workflow-symlink-install.sh --project
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

# Map agent name to system-level skill directories
get_system_target_dirs() {
    case "$TARGET_AGENT" in
        "")
            echo "$HOME/.config/agents/skills"
            echo "$HOME/.claude/skills"
            echo "$HOME/.codex/skills"
            echo "$HOME/.config/opencode/skills"
            echo "$HOME/.trae/skills"
            ;;
        claude-code)
            echo "$HOME/.claude/skills"
            ;;
        kimi)
            echo "$HOME/.config/agents/skills"
            ;;
        codex)
            echo "$HOME/.codex/skills"
            ;;
        opencode)
            echo "$HOME/.config/opencode/skills"
            ;;
        trae)
            echo "$HOME/.trae/skills"
            ;;
        *)
            echo -e "${RED}Error: Unknown agent '$TARGET_AGENT'${NC}" >&2
            echo "Supported agents: claude-code, kimi, codex, opencode, trae" >&2
            exit 1
            ;;
    esac
}

get_project_target_dirs() {
    echo "./.agents/skills"
    echo "./.kimi/skills"
    echo "./.claude/skills"
    echo "./.trae/skills"
}

install_skill_symlink() {
    local skill_name="$1"
    local skill_source="$SCRIPT_DIR/$skill_name"
    local target_dir="$2"
    local link_path="$target_dir/$skill_name"

    if [ ! -d "$skill_source" ]; then
        echo -e "${RED}  [ERROR]${NC} Skill source not found: $skill_source"
        return 1
    fi

    mkdir -p "$target_dir"

    # Remove existing symlink or directory at target
    if [ -L "$link_path" ]; then
        local existing_target
        existing_target="$(readlink "$link_path")"
        if [ "$existing_target" = "$skill_source" ]; then
            echo -e "${GREEN}  [OK]${NC}   $skill_name already linked -> $link_path"
            return 0
        else
            echo -e "${YELLOW}  [REPLACE]${NC} $skill_name was linked to $existing_target, updating..."
            rm "$link_path"
        fi
    elif [ -e "$link_path" ]; then
        echo -e "${YELLOW}  [SKIP]${NC} $link_path exists and is not a symlink (manual install?)"
        return 1
    fi

    ln -s "$skill_source" "$link_path"
    echo -e "${GREEN}  [OK]${NC}   $skill_name -> $link_path"
    return 0
}

install_skill() {
    local skill_name="$1"
    echo -e "${BLUE}Installing $skill_name...${NC}"

    local target_dirs
    if [ "$INSTALL_MODE" = "system" ]; then
        mapfile -t target_dirs < <(get_system_target_dirs)
    else
        mapfile -t target_dirs < <(get_project_target_dirs)
    fi

    local installed=0
    local skipped=0

    for target_dir in "${target_dirs[@]}"; do
        if install_skill_symlink "$skill_name" "$target_dir"; then
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

verify_install() {
    echo ""
    echo -e "${BLUE}Verifying installation...${NC}"

    local target_dirs
    if [ "$INSTALL_MODE" = "system" ]; then
        mapfile -t target_dirs < <(get_system_target_dirs)
    else
        mapfile -t target_dirs < <(get_project_target_dirs)
    fi

    for target_dir in "${target_dirs[@]}"; do
        if [ -d "$target_dir" ]; then
            echo -e "  ${BLUE}$target_dir:${NC}"
            for skill in "${SKILLS[@]}"; do
                local link="$target_dir/$skill"
                if [ -L "$link" ]; then
                    echo -e "    ${GREEN}$skill${NC} -> $(readlink "$link")"
                elif [ -d "$link" ]; then
                    echo -e "    ${YELLOW}$skill${NC} (directory, not symlink)"
                else
                    echo -e "    ${RED}$skill${NC} (missing)"
                fi
            done
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

    echo -e "${BLUE}Skills source: $SCRIPT_DIR${NC}"
    echo -e "${BLUE}Skills to install: ${SKILLS[*]}${NC}"
    echo -e "${BLUE}Install mode: $INSTALL_MODE${NC}"
    [ -n "$TARGET_AGENT" ] && echo -e "${BLUE}Target agent: $TARGET_AGENT${NC}"
    echo ""

    for skill in "${SKILLS[@]}"; do
        install_skill "$skill"
        echo ""
    done

    if $INSTALL_HOOKS && [ "$INSTALL_MODE" = "project" ]; then
        install_git_hooks
        echo ""
    fi

    verify_install

    echo ""
    echo -e "${GREEN}Dev workflow symlink installation complete!${NC}"
    echo "Skills are symlinked from: $SCRIPT_DIR"
    echo "Changes to the source skills will take effect immediately."
}

main "$@"
