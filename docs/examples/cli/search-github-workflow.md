# Search GitHub Workflow Skills with Skill Spark CLI

This guide demonstrates how to use `skill-spark` to search for skills related to GitHub workflow topics.

## Prerequisites

- [Bun](https://bun.sh) runtime installed
- `skill-spark` CLI available. Prefer `./dist/skill-spark` from the project root; run `bun run build:all` first if it does not exist.

## Basic Search

Search for skills matching the "github workflow" keyword. Results are merged from two sources: the skills registry (`skillsdirectory.com`) and the flins directory:

```bash
./dist/skill-spark search "github workflow"
```

Output:

```
Found 10 skills (registry: 10)
  Github Automation ...
  Github Workflow Automation ...
  ...
```

## Advanced Search Options

### Filter by Category

Narrow results to a specific category (e.g., `devops`, `development`, `tools`):

```bash
./dist/skill-spark search "github workflow" --category devops
```

### Control Result Count

Adjust the number of results per page (max 100):

```bash
./dist/skill-spark search "github workflow" --limit 10
```

### Paginate Results

Use `--offset` for paginated browsing:

```bash
./dist/skill-spark search "github workflow" --limit 5 --offset 10
```

### Sort Results

Sort by different criteria:

```bash
# Sort by most starred
./dist/skill-spark search "github workflow" --sort stars

# Sort by most recent
./dist/skill-spark search "github workflow" --sort recent

# Sort by votes
./dist/skill-spark search "github workflow" --sort votes
```

### Combine Multiple Options

```bash
./dist/skill-spark search "github workflow" \
  --category devops \
  --limit 10 \
  --sort stars
```

### Use a Custom Registry

Override the default registry URL:

```bash
./dist/skill-spark search "github workflow" --registry https://custom.registry.com/api
```

Or set via environment variable:

```bash
export FIRE_SKILL_REGISTRY_URL="https://custom.registry.com/api"
./dist/skill-spark search "github workflow"
```

## Save Results to File

Export search results as JSON to a file:

```bash
./dist/skill-spark search "github workflow" -o results.json
./dist/skill-spark search "github workflow" --limit 5 --sort stars -o /tmp/output.json
```

Output file structure:

```json
{
  "query": "github workflow",
  "registry": 3,
  "directory": 0,
  "total": 3,
  "skills": [
    {
      "schemaVersion": "1",
      "slug": "ruvnet-github-automation",
      "name": "Github Automation",
      "description": "GitHub workflow automation, PR management...",
      "repository": "ruvnet/ruflo",
      "stars": 55216,
      "tags": ["bash", "code-review", "git", "ci/cd"],
      "author": { "name": "ruvnet" }
    }
  ]
}
```

## Interactive Browse Mode

Omit the query string to enter interactive TUI browse mode, where you can filter and multi-select skills for installation:

```bash
./dist/skill-spark search
```

Use the arrow keys to navigate, type to filter, space to select/deselect, and Enter to install selected skills.

## Related Search Queries

For broader coverage of GitHub workflow topics, try these related queries:

```bash
# CI/CD pipeline skills
./dist/skill-spark search "ci cd pipeline"

# GitHub Actions skills
./dist/skill-spark search "github actions"

# DevOps automation skills
./dist/skill-spark search "devops automation"

# Deployment workflow skills
./dist/skill-spark search "deployment workflow"
```
