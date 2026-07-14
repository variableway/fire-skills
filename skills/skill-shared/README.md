---
name: Shared
icon: boxes
order: 6
---

# Shared Skills

Cross-cutting skills reused across categories and apps: skill search and app scaffolding.

## Layout

Skills live under `skills/skill-shared/_shared/` so they can be symlinked into many agents without duplication. Each skill is a directory containing a `SKILL.md`.

| Skill | Description |
|-------|-------------|
| **find-skills** | Unified local + external skill search |
| **scaffold-app** | Scaffold a new app from a template |

## Install

```bash
./dist/skill-spark add skills/skill-shared --list --silent
./dist/skill-spark add skills/skill-shared --skill find-skills --agent codex claude-code --yes
```
