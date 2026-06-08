#!/bin/bash
# Claude Code Hook: Auto-suggest git-workflow when task execution is detected.
# Install: add to .claude/settings.json under hooks.UserPromptSubmit
#
# Input (stdin JSON): { "prompt": "...", ... }
# Output: additional context JSON appended to conversation, or silent exit.

read -r JSON 2>/dev/null || exit 0

# Extract the prompt text
PROMPT=$(echo "$JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('prompt', ''))
except:
    print('')
" 2>/dev/null)

if [ -z "$PROMPT" ]; then
    exit 0
fi

# Detect task execution patterns in multiple languages
# Patterns: "execute task", "执行任务", "执行 Task", "run task", "implement task",
#           "Task N:", "Task N ", "complete task", "完成任务"
MATCH=$(echo "$PROMPT" | python3 -c "
import sys, re
prompt = sys.stdin.read().lower()
patterns = [
    r'执行\s*(task|任务)',
    r'execute\s*(task|任务)',
    r'run\s*task',
    r'implement\s*task',
    r'complete\s*task',
    r'完成任务',
    r'task\s*\d+[\s:]',
    r'@tasks[/\\\\]',
    r'please\s+(execute|run|do|complete)\s+task',
]
for p in patterns:
    if re.search(p, prompt):
        print('match')
        break
" 2>/dev/null)

if [ "$MATCH" != "match" ]; then
    exit 0
fi

# Output additional context telling Claude to use git-workflow
cat <<'CTX'
{"additionalContext": "IMPORTANT: The user is asking to execute a task with GitHub Issue tracking. Use the git-workflow skill when GitHub tracking is intended. Follow these steps:\n1. Run INIT: python3 .agents/skills/git-workflow/scripts/orchestrate.py init --title \"<task title>\" --description \"<task description>\"\n2. PLAN: create a lightweight task expansion, assumptions, acceptance criteria, and implementation plan\n3. IMPLEMENT: execute the actual task work and run checks\n4. Run FINISH: python3 .agents/skills/git-workflow/scripts/orchestrate.py finish --agent-expansion \"<scope/questions/acceptance>\" --plan \"<plan>\" --execution \"<execution notes/tests>\" --message \"<completion summary>\"\nThis creates a GitHub Issue, keeps the Issue body as the canonical workflow record, and closes the issue automatically. If the user asks for local-only/offline workflow, use local-workflow instead."}
CTX
