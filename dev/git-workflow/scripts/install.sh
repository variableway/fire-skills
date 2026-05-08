#!/usr/bin/env bash
# Git Workflow Skill Installer (macOS / Linux)
# Usage: ./install.sh [--system | --project] [--agent <name>] [--hooks]
#
# Options:
#   --system        Install to system skill directories
#   --project       Install to current project directory
#   --agent <name>  Target specific agent (claude-code, kimi, codex, opencode)
#   --hooks         Also install git hooks to .git/hooks/
#   -h, --help      Show this help message

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_NAME="$(basename "$SKILL_ROOT")"
INSTALL_MODE=""
TARGET_AGENT=""
INSTALL_HOOKS=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Git Workflow Skill Installer (macOS / Linux)
Usage: ./install.sh [--system | --project] [--agent <name>]

Options:
  --system        Install to system directories (~/.config/agents/skills/)
  --project       Install to current project directory (./.agents/skills/)
  --agent <name>  Target specific agent (claude-code, kimi, codex, opencode)
  -h, --help      Show this help message

Examples:
  ./install.sh --system
  ./install.sh --system --agent kimi
  ./install.sh --project
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

install_hooks() {
    echo ""
    echo -e "${BLUE}Installing git hooks...${NC}"

    if [ ! -d ".git/hooks" ]; then
        echo -e "${YELLOW}Warning: Not a git repository or .git/hooks not found.${NC}"
        return
    fi

    local hooks_dir="$SKILL_ROOT/hooks"
    for hook in prepare-commit-msg post-commit; do
        local src="$hooks_dir/$hook"
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

install_claude_code_hook() {
    echo ""
    echo -e "${BLUE}Configuring Claude Code hook (.claude/settings.json)...${NC}"

    local settings_dir=".claude"
    local settings_file="$settings_dir/settings.json"
    local hook_script="$SKILL_ROOT/hooks/claude-auto-issue.sh"

    if [ ! -f "$hook_script" ]; then
        echo -e "${YELLOW}  [SKIP] claude-auto-issue.sh not found in skill${NC}"
        return
    fi

    mkdir -p "$settings_dir"

    # Use stable symlink path if available, otherwise relative path
    local hook_cmd
    if [ -d ".claude/skills/$SKILL_NAME" ]; then
        hook_cmd="bash .claude/skills/$SKILL_NAME/hooks/claude-auto-issue.sh"
    else
        local skill_rel_path
        skill_rel_path=$(python3 -c "
import os.path
print(os.path.relpath('$SKILL_ROOT', '$PWD'))
" 2>/dev/null || echo "dev/git-workflow")
        hook_cmd="bash $skill_rel_path/hooks/claude-auto-issue.sh"
    fi

    if [ -f "$settings_file" ]; then
        # Merge hooks into existing settings.json
        python3 -c "
import json, sys
with open('$settings_file', 'r') as f:
    settings = json.load(f)

hook_config = {
    'UserPromptSubmit': [
        {
            'matcher': '*',
            'hooks': [
                {
                    'type': 'command',
                    'command': '$hook_cmd',
                    'timeout': 10
                }
            ]
        }
    ]
}

if 'hooks' not in settings:
    settings['hooks'] = {}
settings['hooks'].update(hook_config)

with open('$settings_file', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  [OK]${NC}   Updated $settings_file with UserPromptSubmit hook"
        else
            echo -e "${RED}  [ERROR]${NC} Failed to update $settings_file"
        fi
    else
        # Create new settings.json
        cat > "$settings_file" <<SETTINGS
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "$hook_cmd",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
SETTINGS
        echo -e "${GREEN}  [OK]${NC}   Created $settings_file with UserPromptSubmit hook"
    fi
}

install_claude_md() {
    echo ""
    echo -e "${BLUE}Creating CLAUDE.md with git-workflow instructions...${NC}"

    local claude_md="CLAUDE.md"

    if [ -f "$claude_md" ] && grep -q "git-workflow" "$claude_md" 2>/dev/null; then
        echo -e "${YELLOW}  [SKIP]${NC} CLAUDE.md already contains git-workflow instructions"
        return
    fi

    # Determine relative path — prefer stable symlink path
    local skill_rel_path
    if [ -d ".claude/skills/$SKILL_NAME" ]; then
        skill_rel_path=".claude/skills/$SKILL_NAME"
    else
        skill_rel_path=$(python3 -c "
import os.path
print(os.path.relpath('$SKILL_ROOT', '$PWD'))
" 2>/dev/null || echo "dev/git-workflow")
    fi

    local workflow_block='## Task Execution Workflow

When the user asks to **execute a task**, **implement a task**, or **run a task** (e.g., "请执行Task 9", "execute Task 3"), you MUST use the `git-workflow` skill:

1. **INIT** — Create a GitHub Issue:
   ```bash
   python '"$skill_rel_path"'/scripts/orchestrate.py init --title "<task title>" --description "<task description>"
   ```

2. **IMPLEMENT** — Execute the task (code changes, tests, etc.)

3. **FINISH** — Append completion message and close the Issue:
   ```bash
   python '"$skill_rel_path"'/scripts/orchestrate.py finish --message "<completion summary>"
   ```

This applies to all tasks referenced from task files (e.g., `tasks/issues/dev-workflow.md`).

**Do NOT skip the workflow** — always create an Issue first, then close it after completion.
'

    if [ -f "$claude_md" ]; then
        # Append to existing CLAUDE.md
        echo "" >> "$claude_md"
        echo "$workflow_block" >> "$claude_md"
        echo -e "${GREEN}  [OK]${NC}   Appended git-workflow instructions to $claude_md"
    else
        echo "# Project Instructions" > "$claude_md"
        echo "" >> "$claude_md"
        echo "$workflow_block" >> "$claude_md"
        echo -e "${GREEN}  [OK]${NC}   Created $claude_md with git-workflow instructions"
    fi
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
            # Always configure Claude Code integration for project installs
            install_claude_code_hook
            install_claude_md
            ;;
    esac

    # Install git hooks if requested
    if $INSTALL_HOOKS; then
        install_hooks
    fi

    echo ""
    echo "Skill installed: $SKILL_NAME"
}

main "$@"
