#!/bin/bash
# Kimi CLI Hook: Auto-update the active issue when the session ends.
# Install: reference this script in ~/.kimi/config.toml under [[hooks]] event = "Stop"

read JSON

# Check if stop hook is already active (prevents infinite loops)
IS_ACTIVE=$(echo "$JSON" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('stop_hook_active', False))
")

if [ "$IS_ACTIVE" = "True" ]; then
    exit 0
fi

REPO_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_DIR" ]; then
    exit 0
fi

# Resolve skill directory
SKILL_DIR="$REPO_DIR/.kimi/skills/git-workflow"
if [ ! -d "$SKILL_DIR" ]; then
    SKILL_DIR="$HOME/.kimi/skills/git-workflow"
fi
if [ ! -d "$SKILL_DIR" ]; then
    SKILL_DIR="$HOME/.claude/skills/git-workflow"
fi
if [ ! -d "$SKILL_DIR" ]; then
    SKILL_DIR="$HOME/.config/agents/skills/git-workflow"
fi
if [ ! -d "$SKILL_DIR" ]; then
    exit 0
fi

# Find the active issue from git-workflow state file
ISSUE_FILE="$REPO_DIR/.git-workflow.state.json"
if [ ! -f "$ISSUE_FILE" ]; then
    exit 0
fi

ISSUE=$(python3 -c "import json; print(json.load(open('$ISSUE_FILE')).get('issue', ''))")
if [ -z "$ISSUE" ]; then
    exit 0
fi

cd "$REPO_DIR" || exit 0

# Use gh CLI to comment on the issue
gh issue comment "$ISSUE" \
  --body "### Session Completed\n\nAssociated CLI session has ended." \
  > /dev/null 2>&1

exit 0
