#!/usr/bin/env bash
# Clean up AI Agent Skills using skill-spark
# Usage: ./clean-skills.sh [OPTIONS]
#
# Options:
#   --all                Clean all skills (default if no other filter)
#   --global             Target global skills only (default: project-level)
#   --skill <name>       Clean specific skill by name
#   --dir <path>         Clean all skills under a specific directory
#   --agent <name>       Clean all skills for a specific agent
#   --dry-run            Show what would be deleted without actually deleting
#   --force, -y          Auto-confirm without prompting
#   --help, -h           Show this help message
#
# Supported platforms: macOS, Linux, Windows (WSL2)
#
# How it works:
#   1. Tracked skills (in skills.lock) are removed via "skill-spark remove"
#   2. Untracked skills (present in .agents/skills/ but not in lock) are deleted directly
#   3. Empty agent skill directories are cleaned up
#
# Directory structure consistency note:
#   skill-spark supports multiple installation modes (add, sync, map) and
#   symlink vs. copy. The installed directory structure is NOT always identical
#   to the source directory (e.g. skills/base/):
#
#   - symlink mode (default): source files are copied to central storage
#     (.agents/skills/ for project, ~/.skill-spark/.agents/skills/ for global),
#     then symlinked into each agent's skills directory.
#   - no-symlink mode: files are copied directly into each agent directory.
#   - map command: creates symlinks from .agents/skills/ into target agents.
#
#   Because of this, cleanup must handle three layers:
#     a) Tracked skills -> use "skill-spark remove" (handles symlink targets)
#     b) Untracked/orphaned skills -> delete directly from all agent dirs
#     c) Empty directories -> removed after skills are deleted
#
#   This script handles all three layers across all supported agents.

set -euo pipefail

# ---------------------------------------------------------------------------
# Config & colors
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
FORCE=false
TARGET_ALL=false
TARGET_GLOBAL=false
TARGET_SKILL=""
TARGET_DIR=""
TARGET_AGENT=""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
usage() {
    sed -n '/^# Usage:/,/^# $/p' "$0" | sed 's/^# //'
}

log_info()    { echo -e "${BLUE}ℹ${NC}  $1"; }
log_ok()      { echo -e "${GREEN}✓${NC}  $1"; }
log_warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
log_error()   { echo -e "${RED}✗${NC}  $1"; }
log_dry()     { echo -e "${CYAN}[DRY-RUN]${NC} $1"; }

# Detect if running under WSL
is_wsl() {
    [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null
}

# Resolve skill-spark binary
resolve_skill_spark() {
    if command -v skill-spark &>/dev/null; then
        echo "skill-spark"
        return 0
    fi

    # Try local dev build
    if [[ -f "$SCRIPT_DIR/dist/skill-spark" ]]; then
        echo "$SCRIPT_DIR/dist/skill-spark"
        return 0
    fi

    # Try bun dev
    if command -v bun &>/dev/null && [[ -f "$SCRIPT_DIR/src/index.ts" ]]; then
        echo "bun $SCRIPT_DIR/src/index.ts"
        return 0
    fi

    # Try node / npx
    if command -v npx &>/dev/null; then
        local bin
        bin="$(npx --yes skill-spark 2>/dev/null | head -1 || true)"
        if [[ -n "$bin" ]]; then
            echo "npx skill-spark"
            return 0
        fi
    fi

    return 1
}

SKILL_SPARK=""
init_skill_spark() {
    SKILL_SPARK="$(resolve_skill_spark)" || {
        log_error "skill-spark not found. Please install it first:"
        log_error "  npm install -g skill-spark"
        log_error "  # or ensure it is in PATH"
        exit 1
    }
}

run_skill_spark() {
    if [[ "$DRY_RUN" == true ]]; then
        log_dry "skill-spark $*"
        return 0
    fi
    $SKILL_SPARK "$@"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                TARGET_ALL=true
                shift
                ;;
            --global)
                TARGET_GLOBAL=true
                shift
                ;;
            --skill)
                if [[ -z "${2:-}" ]]; then
                    log_error "--skill requires a value"
                    exit 1
                fi
                TARGET_SKILL="$2"
                shift 2
                ;;
            --dir)
                if [[ -z "${2:-}" ]]; then
                    log_error "--dir requires a value"
                    exit 1
                fi
                TARGET_DIR="$2"
                shift 2
                ;;
            --agent)
                if [[ -z "${2:-}" ]]; then
                    log_error "--agent requires a value"
                    exit 1
                fi
                TARGET_AGENT="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force|-y)
                FORCE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                log_error "Unexpected argument: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Default to --all if nothing specific given
    if [[ "$TARGET_ALL" == false ]] && [[ -z "$TARGET_SKILL" ]] && [[ -z "$TARGET_DIR" ]] && [[ -z "$TARGET_AGENT" ]]; then
        TARGET_ALL=true
    fi
}

# ---------------------------------------------------------------------------
# Lock-file helpers
# ---------------------------------------------------------------------------
get_project_lock() {
    local cwd="${1:-$(pwd)}"
    local path="$cwd/skills.lock"
    if [[ -f "$path" ]]; then
        echo "$path"
    fi
}

get_global_lock() {
    local path="$HOME/.skill-spark/skills.lock"
    if [[ -f "$path" ]]; then
        echo "$path"
    fi
}

# Extract skill names from a lock file (JSON)
extract_skills_from_lock() {
    local lock_file="$1"
    if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
        # Fallback: use sed/awk (very naive)
        grep -oP '"name"\s*:\s*"\K[^"]+' "$lock_file" 2>/dev/null || true
        return
    fi

    local py_cmd="python3"
    command -v python3 &>/dev/null || py_cmd="python"

    "$py_cmd" -c "
import json, sys
try:
    data = json.load(open('$lock_file'))
    for k,v in data.get('skills', {}).items():
        print(v.get('name',''))
except Exception:
    pass
" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Agent directory discovery (aligned with skill-spark agents.ts)
# ---------------------------------------------------------------------------
get_agent_project_dirs() {
    local cwd="${1:-$(pwd)}"
    # These match built-in agents from skill-spark
    cat <<EOF
$cwd/.agents/skills
$cwd/.claude/skills
$cwd/.trae/skills
$cwd/.codex/skills
$cwd/.opencode/skills
$cwd/.cursor/skills
$cwd/.gemini/skills
$cwd/.github-copilot/skills
$cwd/.roo/skills
$cwd/.continue/skills
$cwd/.windsurf/skills
$cwd/.augment/skills
$cwd/.codebuddy/skills
$cwd/.goose/skills
$cwd/.crush/skills
$cwd/.factory/skills
$cwd/.openhands/skills
$cwd/.pi/skills
$cwd/.qwen/skills
$cwd/.qoder/skills
$cwd/.junie/skills
$cwd/.kilocode/skills
$cwd/.mux/skills
$cwd/.vibe/skills
$cwd/.adal/skills
$cwd/.neovate/skills
$cwd/.pochi/skills
$cwd/.zencoder/skills
$cwd/.skills
$cwd/.agent/skills
$cwd/.commandcode/skills
$cwd/.cortex/skills
$cwd/.iflow/skills
$cwd/.kiro/skills
$cwd/.kode/skills
$cwd/.letta/skills
$cwd/.mcpjam/skills
$cwd/.skills
$cwd/skills
EOF
}

get_agent_global_dirs() {
    local home_dir="$HOME"
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    cat <<EOF
$home_dir/.skill-spark/.agents/skills
$home_dir/.agents/skills
$home_dir/.claude/skills
$home_dir/.trae/skills
$home_dir/.trae-cn/skills
$home_dir/.codex/skills
$home_dir/.opencode/skills
$home_dir/.cursor/skills
$home_dir/.gemini/skills
$home_dir/.gemini/antigravity/skills
$home_dir/.copilot/skills
$home_dir/.roo/skills
$home_dir/.continue/skills
$home_dir/.codeium/windsurf/skills
$home_dir/.windsurf/skills
$home_dir/.augment/skills
$home_dir/.codebuddy/skills
$home_dir/.goose/skills
$config_home/goose/skills
$home_dir/.crush/skills
$config_home/crush/skills
$home_dir/.factory/skills
$home_dir/.openhands/skills
$home_dir/.pi/agent/skills
$home_dir/.qwen/skills
$home_dir/.qoder/skills
$home_dir/.junie/skills
$home_dir/.kilocode/skills
$home_dir/.mux/skills
$home_dir/.vibe/skills
$home_dir/.adal/skills
$home_dir/.neovate/skills
$home_dir/.pochi/skills
$home_dir/.zencoder/skills
$home_dir/.agent/skills
$home_dir/.commandcode/skills
$home_dir/.snowflake/cortex/skills
$home_dir/.iflow/skills
$home_dir/.kiro/skills
$home_dir/.kode/skills
$home_dir/.letta/skills
$home_dir/.mcpjam/skills
$config_home/agents/skills
$config_home/opencode/skills
$home_dir/.skills
EOF
}

# ---------------------------------------------------------------------------
# Core operations
# ---------------------------------------------------------------------------

# Remove tracked skills via skill-spark
remove_tracked_skills() {
    local scope="$1"   # "project" or "global"
    local names="$2"   # space-separated skill names

    if [[ -z "$names" ]]; then
        return 0
    fi

    local extra_args=()
    if [[ "$FORCE" == true ]]; then
        extra_args+=("--force")
    fi

    if [[ "$scope" == "global" ]]; then
        # skill-spark remove does not have a --global flag; it scans both locks.
        # We just call remove for each skill name.
        log_info "Removing global tracked skills: $names"
    else
        log_info "Removing project tracked skills: $names"
    fi

    for name in $names; do
        if [[ "$DRY_RUN" == true ]]; then
            log_dry "skill-spark remove --force $name"
        else
            log_info "Running: skill-spark remove --force $name"
            run_skill_spark remove --force "$name" || log_warn "Failed to remove tracked skill: $name"
        fi
    done
}

# Delete untracked skill directories directly
delete_untracked_skill_dir() {
    local path="$1"
    if [[ ! -e "$path" ]]; then
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        if [[ -L "$path" ]]; then
            log_dry "Would delete symlink: $path -> $(readlink "$path" 2>/dev/null || true)"
        else
            log_dry "Would delete directory: $path"
        fi
        return 0
    fi

    rm -rf "$path"
    log_ok "Deleted: $path"
}

# Clean empty agent skill directories
clean_empty_dirs() {
    local dirs="$1"
    local removed=0

    while IFS= read -r dir; do
        [[ -z "$dir" ]] && continue
        [[ -d "$dir" ]] || continue

        # If directory is empty (only . and ..)
        if [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                log_dry "Would remove empty dir: $dir"
            else
                rmdir "$dir" 2>/dev/null && {
                    log_ok "Removed empty dir: $dir"
                    removed=$((removed + 1))
                } || true
            fi
        fi
    done <<< "$dirs"

    return 0
}

# ---------------------------------------------------------------------------
# Modes
# ---------------------------------------------------------------------------

do_clean_all() {
    log_info "Mode: clean ALL skills"

    local tracked_project=""
    local tracked_global=""

    local proj_lock
    proj_lock="$(get_project_lock)"
    if [[ -n "$proj_lock" ]]; then
        tracked_project="$(extract_skills_from_lock "$proj_lock" | sort -u | tr '\n' ' ')"
    fi

    local glob_lock
    glob_lock="$(get_global_lock)"
    if [[ -n "$glob_lock" ]]; then
        tracked_global="$(extract_skills_from_lock "$glob_lock" | sort -u | tr '\n' ' ')"
    fi

    # Remove tracked via skill-spark
    if [[ "$TARGET_GLOBAL" == false ]]; then
        remove_tracked_skills "project" "$tracked_project"
    fi
    remove_tracked_skills "global" "$tracked_global"

    # Remove untracked from directories
    local all_dirs=""
    if [[ "$TARGET_GLOBAL" == false ]]; then
        all_dirs="$(get_agent_project_dirs)"
    fi
    all_dirs="$all_dirs
$(get_agent_global_dirs)"

    local deleted=()
    while IFS= read -r dir; do
        [[ -z "$dir" ]] && continue
        [[ -d "$dir" ]] || continue

        for item in "$dir"/*; do
            [[ -e "$item" ]] || continue
            local basename_item
            basename_item="$(basename "$item")"
            [[ "$basename_item" == *.md ]] && continue  # skip loose md files (commands handled separately)

            # Skip if it is a tracked skill we already removed
            local is_tracked=false
            for t in $tracked_project $tracked_global; do
                if [[ "$(echo "$basename_item" | tr '[:upper:]' '[:lower:]')" == "$(echo "$t" | tr '[:upper:]' '[:lower:]')" ]]; then
                    is_tracked=true
                    break
                fi
            done

            # Also skip if it doesn't look like a skill
            if [[ -d "$item" ]] && [[ ! -f "$item/SKILL.md" ]]; then
                continue
            fi

            delete_untracked_skill_dir "$item"
            deleted+=("$item")
        done
    done <<< "$all_dirs"

    # Clean empty dirs
    clean_empty_dirs "$all_dirs"
}

do_clean_skill() {
    local name="$TARGET_SKILL"
    log_info "Mode: clean specific skill '$name'"

    # Try skill-spark remove first (works if tracked)
    if [[ "$DRY_RUN" == true ]]; then
        log_dry "skill-spark remove --force $name"
    else
        run_skill_spark remove --force "$name" 2>/dev/null && {
            log_ok "Removed tracked skill via skill-spark: $name"
        } || true
    fi

    # Also scan directories to catch untracked copies or stray symlinks
    local all_dirs=""
    if [[ "$TARGET_GLOBAL" == false ]]; then
        all_dirs="$(get_agent_project_dirs)"
    fi
    all_dirs="$all_dirs
$(get_agent_global_dirs)"

    local found=false
    while IFS= read -r dir; do
        [[ -z "$dir" ]] && continue
        [[ -d "$dir" ]] || continue

        for item in "$dir"/"$name" "$dir"/"$name.md"; do
            [[ -e "$item" ]] || continue
            delete_untracked_skill_dir "$item"
            found=true
        done
    done <<< "$all_dirs"

    if [[ "$found" == false ]] && [[ "$DRY_RUN" == false ]]; then
        log_warn "Skill not found anywhere: $name"
    fi
}

do_clean_dir() {
    local target="$TARGET_DIR"
    # Resolve relative paths
    if [[ ! "$target" = /* ]]; then
        target="$(cd "$SCRIPT_DIR" && pwd)/$target"
    fi

    if [[ ! -d "$target" ]]; then
        log_error "Directory does not exist: $target"
        exit 1
    fi

    log_info "Mode: clean all skills under directory: $target"

    for item in "$target"/*; do
        [[ -e "$item" ]] || continue
        local basename_item
        basename_item="$(basename "$item")"

        # Only delete items that look like skills
        if [[ -d "$item" ]] && [[ -f "$item/SKILL.md" ]]; then
            delete_untracked_skill_dir "$item"
        elif [[ -L "$item" ]]; then
            # symlink skill
            delete_untracked_skill_dir "$item"
        elif [[ -f "$item" ]] && [[ "$basename_item" == *.md ]]; then
            # command
            if [[ "$DRY_RUN" == true ]]; then
                log_dry "Would delete command file: $item"
            else
                rm -f "$item"
                log_ok "Deleted command: $item"
            fi
        fi
    done

    # If this directory matches a lock-file scope, also clean the lock
    if [[ -f "$target/../skills.lock" ]]; then
        local lock_dir
        lock_dir="$(cd "$target/.." && pwd)"
        local lock_file="$lock_dir/skills.lock"
        if [[ -f "$lock_file" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                log_dry "Would clear lock file: $lock_file"
            else
                rm -f "$lock_file"
                log_ok "Removed lock file: $lock_file"
            fi
        fi
    fi
}

do_clean_agent() {
    local agent="$TARGET_AGENT"
    log_info "Mode: clean all skills for agent: $agent"

    local dirs_to_check=()

    case "$(echo "$agent" | tr '[:upper:]' '[:lower:]')" in
        claude|claudecode|claude-code)
            dirs_to_check+=(".claude/skills" "$HOME/.claude/skills")
            ;;
        kimi|kimi-cli|kimicode|kimi-code)
            dirs_to_check+=(".agents/skills" "$HOME/.agents/skills")
            ;;
        codex)
            dirs_to_check+=(".agents/skills" ".codex/skills" "$HOME/.codex/skills")
            ;;
        opencode|open-code)
            dirs_to_check+=(".agents/skills" ".opencode/skills" "$HOME/.opencode/skills")
            ;;
        trae)
            dirs_to_check+=(".trae/skills" "$HOME/.trae/skills")
            ;;
        trae-cn|traecn)
            dirs_to_check+=(".trae/skills" "$HOME/.trae-cn/skills")
            ;;
        cursor)
            dirs_to_check+=(".agents/skills" "$HOME/.cursor/skills")
            ;;
        gemini|gemini-cli)
            dirs_to_check+=(".agents/skills" "$HOME/.gemini/skills")
            ;;
        copilot|github-copilot)
            dirs_to_check+=(".agents/skills" "$HOME/.copilot/skills")
            ;;
        droid)
            dirs_to_check+=(".factory/skills" "$HOME/.factory/skills")
            ;;
        windsurf)
            dirs_to_check+=(".windsurf/skills" "$HOME/.codeium/windsurf/skills" "$HOME/.windsurf/skills")
            ;;
        roo|roo-code)
            dirs_to_check+=(".roo/skills" "$HOME/.roo/skills")
            ;;
        continue)
            dirs_to_check+=(".continue/skills" "$HOME/.continue/skills")
            ;;
        augment)
            dirs_to_check+=(".augment/skills" "$HOME/.augment/skills")
            ;;
        codebuddy)
            dirs_to_check+=(".codebuddy/skills" "$HOME/.codebuddy/skills")
            ;;
        goose)
            dirs_to_check+=(".goose/skills" "$HOME/.goose/skills" "${XDG_CONFIG_HOME:-$HOME/.config}/goose/skills")
            ;;
        crush)
            dirs_to_check+=(".crush/skills" "$HOME/.crush/skills" "${XDG_CONFIG_HOME:-$HOME/.config}/crush/skills")
            ;;
        openhands)
            dirs_to_check+=(".openhands/skills" "$HOME/.openhands/skills")
            ;;
        pi)
            dirs_to_check+=(".pi/skills" "$HOME/.pi/agent/skills")
            ;;
        qwen|qwen-code)
            dirs_to_check+=(".qwen/skills" "$HOME/.qwen/skills")
            ;;
        qoder)
            dirs_to_check+=(".qoder/skills" "$HOME/.qoder/skills")
            ;;
        junie)
            dirs_to_check+=(".junie/skills" "$HOME/.junie/skills")
            ;;
        kilo|kilocode)
            dirs_to_check+=(".kilocode/skills" "$HOME/.kilocode/skills")
            ;;
        mux)
            dirs_to_check+=(".mux/skills" "$HOME/.mux/skills")
            ;;
        vibe|mistral-vibe|mistral)
            dirs_to_check+=(".vibe/skills" "$HOME/.vibe/skills")
            ;;
        adal)
            dirs_to_check+=(".adal/skills" "$HOME/.adal/skills")
            ;;
        neovate)
            dirs_to_check+=(".neovate/skills" "$HOME/.neovate/skills")
            ;;
        pochi)
            dirs_to_check+=(".pochi/skills" "$HOME/.pochi/skills")
            ;;
        zencoder)
            dirs_to_check+=(".zencoder/skills" "$HOME/.zencoder/skills")
            ;;
        antigravity)
            dirs_to_check+=(".agent/skills" "$HOME/.gemini/antigravity/skills")
            ;;
        cortex)
            dirs_to_check+=(".cortex/skills" "$HOME/.snowflake/cortex/skills")
            ;;
        command-code)
            dirs_to_check+=(".commandcode/skills" "$HOME/.commandcode/skills")
            ;;
        iflow|iflow-cli)
            dirs_to_check+=(".iflow/skills" "$HOME/.iflow/skills")
            ;;
        kiro|kiro-cli)
            dirs_to_check+=(".kiro/skills" "$HOME/.kiro/skills")
            ;;
        kode)
            dirs_to_check+=(".kode/skills" "$HOME/.kode/skills")
            ;;
        letta)
            dirs_to_check+=(".skills" "$HOME/.letta/skills")
            ;;
        mcpjam)
            dirs_to_check+=(".mcpjam/skills" "$HOME/.mcpjam/skills")
            ;;
        universal|common|agents|agent)
            dirs_to_check+=(".agents/skills" "$HOME/.agents/skills" "$HOME/.skill-spark/.agents/skills")
            ;;
        *)
            log_warn "Unknown agent '$agent', trying generic paths..."
            dirs_to_check+=(".$agent/skills" "$HOME/.$agent/skills")
            ;;
    esac

    local found_any=false
    for rel in "${dirs_to_check[@]}"; do
        local dir
        if [[ "$rel" = /* ]]; then
            dir="$rel"
        else
            dir="$(pwd)/$rel"
        fi

        [[ -d "$dir" ]] || continue
        found_any=true

        for item in "$dir"/*; do
            [[ -e "$item" ]] || continue
            delete_untracked_skill_dir "$item"
        done

        clean_empty_dirs "$dir"
    done

    if [[ "$found_any" == false ]]; then
        log_warn "No skill directories found for agent: $agent"
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    parse_args "$@"
    init_skill_spark

    if [[ "$DRY_RUN" == true ]]; then
        echo ""
        log_dry "DRY RUN — no files will be deleted"
        echo ""
    fi

    if [[ -n "$TARGET_SKILL" ]]; then
        do_clean_skill
    elif [[ -n "$TARGET_DIR" ]]; then
        do_clean_dir
    elif [[ -n "$TARGET_AGENT" ]]; then
        do_clean_agent
    elif [[ "$TARGET_ALL" == true ]]; then
        do_clean_all
    fi

    echo ""
    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Dry run complete. No files were deleted."
    else
        log_ok "Clean complete."
    fi
}

main "$@"
