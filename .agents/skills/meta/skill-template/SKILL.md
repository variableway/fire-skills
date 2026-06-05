---
name: skill-template
description: >
  Copy this template when creating a new skill. Use as a starting point
  for writing SKILL.md files that follow the skill-spark standard.
---

# /{{skill-name}} — {{Short Human-Readable Title}}

## Overview

{{One or two sentences explaining what this skill does and why it exists.}}

## When to Use

{{Describe the trigger conditions. Be specific so the agent knows when to activate this skill.}}

- When the user types `/{{trigger}}`
- When the user asks to {{action}}
- When {{specific situation}} occurs

## Workflow

{{Step-by-step instructions for the agent. Use numbered lists for sequential tasks.}}

1. **{{Step 1 name}}**: {{What to do}}
2. **{{Step 2 name}}**: {{What to do}}
3. **{{Step 3 name}}**: {{What to do}}

## Commands / API

```bash
# Example command pattern
{{command}} {{subcommand}} <arg>

# Another example with flags
{{command}} {{subcommand}} --flag value
```

## Common Patterns

### {{Pattern Name}}

```bash
# Step-by-step example
{{command}} step-one
{{command}} step-two --option
{{command}} step-three
```

### {{Another Pattern}}

```bash
{{command}} example --with-args
```

## Rules

- **Rule one**: {{Specific constraint or must-do}}
- **Rule two**: {{Specific constraint or must-do}}
- **Rule three**: {{Specific constraint or must-do}}

## Output Format

{{If the skill produces structured output, describe it here.}}

```{{language}}
{{example output}}
```

## Error Handling

{{What to do when things go wrong.}}

- {{Error situation}} → {{Recovery action}}
- {{Error situation}} → {{Recovery action}}

## Notes

- {{Implementation detail or caveat}}
- {{Implementation detail or caveat}}
