#!/usr/bin/env python3
"""Local Task Tracing for git-workflow.

Records task execution locally in tasks/tracing/ alongside GitHub Issues.

Usage:
    python tracing.py init --issue <number> [--parsed "..."]
    python tracing.py finish --issue <number> [--summary "..."]
    python tracing.py status
"""

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

TRACING_DIR = Path("tasks/tracing")
STATE_FILE = Path(".git-workflow.state.json")


def _ensure_dir():
    TRACING_DIR.mkdir(parents=True, exist_ok=True)


def _tracing_file(issue_number: int) -> Path:
    return TRACING_DIR / f"issue-{issue_number}.md"


def _read_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text(encoding="utf-8"))
    return {}


def cmd_init(args):
    """Initialize tracing record for a GitHub issue."""
    _ensure_dir()

    state = _read_state()
    issue_number = args.issue or state.get("issue")
    title = args.title or state.get("title", f"Issue #{issue_number}")
    description = args.description or state.get("description", "")

    if not issue_number:
        print("Error: No issue number found. Provide --issue or run orchestrate.py init first.", file=sys.stderr)
        sys.exit(1)

    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    tracing_file = _tracing_file(issue_number)

    content = f"# Tracing: {title}\n\n"
    content += f"## Task Entry ({now})\n\n"
    content += f"- **Issue**: #{issue_number}\n"
    content += f"- **Title**: {title}\n"
    content += f"- **Started At**: {now}\n"
    content += f"- **Status**: in_progress\n\n"

    if description:
        content += "### Original Task Description\n\n"
        content += "```markdown\n"
        content += description.strip() + "\n"
        content += "```\n\n"

    if args.parsed:
        content += "### Agent Parsed Content\n\n"
        content += args.parsed.strip() + "\n\n"

    tracing_file.write_text(content, encoding="utf-8")
    print(f"Tracing initialized: {tracing_file}")


def cmd_finish(args):
    """Mark tracing record as completed."""
    state = _read_state()
    issue_number = args.issue or state.get("issue")
    title = args.title or state.get("title", f"Issue #{issue_number}")

    if not issue_number:
        print("Error: No issue number found. Provide --issue or run orchestrate.py init first.", file=sys.stderr)
        sys.exit(1)

    tracing_file = _tracing_file(issue_number)

    if not tracing_file.exists():
        # Create a minimal tracing file if init wasn't called
        _ensure_dir()
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        content = f"# Tracing: {title}\n\n"
        content += f"## Task Entry ({now})\n\n"
        content += f"- **Issue**: #{issue_number}\n"
        content += f"- **Title**: {title}\n"
        content += f"- **Status**: completed\n"
        content += f"- **Completed At**: {now}\n\n"
        tracing_file.write_text(content, encoding="utf-8")
    else:
        content = tracing_file.read_text(encoding="utf-8")
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        content = content.replace("- **Status**: in_progress", "- **Status**: completed")
        content = content.rstrip() + f"\n- **Completed At**: {now}\n"

        if args.summary:
            content += f"\n### Implementation Summary\n\n"
            content += args.summary.strip() + "\n\n"

        tracing_file.write_text(content, encoding="utf-8")

    print(f"Tracing updated: {tracing_file}")


def cmd_status(_args):
    """Show all tracing records."""
    if not TRACING_DIR.exists():
        print("No tracing directory found.")
        return

    files = sorted(TRACING_DIR.glob("issue-*.md"))
    if not files:
        print("No tracing records found.")
        return

    print(f"Tracing records ({len(files)}):\n")
    for f in files:
        text = f.read_text(encoding="utf-8")
        status = "unknown"
        title = f.stem
        for line in text.split("\n"):
            if "**Status**:" in line:
                status = line.split("**Status**:")[1].strip()
            if "**Title**:" in line:
                title = line.split("**Title**:")[1].strip()
        print(f"  - {f.name}: {title} [{status}]")


def main():
    parser = argparse.ArgumentParser(description="Local Task Tracing for git-workflow")
    sub = parser.add_subparsers(dest="cmd", help="Available commands")

    p_init = sub.add_parser("init", help="Initialize tracing record")
    p_init.add_argument("--issue", type=int, help="Issue number")
    p_init.add_argument("--title", help="Task title")
    p_init.add_argument("--description", help="Task description")
    p_init.add_argument("--parsed", help="Agent-parsed content")

    p_finish = sub.add_parser("finish", help="Mark tracing as completed")
    p_finish.add_argument("--issue", type=int, help="Issue number")
    p_finish.add_argument("--title", help="Task title")
    p_finish.add_argument("--summary", help="Implementation summary")

    sub.add_parser("status", help="Show all tracing records")

    args = parser.parse_args()

    handlers = {
        "init": cmd_init,
        "finish": cmd_finish,
        "status": cmd_status,
    }

    handler = handlers.get(args.cmd)
    if not handler:
        parser.print_help()
        sys.exit(1)

    handler(args)


if __name__ == "__main__":
    main()
