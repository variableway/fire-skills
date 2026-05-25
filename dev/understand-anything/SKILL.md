---
name: understand-anything
description: |
  Turn any codebase, knowledge base, or docs into an interactive knowledge graph you can explore, search, and ask questions about.
  TRIGGER: When user asks to "analyze codebase", "understand project", "explore code graph", 
  "build knowledge graph", or wants to understand a complex codebase.
type: skill
supported_agents:
  - claude-code
  - kimi
  - codex
  - opencode
  - trae
  - trae-solo
  - workbuddy
triggers:
  - pattern: "understand.*code"
  - pattern: "analyze.*codebase"
  - pattern: "knowledge graph"
  - pattern: "explore.*code"
  - pattern: "understand.*project"
tags:
  - code-analysis
  - knowledge-graph
  - visualization
  - exploration
---

# Understand Anything

Turn any codebase, knowledge base, or docs into an interactive knowledge graph you can explore, search, and ask questions about.

## Quick Install (Auto-Install)

### One-Command Installation

```bash
cd dev/understand-anything && ./scripts/install-plugin.sh
```

This will automatically:
1. Clone the plugin from GitHub
2. Build the plugin (requires Node.js >= 22, pnpm >= 10)
3. Install to Claude Code plugin cache
4. Link skill to Claude/Trae skills directories

### Installation Options

```bash
# Install for Claude Code only
./scripts/install-plugin.sh --claude

# Install for Trae only
./scripts/install-plugin.sh --trae

# Install without building (use pre-built if available)
./scripts/install-plugin.sh --skip-build
```

### Prerequisites

- **Node.js >= 22** (developed on v24)
- **pnpm >= 10** (pinned via `packageManager` field in root `package.json`)
- **git**

On macOS:
```bash
brew install node pnpm
```

## Commands

### `/understand`

Analyze the current codebase and build a knowledge graph.

```
/understand
```

Multi-agent pipeline scans your project, extracts every file, function, class, and dependency, then builds a knowledge graph saved to `.understand-anything/knowledge-graph.json`.

**Options:**
- `--auto-update` - Enable post-commit hook to incrementally update the graph
- `--review` - Run full LLM review for graph validation
- `--full` - Force full rebuild (bypass cache)

### `/understand-dashboard`

Open interactive web dashboard to explore the knowledge graph.

```
/understand-dashboard
```

An interactive web dashboard opens with your codebase visualized as a graph — color-coded by architectural layer, searchable, and clickable.

### `/understand-chat`

Ask questions about the codebase.

```
/understand-chat How does the payment flow work?
```

### `/understand-diff`

Analyze impact of your current changes.

```
/understand-diff
```

### `/understand-explain`

Deep-dive into a specific file or function.

```
/understand-explain src/auth/login.ts
```

### `/understand-onboard`

Generate an onboarding guide for new team members.

```
/understand-onboard
```

### `/understand-domain`

Extract business domain knowledge (domains, flows, steps).

```
/understand-domain
```

### `/understand-knowledge`

Analyze a Karpathy-pattern LLM wiki knowledge base.

```
/understand-knowledge ~/path/to/wiki
```

## Features

| Feature | Description |
|---------|-------------|
| **Graph Exploration** | Navigate codebase as interactive knowledge graph |
| **Guided Tours** | Auto-generated walkthroughs ordered by dependency |
| **Fuzzy & Semantic Search** | Find anything by name or by meaning |
| **Diff Impact Analysis** | See which parts your changes affect |
| **Domain Analysis** | Extract business domains, flows, and process steps |
| **Layer Visualization** | Automatic grouping by architectural layer |

## Sharing Graphs

The graph is just JSON — commit it once, and teammates skip the pipeline.

```bash
git add .understand-anything/

# Ignore intermediate files
echo ".understand-anything/intermediate/" >> .gitignore
echo ".understand-anything/diff-overlay.json" >> .gitignore
```

For large graphs (10 MB+), use git-lfs:

```bash
git lfs install
git lfs track ".understand-anything/*.json"
```

## Manual Installation (Alternative)

If the auto-install script doesn't work, you can install manually:

### Claude Code

```
/plugin marketplace add Lum1104/Understand-Anything
/plugin install understand-anything
```

### Trae

```
/plugin marketplace add Lum1104/Understand-Anything
/plugin install understand-anything
```