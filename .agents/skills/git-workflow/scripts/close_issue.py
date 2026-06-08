#!/usr/bin/env python3
"""Finalize a GitHub issue by updating its body and closing it.

The Issue body is the canonical workflow record. Finish replaces the pending
sections with the final task expansion, plan, execution notes, and result.

Uses gh CLI api command for all operations.
"""

import argparse
from datetime import datetime, timezone
import json
import subprocess
import sys
from pathlib import Path

STATE_FILE = Path(".git-workflow.state.json")


def run_gh(args: list, check: bool = True) -> subprocess.CompletedProcess:
    """Run a gh CLI command."""
    cmd = ["gh"] + args
    return subprocess.run(cmd, capture_output=True, text=True, check=check)


def get_issue(repo: str, issue_number: int) -> dict:
    """Get an issue using gh api."""
    result = run_gh(["api", f"repos/{repo}/issues/{issue_number}"])
    if result.returncode != 0:
        raise RuntimeError(f"gh api get issue failed: {result.stderr}")
    return json.loads(result.stdout)


def update_issue(repo: str, issue_number: int, body: str, state: str = None) -> dict:
    """Update an issue body and optionally its state."""
    fields = [f"body={body}"]
    if state:
        fields.append(f"state={state}")

    args = ["api", "-X", "PATCH", f"repos/{repo}/issues/{issue_number}"]
    for field in fields:
        args.extend(["-f", field])

    result = run_gh(args)
    if result.returncode != 0:
        raise RuntimeError(f"gh api update issue failed: {result.stderr}")
    return json.loads(result.stdout)


def utc_now() -> str:
    """Return an ISO-8601 UTC timestamp."""
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def value_or_note(value: str, note: str) -> str:
    """Return stripped markdown content or a fallback note."""
    if value and value.strip():
        return value.strip()
    return note


def extract_task_from_body(body: str) -> str:
    """Extract the original task section from a git-workflow Issue body."""
    text = (body or "").strip()
    if not text:
        return ""

    if text.startswith("# Task"):
        text = text[len("# Task"):].lstrip()
        for marker in ["\n## Agent Expansion", "\n## Plan", "\n## Execution", "\n## Result", "\n## Metadata"]:
            if marker in text:
                text = text.split(marker, 1)[0]
                break
    return text.strip()


def merge_execution(execution: str, doc_suggestions: str) -> str:
    """Combine execution notes with generated documentation suggestions."""
    parts = []
    if execution and execution.strip():
        parts.append(execution.strip())
    if doc_suggestions and doc_suggestions.strip():
        parts.append("### Documentation Check\n\n" + doc_suggestions.strip())
    return "\n\n".join(parts)


def build_final_body(state: dict, current_body: str, args) -> str:
    """Build the final canonical Issue body."""
    task = state.get("description") or extract_task_from_body(current_body)
    task = value_or_note(task, "_No task description recorded._")

    metadata = []
    if state.get("title"):
        metadata.append(f"- Title: {state['title']}")
    if state.get("created_at"):
        metadata.append(f"- Created at: {state['created_at']}")
    metadata.extend([
        f"- Completed at: {utc_now()}",
        "- Status: closed",
    ])

    execution = merge_execution(args.execution, args.doc_suggestions)

    return "\n".join([
        "# Task",
        "",
        task,
        "",
        "## Agent Expansion",
        "",
        value_or_note(args.agent_expansion, "_Not recorded._"),
        "",
        "## Plan",
        "",
        value_or_note(args.plan, "_Not recorded._"),
        "",
        "## Execution",
        "",
        value_or_note(execution, "_Not recorded._"),
        "",
        "## Result",
        "",
        value_or_note(args.message, "_No completion summary recorded._"),
        "",
        "## Metadata",
        "",
        "\n".join(metadata),
    ])


def main():
    parser = argparse.ArgumentParser(
        description="Update an issue body with the final workflow record and close it"
    )
    parser.add_argument("--message", required=True, help="Completion summary for the Result section")
    parser.add_argument("--agent-expansion", default="", help="Clarified scope, questions, assumptions, and acceptance criteria")
    parser.add_argument("--plan", default="", help="Plan or task loop summary")
    parser.add_argument("--execution", default="", help="Execution notes, changed areas, checks, or tests")
    parser.add_argument("--doc-suggestions", default="", help=argparse.SUPPRESS)
    parser.add_argument("--issue", type=int, help="Issue number (overrides state file)")
    parser.add_argument("--repo", help="Repository (owner/repo, overrides state file)")
    args = parser.parse_args()

    if STATE_FILE.exists():
        state = json.loads(STATE_FILE.read_text())
    else:
        state = {}

    issue_number = args.issue or state.get("issue")
    repo = args.repo or state.get("repo")

    if not issue_number or not repo:
        print("Error: Issue number and repo required. Provide --issue/--repo or run init first.", file=sys.stderr)
        sys.exit(1)

    issue = get_issue(repo, issue_number)
    new_body = build_final_body(state, issue.get("body", ""), args)
    update_issue(repo, issue_number, new_body, state="closed")

    if STATE_FILE.exists():
        STATE_FILE.unlink()

    print(f"Issue #{issue_number} closed.")
    print("Issue body updated with the final workflow record.")


if __name__ == "__main__":
    main()
