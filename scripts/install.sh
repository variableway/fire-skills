#!/usr/bin/env bash
# Unified Skill Installer (macOS / Linux / WSL2)
# Copies skills to canonical storage (~/.skill-spark/.agents/skills/) then symlinks to agent dirs.
#
# Usage: ./scripts/install.sh <source> [OPTIONS]
#
# Options:
#   --system              Install to system skill directories (default)
#   --project             Install to current project directory
#   --global              Alias for --system
#   --agent <name>        Target agent(s), repeatable (default: all)
#   --skill <name>        Install specific skill(s) only, repeatable
#   --no-symlink          Copy directly instead of symlink
#   -h, --help            Show this help message
#
# Supported agents:
#   claude-code, kimi, codex, opencode, trae, trae-solo, workbuddy
#
# Examples:
#   ./scripts/install.sh skills/devops --system
#   ./scripts/install.sh skills/devops --project --agent claude-code
#   ./scripts/install.sh skills/base --system --skill anysearch
#   ./scripts/install.sh skills/devops --project --skill git-workflow --skill local-workflow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_SPARK_HOME="${SKILL_SPARK_HOME:-$HOME/.skill-spark}"
CANONICAL_DIR="$SKILL_SPARK_HOME/.agents/skills"

SOURCE_PATH=""
INSTALL_MODE="system"
TARGET_AGENTS=""
SELECTED_SKILLS=""
USE_SYMLINK=true

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

ALL_AGENTS="claude-code kimi codex opencode trae trae-solo workbuddy"

# Get system target dir for an agent
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

# Get project target dir for an agent
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

# Check if agent is valid
is_valid_agent() {
    case "$1" in
        claude-code|kimi|codex|opencode|trae|trae-solo|workbuddy) return 0 ;;
        *) return 1 ;;
    esac
}

usage() {
    cat <<'EOF'
Unified Skill Installer (macOS / Linux / WSL2)
Copies skills to canonical storage then symlinks to agent directories.

Usage: ./scripts/install.sh <source> [OPTIONS]

Options:
  --system              Install to system skill directories (default)
  --project             Install to current project directory
  --global              Alias for --system
  --agent <name>        Target agent(s), repeatable (default: all supported)
  --skill <name>        Install specific skill(s) only, repeatable
  --no-symlink          Copy directly instead of creating symlinks
  -h, --help            Show this help message

Supported agents:
  claude-code  ~/.claude/skills/
  kimi         ~/.kimi/skills/
  codex        ~/.codex/skills/
  opencode     ~/.opencode/skills/
  trae         ~/.trae/skills/
  trae-solo    ~/.trae/skills/
  workbuddy    ~/.workbuddy/skills/

Examples:
  ./scripts/install.sh skills/devops --system
  ./scripts/install.sh skills/devops --project --agent claude-code
  ./scripts/install.sh skills/base --system --skill anysearch
  ./scripts/install.sh skills/devops --project --skill git-workflow --skill local-workflow
EOF
}

log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}  [OK]${NC}   $*"; }
log_skip()  { echo -e "${YELLOW}  [SKIP]${NC} $*"; }
log_err()   { echo -e "${RED}  [ERR]${NC}  $*"; }
log_detail(){ echo -e "         $*"; }

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
            --no-symlink) USE_SYMLINK=false; shift ;;
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

    # Resolve to absolute path
    if [[ ! "$SOURCE_PATH" = /* ]]; then
        SOURCE_PATH="$PROJECT_ROOT/$SOURCE_PATH"
    fi

    if [[ ! -d "$SOURCE_PATH" ]]; then
        echo "Error: Source directory not found: $SOURCE_PATH" >&2; exit 1
    fi

    # Default: all agents
    TARGET_AGENTS="${TARGET_AGENTS:-$ALL_AGENTS}"
    TARGET_AGENTS="$(echo "$TARGET_AGENTS" | xargs)"

    # Validate agents
    for agent in $TARGET_AGENTS; do
        if ! is_valid_agent "$agent"; then
            echo "Error: Unknown agent '$agent'" >&2
            echo "Supported: $ALL_AGENTS" >&2
            exit 1
        fi
    done
}

detect_wsl() {
    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
        return 0
    fi
    return 1
}

check_os() {
    local os
    os="$(uname -s)"
    case "$os" in
        Darwin) log_info "Detected: macOS" ;;
        Linux*)
            if detect_wsl; then
                log_info "Detected: Windows WSL2"
            else
                log_info "Detected: Linux"
            fi ;;
        *)      log_info "Detected: $os" ;;
    esac
}

# Find SKILL.md files in a directory tree and return skill root paths (newline-separated)
find_skills() {
    local source="$1"

    # Direct skill (has SKILL.md)
    if [[ -f "$source/SKILL.md" ]]; then
        echo "$source"
        return
    fi

    # Category directory (contains skill subdirectories)
    for entry in "$source"/*/SKILL.md; do
        [[ -f "$entry" ]] || continue
        dirname "$entry"
    done
}

get_skill_name() {
    local skill_md="$1/SKILL.md"
    local in_frontmatter=false

    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if $in_frontmatter; then break; else in_frontmatter=true; continue; fi
        fi
        if $in_frontmatter && [[ "$line" =~ ^name:[[:space:]]*(.+) ]]; then
            echo "${BASH_REMATCH[1]}"
            return
        fi
    done < "$skill_md"

    basename "$1"
}

# Check if a skill name is in the selected list (empty = all selected)
is_skill_selected() {
    local name="$1"
    if [[ -z "$SELECTED_SKILLS" ]]; then
        return 0  # all selected
    fi
    for selected in $SELECTED_SKILLS; do
        if [[ "$name" == "$selected" ]]; then
            return 0
        fi
    done
    return 1
}

# Copy skill to canonical storage
copy_to_canonical() {
    local source="$1"
    local name="$2"
    local target="$CANONICAL_DIR/$name"

    if [[ -d "$target" ]]; then
        rm -rf "$target"
    fi
    mkdir -p "$target"

    # Copy excluding .git, node_modules, __pycache__, .DS_Store
    for entry in "$source"/*; do
        [[ -e "$entry" ]] || continue
        local b
        b="$(basename "$entry")"
        case "$b" in
            .git|node_modules|__pycache__|.DS_Store|.env|.env.local) continue ;;
        esac
        cp -R "$entry" "$target/"
    done

    # Copy hidden files except excluded ones
    for entry in "$source"/.*; do
        [[ -e "$entry" ]] || continue
        local b
        b="$(basename "$entry")"
        case "$b" in
            .|..|.git|.env|.env.local|.DS_Store) continue ;;
        esac
        cp -R "$entry" "$target/" 2>/dev/null || true
    done
}

# Install skill symlink to an agent directory
install_to_agent() {
    local name="$1"
    local agent="$2"
    local agent_dir="$3"
    local link_path="$agent_dir/$name"

    mkdir -p "$agent_dir"

    if [[ -e "$link_path" ]] || [[ -L "$link_path" ]]; then
        log_skip "$name -> $agent (already exists)"
        return 1
    fi

    if $USE_SYMLINK; then
        ln -s "$CANONICAL_DIR/$name" "$link_path"
    else
        cp -R "$CANONICAL_DIR/$name" "$link_path"
    fi
    log_ok "$name -> $agent"
    log_detail "$link_path"
    return 0
}

do_install() {
    local skill_paths
    skill_paths="$(find_skills "$SOURCE_PATH")"

    if [[ -z "$skill_paths" ]]; then
        echo "Error: No skills found in $SOURCE_PATH" >&2
        exit 1
    fi

    check_os
    echo ""

    local mode_label="system"
    [[ "$INSTALL_MODE" == "project" ]] && mode_label="project"

    log_info "Mode: $mode_label | Agents: $TARGET_AGENTS"
    local skill_count
    skill_count="$(echo "$skill_paths" | wc -l | xargs)"
    log_info "Skills found: $skill_count"
    echo ""

    local total_installed=0
    local total_skipped=0

    while IFS= read -r skill_path; do
        [[ -z "$skill_path" ]] && continue

        local name
        name="$(get_skill_name "$skill_path")"

        # Filter by selected skills
        if ! is_skill_selected "$name"; then
            continue
        fi

        echo -e "${CYAN}[$name]${NC}"

        # Step 1: Copy to canonical storage
        if $USE_SYMLINK; then
            copy_to_canonical "$skill_path" "$name"
            log_detail "canonical: $CANONICAL_DIR/$name"
        fi

        # Step 2: Install to each agent
        local installed=0
        local skipped=0

        for agent in $TARGET_AGENTS; do
            local agent_dir
            if [[ "$INSTALL_MODE" == "system" ]]; then
                agent_dir="$(get_system_target "$agent")"
            else
                agent_dir="$(get_project_target "$agent")"
            fi

            if install_to_agent "$name" "$agent" "$agent_dir"; then
                installed=$((installed + 1))
            else
                skipped=$((skipped + 1))
            fi
        done

        total_installed=$((total_installed + installed))
        total_skipped=$((total_skipped + skipped))
        echo ""
    done <<< "$skill_paths"

    echo -e "${GREEN}Installation complete!${NC} Installed: $total_installed, Skipped: $total_skipped"
}

main() {
    parse_args "$@"
    do_install
}

main "$@"
