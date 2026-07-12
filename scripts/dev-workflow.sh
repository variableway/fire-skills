#!/usr/bin/env bash
# Unified DevOps workflow script
# Provides install, verify, update, remove, hooks subcommands
# Uses skill-spark CLI when available, falls back to standalone installers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEVOPS_DIR="$PROJECT_DIR/skills/devops"

# Resolve skill-spark binary
CLI=""
if command -v skill-spark &>/dev/null; then
  CLI="skill-spark"
elif [ -f "$PROJECT_DIR/dist/index.js" ]; then
  CLI="node $PROJECT_DIR/dist/index.js"
elif command -v bun &>/dev/null && [ -f "$PROJECT_DIR/packages/skill-cli/src/index.ts" ]; then
  CLI="bun run $PROJECT_DIR/packages/skill-cli/src/index.ts"
fi

usage() {
    cat <<EOF
DevOps Workflow Script

Usage: $0 {install|verify|update|remove|hooks} [options]

Commands:
  install [--scope system|project] [--agent <name>] [--yes]
  verify  [--scope system|project] [--agent <name>]
  update  [--scope system|project] [--agent <name>] [--yes]
  remove  [--scope system|project] [--agent <name>] [--yes]
  hooks

Options:
  --scope system|project   Installation scope (default: project)
  --agent <name>           Target agent (claude-code, kimi, codex, opencode, trae)
  --yes                    Auto-confirm prompts

Examples:
  $0 install --scope system --agent codex
  $0 install --agent codex --yes
  $0 verify --scope system
  $0 update
  $0 remove --scope system --agent codex --yes
  $0 hooks
EOF
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

CMD="$1"
shift

SCOPE="project"
AGENT=""
YES=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --scope)
            SCOPE="$2"
            shift 2
            ;;
        --agent)
            AGENT="$2"
            shift 2
            ;;
        --yes)
            YES=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'" >&2
            usage
            exit 1
            ;;
    esac
done

SKILLS="git-workflow local-workflow github-cli-skill gh-create-release scanning-for-secrets"

run_with_cli() {
    if [ -n "$CLI" ]; then
        return 0
    fi
    return 1
}

resolve_scope_flag() {
    if [ "$SCOPE" = "system" ]; then
        echo "--global"
    else
        echo ""
    fi
}

resolve_agent_flag() {
    if [ -n "$AGENT" ]; then
        echo "--agent $AGENT"
    else
        echo ""
    fi
}

resolve_yes_flag() {
    if [ "$YES" = true ]; then
        echo "--yes"
    else
        echo ""
    fi
}

case "$CMD" in
    install)
        if run_with_cli; then
            # shellcheck disable=SC2086
            $CLI add skills/devops $(resolve_scope_flag) $(resolve_agent_flag) $(resolve_yes_flag)
        else
            echo "skill-spark not found. Build first: bun run build"
            echo "Falling back to standalone installer..."
            if [ "$SCOPE" = "system" ]; then
                SYSTEM_FLAG="--system"
            else
                SYSTEM_FLAG="--project"
            fi
            AGENT_FLAG=""
            if [ -n "$AGENT" ]; then
                AGENT_FLAG="--agent $AGENT"
            fi
            # shellcheck disable=SC2086
            exec "$DEVOPS_DIR/dev-workflow-install.sh" $SYSTEM_FLAG $AGENT_FLAG
        fi
        ;;
    verify)
        echo "Verifying devops skills installation..."
        FOUND=0
        for skill in $SKILLS; do
            if [ "$SCOPE" = "system" ]; then
                # Check common global directories
                for dir in "$HOME/.config/agents/skills" "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.config/opencode/skills" "$HOME/.trae/skills"; do
                    if [ -e "$dir/$skill" ]; then
                        echo "  [OK] $skill -> $dir/$skill"
                        FOUND=$((FOUND + 1))
                        break
                    fi
                done
            else
                if [ -e "./.agents/skills/$skill" ]; then
                    echo "  [OK] $skill -> ./.agents/skills/$skill"
                    FOUND=$((FOUND + 1))
                elif [ -e "./.claude/skills/$skill" ]; then
                    echo "  [OK] $skill -> ./.claude/skills/$skill"
                    FOUND=$((FOUND + 1))
                elif [ -e "./.trae/skills/$skill" ]; then
                    echo "  [OK] $skill -> ./.trae/skills/$skill"
                    FOUND=$((FOUND + 1))
                fi
            fi
        done
        echo ""
        echo "Verified: $FOUND / 5 skills"
        if [ "$FOUND" -lt 5 ]; then
            exit 1
        fi
        ;;
    update)
        if run_with_cli; then
            # shellcheck disable=SC2086
            $CLI update $SKILLS $(resolve_scope_flag) $(resolve_agent_flag) $(resolve_yes_flag)
        else
            echo "Error: skill-spark is required for update. Build first: bun run build" >&2
            exit 1
        fi
        ;;
    remove)
        if run_with_cli; then
            # shellcheck disable=SC2086
            $CLI remove $SKILLS $(resolve_scope_flag) $(resolve_agent_flag) $(resolve_yes_flag)
        else
            echo "Error: skill-spark is required for remove. Build first: bun run build" >&2
            exit 1
        fi
        ;;
    hooks)
        if [ ! -d ".git/hooks" ]; then
            echo "Error: Not a git repository." >&2
            exit 1
        fi
        HOOK_SRC="$DEVOPS_DIR/git-workflow/hooks"
        for hook in prepare-commit-msg post-commit; do
            if [ -f "$HOOK_SRC/$hook" ]; then
                cp "$HOOK_SRC/$hook" ".git/hooks/$hook"
                chmod +x ".git/hooks/$hook"
                echo "Installed .git/hooks/$hook"
            fi
        done
        ;;
    *)
        echo "Error: Unknown command '$CMD'" >&2
        usage
        exit 1
        ;;
esac
