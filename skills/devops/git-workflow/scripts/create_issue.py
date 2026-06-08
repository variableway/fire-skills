#!/usr/bin/env python3
"""Create a GitHub issue from a task description.

Based on github-cli-skill. Uses gh CLI api command for all operations.
Saves workflow state to .git-workflow.state.json.
"""

import argparse
from datetime import datetime, timezone
import json
import re
import subprocess
import sys
from pathlib import Path

STATE_FILE = Path(".git-workflow.state.json")


def run_gh(args: list, check: bool = True) -> subprocess.CompletedProcess:
    """Run a gh CLI command."""
    cmd = ["gh"] + args
    return subprocess.run(cmd, capture_output=True, text=True, check=check)


def get_repo(remote_name: str = "origin") -> str:
    """Detect owner/repo from git remote."""
    try:
        result = subprocess.run(
            ["git", "remote", "get-url", remote_name],
            capture_output=True, text=True, check=True
        )
        remote_url = result.stdout.strip()
        match = re.search(r"github\.com[:/]([\w.-]+/[\w.-]+?)(?:\.git)?$", remote_url)
        if match:
            return match.group(1)
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    return None


def create_issue(repo: str, title: str, body: str, labels: list = None) -> dict:
    """Create a GitHub issue using gh api."""
    fields = [f"title={title}", f"body={body}"]
    if labels:
        for label in labels:
            fields.append(f"labels[]={label}")

    args = ["api", "-X", "POST", f"repos/{repo}/issues"]
    for f in fields:
        args.extend(["-f", f])

    result = run_gh(args)
    if result.returncode != 0:
        raise RuntimeError(f"gh api create issue failed: {result.stderr}")

    return json.loads(result.stdout)


def utc_now() -> str:
    """Return an ISO-8601 UTC timestamp."""
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def build_issue_body(description: str, created_at: str) -> str:
    """Build the canonical issue body used by git-workflow."""
    task = description.strip() or "_No task description provided._"
    return "\n".join([
        "# Task",
        "",
        task,
        "",
        "## Agent Expansion",
        "",
        "_Pending until finish. Record clarified scope, questions, assumptions, and acceptance criteria._",
        "",
        "## Plan",
        "",
        "_Pending until finish._",
        "",
        "## Execution",
        "",
        "_Pending until finish._",
        "",
        "## Result",
        "",
        "_Pending until finish._",
        "",
        "## Metadata",
        "",
        f"- Created at: {created_at}",
        "- Status: open",
    ])


def main():
    parser = argparse.ArgumentParser(
        description="Create a GitHub issue from a task description"
    )
    parser.add_argument("--title", required=True, help="Issue title")
    parser.add_argument("--description", required=True, help="Task description (stored in Issue body)")
    parser.add_argument("--labels", default="task", help="Comma-separated labels")
    parser.add_argument("--repo", help="Repository (owner/repo). Auto-detected from git remote.")
    parser.add_argument("--remote", default="origin", help="Git remote name for auto-detection")
    args = parser.parse_args()

    repo = args.repo or get_repo(args.remote)
    if not repo:
        print("Error: Could not detect repository.", file=sys.stderr)
        print("Please provide --repo or run from a git repo with GitHub remote.", file=sys.stderr)
        sys.exit(1)

    labels = [l.strip() for l in args.labels.split(",")] if args.labels else None

    created_at = utc_now()
    issue_body = build_issue_body(args.description, created_at)
    issue = create_issue(repo, args.title, issue_body, labels)

    state = {
        "issue": issue["number"],
        "repo": repo,
        "description": args.description,
        "title": args.title,
        "created_at": created_at,
        "issue_body": issue_body,
    }
    STATE_FILE.write_text(json.dumps(state, indent=2))

    print(f"Issue #{issue['number']} created: {issue.get('html_url', '')}")
    print("Issue body initialized as the canonical workflow record.")
    print(f"State saved to: {STATE_FILE}")


if __name__ == "__main__":
    main()
