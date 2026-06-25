# Agents

This document lists the AI coding agents supported by skill-spark and their skill/command directories.

## No-Hook Workflow Control

Hooks are optional. In Codex and other agents that read project instructions plus `.agents/skills`, prefer this no-hook control path:

- When the user asks to execute, implement, run, or complete a task with GitHub Issue tracking, use `git-workflow`.
- When the user asks for local/offline/no GitHub tracking, use `local-workflow`.
- For GitHub mode, run `python3 .agents/skills/git-workflow/scripts/orchestrate.py init --title "<task title>" --description "<task description>"` before implementation.
- After implementation and checks, run `python3 .agents/skills/git-workflow/scripts/orchestrate.py finish --agent-expansion "<scope/questions/acceptance>" --plan "<plan>" --execution "<execution notes/tests>" --message "<completion summary>"`.
- Do not require Claude/Kimi/Git hooks for this workflow. Hooks only provide optional reminders or commit event logs.

## Universal Agents

These agents share the same `.agents/skills` directory:

| Agent | Skills Directory | Commands Directory |
|-------|-----------------|-------------------|
| Amp | `.agents/skills` | — |
| Claude Code | `.claude/skills` | `.claude/commands` |
| Cline | `.agents/skills` | — |
| Codex | `.agents/skills` | — |
| Cursor | `.agents/skills` | — |
| Gemini CLI | `.agents/skills` | — |
| GitHub Copilot | `.agents/skills` | — |
| Kimi CLI | `.agents/skills` | — |
| OpenCode | `.agents/skills` | `.opencode/commands` |
| Replit | `.agents/skills` | — |

## Agent-Specific Directories

### Antigravity
- **Skills**: `.agent/skills`
- **Global**: `~/.gemini/antigravity/skills`

### Augment
- **Skills**: `.augment/skills`
- **Global**: `~/.augment/skills`

### CodeBuddy
- **Skills**: `.codebuddy/skills`
- **Global**: `~/.codebuddy/skills`

### Command Code
- **Skills**: `.commandcode/skills`
- **Global**: `~/.commandcode/skills`

### Continue
- **Skills**: `.continue/skills`
- **Global**: `~/.continue/skills`

### Cortex Code
- **Skills**: `.cortex/skills`
- **Global**: `~/.snowflake/cortex/skills`

### Crush
- **Skills**: `.crush/skills`
- **Global**: `~/.config/crush/skills`

### Droid
- **Skills**: `.factory/skills`
- **Commands**: `.factory/commands`
- **Global**: `~/.factory/skills`, `~/.factory/commands`

### Goose
- **Skills**: `.goose/skills`
- **Global**: `~/.config/goose/skills`

### Junie
- **Skills**: `.junie/skills`
- **Global**: `~/.junie/skills`

### iFlow CLI
- **Skills**: `.iflow/skills`
- **Global**: `~/.iflow/skills`

### Kilo Code
- **Skills**: `.kilocode/skills`
- **Global**: `~/.kilocode/skills`

### Kiro CLI
- **Skills**: `.kiro/skills`
- **Global**: `~/.kiro/skills`

### Kode
- **Skills**: `.kode/skills`
- **Global**: `~/.kode/skills`

### Letta
- **Skills**: `.skills`
- **Global**: `~/.letta/skills`

### MCPJam
- **Skills**: `.mcpjam/skills`
- **Global**: `~/.mcpjam/skills`

### Mistral Vibe
- **Skills**: `.vibe/skills`
- **Global**: `~/.vibe/skills`

### Mux
- **Skills**: `.mux/skills`
- **Global**: `~/.mux/skills`

### OpenHands
- **Skills**: `.openhands/skills`
- **Global**: `~/.openhands/skills`

### Pi
- **Skills**: `.pi/skills`
- **Global**: `~/.pi/agent/skills`

### Qoder
- **Skills**: `.qoder/skills`
- **Global**: `~/.qoder/skills`

### Qwen Code
- **Skills**: `.qwen/skills`
- **Global**: `~/.qwen/skills`

### Roo Code
- **Skills**: `.roo/skills`
- **Global**: `~/.roo/skills`

### Trae
- **Skills**: `.trae/skills`
- **Global**: `~/.trae/skills`

### Trae CN
- **Skills**: `.trae/skills`
- **Global**: `~/.trae-cn/skills`

### Windsurf
- **Skills**: `.windsurf/skills`
- **Global**: `~/.codeium/windsurf/skills`

### Zencoder
- **Skills**: `.zencoder/skills`
- **Global**: `~/.zencoder/skills`

### Neovate
- **Skills**: `.neovate/skills`
- **Global**: `~/.neovate/skills`

### Pochi
- **Skills**: `.pochi/skills`
- **Global**: `~/.pochi/skills`

### AdaL
- **Skills**: `.adal/skills`
- **Global**: `~/.adal/skills`

## Global Installation Paths

Global skills are installed in user-level directories:

- **Linux/macOS**: `~/.skill-spark/`
- **Windows**: `%USERPROFILE%/.skill-spark/`

## Commands Support

Only the following agents support command installation:

| Agent | Commands Directory |
|-------|-------------------|
| Claude Code | `.claude/commands` |
| Droid | `.factory/commands` |
| OpenCode | `.opencode/commands` |

## Using with skill-spark

```bash
# Install for specific agents
skill-spark add <source> --agent claude-code --agent cursor

# Install globally
skill-spark add <source> --global

# Map skills between agents
skill-spark map --target gemini --universal
```

## Notes

- Project-level installations use `./skills.lock`
- Global installations use `~/.skill-spark/skills.lock`
- Universal folder (`.agents/skills`) is shared by multiple agents
