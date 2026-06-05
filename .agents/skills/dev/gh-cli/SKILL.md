---
name: gh-cli
description: >
  GitHub CLI (gh) usage guide. Use when the user asks about GitHub operations
  from the terminal — PRs, issues, repos, releases, workflows, or searching
  GitHub for skills and repositories. Triggers on "gh", "github cli", or any
  GitHub terminal workflow question.
---

# /gh-cli — GitHub CLI Workflows

Use the `gh` command-line tool for all GitHub operations. Prefer `gh` over web UI or curl when working from the terminal.

## Quick Reference

```bash
# Authentication
gh auth status                    # Check login state
gh auth login                     # Interactive login
gh auth switch                    # Switch GitHub accounts

# Repository
gh repo view                      # Show current repo info
gh repo clone owner/repo          # Clone a repo
gh repo fork                      # Fork current repo
gh repo list owner                # List repos for a user/org

# Pull Requests
gh pr list                        # List open PRs
gh pr view 123                    # View PR details
gh pr checkout 123                # Check out a PR branch
gh pr create --fill               # Create PR using commit messages
gh pr merge 123 --squash          # Merge PR
gh pr checks 123                  # View CI checks

# Issues
gh issue list                     # List open issues
gh issue view 42                  # View issue details
gh issue create --title "..."     # Create issue
gh issue close 42                 # Close issue

# Releases
gh release list                   # List releases
gh release view v1.0.0            # View release
gh release create v1.0.0          # Create release (interactive)

# Actions / Workflows
gh workflow list                  # List workflows
gh workflow run deploy.yml        # Trigger workflow
gh run list                       # List recent runs
gh run view 1234567890            # View run logs

# Search
gh search repos "topic:ai"        # Search repositories
gh search code "func main"        # Search code
gh search issues "is:open label:bug"  # Search issues
```

## Querying GitHub for Skills

When searching for skills, tools, or reusable configurations on GitHub:

```bash
# Search for skill-related repos
gh search repos "skill-spark" --sort stars
gh search repos "claude-code skill" --sort stars
gh search repos "topic:ai-agent-skill"

# Search within a known org
gh search repos "topic:skill" --owner=slopus

# List files in a repo's skills directory
gh api repos/owner/repo/contents/.agents/skills --jq '.[].name'

# View a specific skill file
gh api repos/owner/repo/contents/.agents/skills/my-skill/SKILL.md \
  --jq '.content' | base64 -d
```

## Common Patterns

### Daily Workflow

```bash
# Start the day
git pull
gh pr list --author @me        # Check my PRs
gh pr list --review-requested @me  # Check reviews needed

# Create and submit work
git checkout -b feat/my-branch
git commit -am "Add feature"
git push -u origin feat/my-branch
gh pr create --fill --web      # Create PR and open in browser
```

### Review a PR

```bash
gh pr view 123                  # Overview
gh pr diff 123                  # View diff
gh pr checks 123                # CI status
gh pr review 123 --approve      # Approve
gh pr review 123 --request-changes --body "..."
```

### Bulk Operations

```bash
# Close all stale issues with a label
gh issue list --label stale --json number --jq '.[].number' | \
  xargs -I {} gh issue close {} --reason "not planned"

# Download all release assets
gh release view v1.0.0 --json assets --jq '.assets[].url' | \
  xargs -I {} curl -L -O {}
```

## Rules

- Always check `gh auth status` before operations that require authentication
- Use `--json` + `--jq` for scripting instead of parsing human output
- Prefer `gh pr create --fill` over manual title/body when commits are descriptive
- Use `gh api` for GraphQL or REST operations not covered by top-level commands
- For CI debugging, `gh run view --log-failed` shows only failed steps
