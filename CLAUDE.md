# Project Instructions

## Task Execution Workflow

When the user asks to **execute a task**, **implement a task**, or **run a task** (e.g., "请执行Task 9", "execute Task 3"), you MUST use the `git-workflow` skill:

1. **INIT** — Create a GitHub Issue:
   ```bash
   python .claude/skills/git-workflow/scripts/orchestrate.py init --title "<task title>" --description "<task description>"
   ```

2. **IMPLEMENT** — Execute the task (code changes, tests, etc.)

3. **FINISH** — Append completion message and close the Issue:
   ```bash
   python .claude/skills/git-workflow/scripts/orchestrate.py finish --message "<completion summary>"
   ```

This applies to all tasks referenced from task files (e.g., `tasks/issues/dev-workflow.md`).

**Do NOT skip the workflow** — always create an Issue first, then close it after completion.


## Local Task Execution Workflow

When the user asks to **execute a task locally** or **use local-workflow** (no GitHub needed), follow:

1. **INIT** — Initialize local tracking:
   ```bash
   python .claude/skills/local-workflow/scripts/orchestrate.py init <task-file.md>
   ```

2. **IMPLEMENT** — Execute the task (code changes, tests, etc.)

3. **FINISH** — Mark task complete and commit:
   ```bash
   python .claude/skills/local-workflow/scripts/orchestrate.py finish
   ```

Tracking records are saved to `tasks/tracing/`. No GitHub Issues required.

