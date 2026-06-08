#!/usr/bin/env python3
"""Create GitHub Issues via gh CLI.

Supports creating issues from a string body or from a file (--body-file).

Usage:
    # Create issue with inline body
    python create_issue.py --title "Bug report" --body "Description here"

    # Create issue from file
    python create_issue.py --title "Bug report" --body-file ./issue-body.md

    # With labels
    python create_issue.py --title "Bug" --body "desc" --labels bug,p0

    # Specify repo
    python create_issue.py --title "Bug" --body "desc" --repo owner/repo
"""

import argparse
import json
import subprocess
import sys


def detect_repo(remote: str = "origin") -> str:
    """Detect GitHub repo (owner/repo) from git remote."""
    try:
        result = subprocess.run(
            ["git", "remote", "get-url", remote],
            capture_output=True, text=True, check=True,
        )
        url = result.stdout.strip()
        # Handle SSH: git@github.com:owner/repo.git
        if url.startswith("git@"):
            url = url.split(":", 1)[1]
        # Handle HTTPS: https://github.com/owner/repo.git
        elif "github.com" in url:
            url = url.split("github.com/", 1)[-1]
        # Strip .git suffix
        if url.endswith(".git"):
            url = url[:-4]
        return url
    except subprocess.CalledProcessError:
        print(f"Error: Could not detect repo from remote '{remote}'", file=sys.stderr)
        sys.exit(1)


def create_issue(
    title: str,
    body: str = None,
    body_file: str = None,
    labels: list = None,
    repo: str = None,
    remote: str = "origin",
) -> str:
    """Create a GitHub Issue and return its URL."""
    if not repo:
        repo = detect_repo(remote)

    if not body and not body_file:
        print("Error: Either --body or --body-file is required", file=sys.stderr)
        sys.exit(1)

    cmd = ["gh", "issue", "create", "--repo", repo, "--title", title]

    if body_file:
        cmd.extend(["--body-file", body_file])
    else:
        cmd.extend(["--body", body])

    if labels:
        for label in labels:
            cmd.extend(["--label", label])

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error creating issue: {result.stderr}", file=sys.stderr)
        sys.exit(1)

    issue_url = result.stdout.strip()
    print(issue_url)

    # Extract issue number from URL
    if "/issues/" in issue_url:
        issue_number = issue_url.split("/issues/")[-1]
        print(f"Issue #{issue_number} created: {issue_url}", file=sys.stderr)

    return issue_url


def main():
    parser = argparse.ArgumentParser(description="Create GitHub Issues via gh CLI")
    parser.add_argument("--title", required=True, help="Issue title")
    parser.add_argument("--body", help="Issue body text")
    parser.add_argument("--body-file", help="File to use as issue body")
    parser.add_argument("--labels", help="Comma-separated labels")
    parser.add_argument("--repo", help="Repository (owner/repo), auto-detected if omitted")
    parser.add_argument("--remote", default="origin", help="Git remote name (default: origin)")

    args = parser.parse_args()

    if args.body and args.body_file:
        print("Error: Cannot use both --body and --body-file", file=sys.stderr)
        sys.exit(1)

    if not args.body and not args.body_file:
        print("Error: Either --body or --body-file is required", file=sys.stderr)
        sys.exit(1)

    labels = args.labels.split(",") if args.labels else None

    create_issue(
        title=args.title,
        body=args.body,
        body_file=args.body_file,
        labels=labels,
        repo=args.repo,
        remote=args.remote,
    )


if __name__ == "__main__":
    main()
