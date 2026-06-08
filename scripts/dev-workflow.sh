#!/usr/bin/env sh
# Unified Dev Workflow skill manager for macOS, Linux, WSL2, and Git Bash.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
CLI="$ROOT_DIR/dist/skill-spark"
SOURCE="$ROOT_DIR/skills/devops"

ACTION="install"
SCOPE="project"
YES="--yes"
FORCE=""
NO_SYMLINK=""
AGENTS="codex"
SKILLS="git-workflow local-workflow"
ALL_DEVOPS_SKILLS="gh-create-release git-workflow github-cli local-workflow scanning-for-secrets"
AGENTS_CUSTOM=0
SKILLS_CUSTOM=0
ALL_DEVOPS=0

usage() {
  cat <<'EOF'
Usage: scripts/dev-workflow.sh <command> [options]

Commands:
  install|add       Install git-workflow/local-workflow skills
  remove|delete    Remove installed workflow skills
  update           Update installed workflow skills
  outdated|status  Check installed workflow skill status
  hooks            Install/diagnose git-workflow trigger hooks
  list             List installable DevOps skills
  verify|doctor    Run validation and environment checks

Options:
  --scope <scope>       project or system/global (default: project)
  --global              Alias for --scope system
  --project             Alias for --scope project
  --agent <agent>       Target agent; repeatable (default: codex)
  --skill <skill>       Target skill; repeatable (default: git-workflow local-workflow)
  --all-devops          Target all skills in skills/devops
  --no-symlink          Copy files instead of using symlinks
  --force               Force/auto-confirm operations
  -y, --yes             Auto-confirm operations (default)
  -h, --help            Show this help

Examples:
  scripts/dev-workflow.sh install --agent codex
  scripts/dev-workflow.sh install --scope system --agent codex
  scripts/dev-workflow.sh remove --scope system --agent codex
  scripts/dev-workflow.sh verify --agent codex
  scripts/dev-workflow.sh hooks --agent claude-code
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

append_word() {
  if [ -z "$1" ]; then
    printf '%s' "$2"
  else
    printf '%s %s' "$1" "$2"
  fi
}

normalize_agent() {
  case "$1" in
    kimi) printf '%s' "kimi-cli" ;;
    claude) printf '%s' "claude-code" ;;
    *) printf '%s' "$1" ;;
  esac
}

global_skill_dir() {
  agent=$(normalize_agent "$1")
  config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
  case "$agent" in
    codex) printf '%s' "${CODEX_HOME:-$HOME/.codex}/skills" ;;
    claude-code) printf '%s' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills" ;;
    opencode) printf '%s' "$config_home/opencode/skills" ;;
    trae) printf '%s' "$HOME/.trae/skills" ;;
    trae-cn) printf '%s' "$HOME/.trae-cn/skills" ;;
    kimi-cli) printf '%s' "$config_home/agents/skills" ;;
    universal) printf '%s' "$config_home/agents/skills" ;;
    *) printf '%s' "$HOME/.$agent/skills" ;;
  esac
}

project_skill_dir() {
  agent=$(normalize_agent "$1")
  case "$agent" in
    claude-code) printf '%s' "$ROOT_DIR/.claude/skills" ;;
    trae|trae-cn) printf '%s' "$ROOT_DIR/.trae/skills" ;;
    *) printf '%s' "$ROOT_DIR/.agents/skills" ;;
  esac
}

run_cli() {
  [ -x "$CLI" ] || die "skill-spark executable not found at $CLI. Build it first."
  "$CLI" "$@"
}

remove_paths() {
  for agent in $AGENTS; do
    if [ "$SCOPE" = "system" ] || [ "$SCOPE" = "global" ]; then
      base=$(global_skill_dir "$agent")
    else
      base=$(project_skill_dir "$agent")
    fi
    for skill in $SKILLS; do
      rm -rf "$base/$skill"
      echo "Removed $base/$skill"
    done
  done
}

remove_global_lock() {
  lock="$HOME/.skill-spark/skills.lock"
  [ -f "$lock" ] || return 0
  python3 - "$lock" $SKILLS <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
skills = sys.argv[2:]
try:
    data = json.loads(path.read_text())
except Exception:
    sys.exit(0)

entries = data.get("skills") or {}
for skill in skills:
    entries.pop(f"skill:{skill.lower()}", None)

if entries:
    data["skills"] = entries
    path.write_text(json.dumps(data, indent=2) + "\n")
else:
    path.unlink(missing_ok=True)
PY
}

verify_paths() {
  missing=0
  for agent in $AGENTS; do
    if [ "$SCOPE" = "system" ] || [ "$SCOPE" = "global" ]; then
      base=$(global_skill_dir "$agent")
    else
      base=$(project_skill_dir "$agent")
    fi
    for skill in $SKILLS; do
      if [ -f "$base/$skill/SKILL.md" ]; then
        echo "OK: $base/$skill/SKILL.md"
      else
        echo "Missing: $base/$skill/SKILL.md" >&2
        missing=1
      fi
    done
  done
  return "$missing"
}

install_git_hooks() {
  hooks_dir=$(git rev-parse --git-path hooks 2>/dev/null || true)
  if [ -z "$hooks_dir" ]; then
    echo "Not a git repository; skip git hooks" >&2
    return 1
  fi
  mkdir -p "$hooks_dir"
  src_dir="$ROOT_DIR/.agents/skills/git-workflow/hooks"
  [ -d "$src_dir" ] || src_dir="$ROOT_DIR/skills/devops/git-workflow/hooks"
  for hook in prepare-commit-msg post-commit; do
    if [ -f "$src_dir/$hook" ]; then
      cp "$src_dir/$hook" "$hooks_dir/$hook"
      chmod +x "$hooks_dir/$hook"
      echo "OK: $hooks_dir/$hook"
    fi
  done
}

install_claude_hook() {
  mkdir -p "$ROOT_DIR/.claude"
  settings="$ROOT_DIR/.claude/settings.json"
  hook_cmd="bash .agents/skills/git-workflow/hooks/claude-auto-issue.sh"
  if [ ! -f "$ROOT_DIR/.agents/skills/git-workflow/hooks/claude-auto-issue.sh" ] && [ -f "$ROOT_DIR/.claude/skills/git-workflow/hooks/claude-auto-issue.sh" ]; then
    hook_cmd="bash .claude/skills/git-workflow/hooks/claude-auto-issue.sh"
  fi
  python3 - "$settings" "$hook_cmd" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
hook_cmd = sys.argv[2]
if path.exists():
    try:
        settings = json.loads(path.read_text())
    except Exception:
        settings = {}
else:
    settings = {}

settings.setdefault("hooks", {})
settings["hooks"]["UserPromptSubmit"] = [
    {
        "matcher": "*",
        "hooks": [
            {
                "type": "command",
                "command": hook_cmd,
                "timeout": 10,
            }
        ],
    }
]
path.write_text(json.dumps(settings, indent=2) + "\n")
PY
  echo "OK: $settings UserPromptSubmit -> $hook_cmd"
}

diagnose_hooks() {
  echo "Hook diagnosis:"
  echo "- Codex project skills: $ROOT_DIR/.agents/skills"
  if [ -f "$ROOT_DIR/.agents/skills/git-workflow/SKILL.md" ]; then
    echo "  OK: git-workflow installed for Codex/universal agents"
  else
    echo "  Missing: .agents/skills/git-workflow/SKILL.md"
  fi
  if [ -f "$ROOT_DIR/.claude/settings.json" ]; then
    echo "  OK: .claude/settings.json exists"
  else
    echo "  Missing: .claude/settings.json (Claude Code hook is not installed)"
  fi
  hooks_dir=$(git rev-parse --git-path hooks 2>/dev/null || true)
  if [ -n "$hooks_dir" ]; then
    echo "- Git hooks dir: $hooks_dir"
    for hook in prepare-commit-msg post-commit; do
      if [ -f "$hooks_dir/$hook" ]; then
        echo "  OK: $hook"
      else
        echo "  Missing: $hook"
      fi
    done
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    install|add|remove|delete|update|outdated|status|hooks|list|verify|doctor)
      ACTION="$1"
      shift
      ;;
    --scope)
      [ $# -gt 1 ] || die "--scope requires a value"
      SCOPE="$2"
      shift 2
      ;;
    --global|--system)
      SCOPE="system"
      shift
      ;;
    --project)
      SCOPE="project"
      shift
      ;;
    --agent)
      [ $# -gt 1 ] || die "--agent requires a value"
      if [ "$AGENTS_CUSTOM" -eq 0 ]; then
        AGENTS=""
        AGENTS_CUSTOM=1
      fi
      AGENTS=$(append_word "$AGENTS" "$(normalize_agent "$2")")
      shift 2
      ;;
    --skill)
      [ $# -gt 1 ] || die "--skill requires a value"
      if [ "$SKILLS_CUSTOM" -eq 0 ]; then
        SKILLS=""
        SKILLS_CUSTOM=1
      fi
      SKILLS=$(append_word "$SKILLS" "$2")
      shift 2
      ;;
    --all-devops)
      SKILLS=""
      ALL_DEVOPS=1
      shift
      ;;
    --no-symlink)
      NO_SYMLINK="--no-symlink"
      shift
      ;;
    --force)
      FORCE="--force"
      YES=""
      shift
      ;;
    -y|--yes)
      YES="--yes"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

case "$SCOPE" in
  project|system|global) ;;
  *) die "--scope must be project or system/global" ;;
esac

GLOBAL_FLAG=""
if [ "$SCOPE" = "system" ] || [ "$SCOPE" = "global" ]; then
  GLOBAL_FLAG="--global"
fi

AGENT_ARGS=""
for agent in $AGENTS; do
  AGENT_ARGS=$(append_word "$AGENT_ARGS" "--agent")
  AGENT_ARGS=$(append_word "$AGENT_ARGS" "$agent")
done

SKILL_ARGS=""
for skill in $SKILLS; do
  SKILL_ARGS=$(append_word "$SKILL_ARGS" "--skill")
  SKILL_ARGS=$(append_word "$SKILL_ARGS" "$skill")
done

cd "$ROOT_DIR"

if [ "$ALL_DEVOPS" -eq 1 ] && [ "$ACTION" != "install" ] && [ "$ACTION" != "add" ] && [ "$ACTION" != "list" ]; then
  SKILLS="$ALL_DEVOPS_SKILLS"
fi

case "$ACTION" in
  install|add)
    # shellcheck disable=SC2086
    run_cli add "$SOURCE" $GLOBAL_FLAG $AGENT_ARGS $SKILL_ARGS $YES $FORCE $NO_SYMLINK
    ;;
  remove|delete)
    if [ "$SCOPE" = "project" ]; then
      # shellcheck disable=SC2086
      run_cli remove $SKILLS $YES $FORCE --silent || true
    else
      remove_global_lock
    fi
    remove_paths
    ;;
  update)
    # shellcheck disable=SC2086
    run_cli update $SKILLS $YES $FORCE
    ;;
  outdated|status)
    # shellcheck disable=SC2086
    run_cli outdated $SKILLS
    ;;
  hooks)
    diagnose_hooks
    install_git_hooks || true
    for agent in $AGENTS; do
      if [ "$agent" = "claude-code" ] || [ "$agent" = "claude" ]; then
        install_claude_hook
      fi
    done
    ;;
  list)
    run_cli add "$SOURCE" --list --silent
    ;;
  verify|doctor)
    run_cli doctor
    python3 skills/meta/skill-creator/scripts/quick_validate.py skills/devops/git-workflow
    python3 skills/meta/skill-creator/scripts/quick_validate.py skills/devops/local-workflow
    verify_paths
    ;;
esac
