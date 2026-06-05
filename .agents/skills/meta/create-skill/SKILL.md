---
name: create-skill
description: >
  Use when the user asks to create a new skill, write a skill template,
  or add a skill to the project. Guides the user through skill creation
  and generates properly formatted SKILL.md files.
---

# /create-skill — Create a New Skill

Create a new skill by interviewing the user and generating a `SKILL.md` file.

## Process

### 1. Gather Requirements

Ask the user **one question at a time** until you have enough information:

1. **What should this skill do?**
   - Ask for the skill's purpose and main functionality.
   - If the user is vague, ask follow-ups.

2. **When should it activate?**
   - Slash command trigger? (e.g., `/deploy`)
   - Natural language trigger? (e.g., "when asked about X")
   - Both?

3. **What commands, tools, or APIs does it use?**
   - Shell commands?
   - External CLIs?
   - Internal project scripts?
   - Specific tools the agent should use?

4. **Any specific rules or constraints?**
   - Must-do steps?
   - Never-do items?
   - Output format requirements?

5. **Complexity level?**
   - Simple: single `SKILL.md`
   - Medium: `SKILL.md` with `allowed-tools` restriction
   - Complex: directory with `metadata.json` and extra files

### 2. Determine Location

Decide where to place the skill:

| Scope | Path |
|-------|------|
| Project (universal) | `.agents/skills/{name}/SKILL.md` |
| Claude Code only | `.claude/skills/{name}/SKILL.md` |
| Global | `~/.skill-spark/.agents/skills/{name}/SKILL.md` |

Default to **project scope** (`.agents/skills/`) unless the user specifies otherwise.

### 3. Generate SKILL.md

Use the following structure. Adapt sections based on the skill's needs — remove irrelevant ones, add custom ones.

```markdown
---
name: {kebab-case-name}
description: >
  {When to use this skill. Be specific.}
---

# /{name} — {Title}

## Overview

{What this skill does.}

## When to Use

- When the user types `/{trigger}`
- When the user asks to {action}
- When {situation}

## Workflow

1. **{Step 1}**: {Description}
2. **{Step 2}**: {Description}
3. **{Step 3}**: {Description}

## Commands

```bash
{example commands}
```

## Rules

- {Rule one}
- {Rule two}

## Notes

- {Note or caveat}
```

### Frontmatter Rules

- `name`: kebab-case, unique, short
- `description`: >
  - Start with "Use when..." or action verb
  - Mention trigger conditions
  - Keep to 1–3 sentences
- `allowed-tools`: only add if the skill needs tool restrictions

### Content Rules

- Use `##` for top-level sections
- Use `###` for sub-sections
- Use fenced code blocks with language tags
- Use bold for emphasis on critical steps
- Use bullet lists for rules and notes
- Keep descriptions concise — agents read this at runtime

### 4. Create Files

1. Create the directory: `{skills-dir}/{name}/`
2. Write `SKILL.md`
3. If complex, also write `metadata.json`:

```json
{
  "name": "{name}",
  "category": "{devops|product|development|tools|other}",
  "author": "{author}",
  "source": "{source-url-or-local}"
}
```

### 5. Confirm

Show the user:
- The full path of the created skill
- A summary of what it does
- How to trigger it
- Ask if they want to edit anything

## Examples by Complexity

### Simple Skill

Single file, no restrictions. Example: `control-flow`

### Medium Skill

Single file with `allowed-tools`. Example: `agent-browser`

```yaml
---
name: my-tool
description: Uses my-tool CLI.
allowed-tools: Bash(my-tool:*), Bash(npx my-tool:*)
---
```

### Complex Skill

Directory with metadata. Example: `brainstorm-beagle`

```
my-skill/
├── SKILL.md
└── metadata.json
```

## Validation Checklist

Before finishing, verify:

- [ ] `name` is kebab-case
- [ ] `description` mentions when to use the skill
- [ ] At least one trigger condition is documented
- [ ] Workflow steps are clear and actionable
- [ ] Code examples use correct syntax
- [ ] Rules are specific (not generic platitudes)
- [ ] File is saved to the correct path
