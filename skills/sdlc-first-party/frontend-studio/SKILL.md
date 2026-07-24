---
name: frontend-studio
description: Single entry point for frontend UI work — builds new UI from scratch and audits/rewrites existing UI to remove AI slop, in one skill. Use for "build me a landing page", "make a hero", "create a dashboard", "de-slop this UI", "make it look less AI-generated", "audit/refactor the UI". Dispatches to a build or redesign workflow based on whether the code already exists. Pulls the shared reference layer (../frontend-shared/) on demand; never preloads everything.
---

# Frontend Studio — one skill, two modes

One entry point that routes to a **build** or **redesign** workflow depending on whether the UI already exists. The shared knowledge base lives in `../frontend-shared/`; each mode's steps live in `modes/<mode>.md`.

## Step 0 — Route (the only decision that matters here)

| Signal | Mode | Load workflow |
|--------|------|---------------|
| Greenfield, "build / make / create / design a page", or a URL to rebuild from scratch | **build** | `modes/build.md` |
| Existing code, "de-slop / looks AI-generated / refactor the UI / audit" | **redesign** | `modes/redesign.md` |
| Presentation / deck / PPT conversion | (out of scope) | use `../frontend-slides/SKILL.md` |
| Directory reorganization / splitting a big file | (out of scope) | use `../frontend/fe-code-structure/SKILL.md` |

If ambiguous, ask one routing question. Do not start the wrong artifact.

## Step 1 — Stack detection (shared across modes)

Read the project once; pick exactly one adapter (do not mix two stacks' assumptions):

| Signal | Adapter |
|--------|---------|
| `next.config.*` / `app/` / `next` dep | `../frontend-shared/stacks/nextjs.md` |
| `@tanstack/react-router` + `routes/` + `vite.config.*`, no `next` | `../frontend-shared/stacks/tanstack.md` |
| `svelte.config.js` / `@sveltejs/kit` | `../frontend-shared/stacks/sveltekit.md` |
| Single self-contained HTML artifact | `../frontend-shared/stacks/single-html.md` |

Project specifics in `../frontend/fe-foundation/SKILL.md` outrank the adapter when they disagree.

## Step 2 — Load the mode workflow

Open the mode file for the route above. It references the shared reference docs (`../frontend-shared/references/*`) at the points they're needed:

| Reference | Loaded when… |
|-----------|--------------|
| `../frontend-shared/references/discovery.md` | Gathering the brief / scoping the audit |
| `../frontend-shared/references/design-language.md` | Auditing or committing the anti-slop rules |
| `../frontend-shared/references/aesthetic-directions.md` | Picking a direction / palette / type |
| `../frontend-shared/references/component-sourcing.md` | Choosing where a component comes from |
| `../frontend-shared/references/accessibility-motion.md` | Writing motion / a11y |
| `../frontend-shared/references/quality-checklist.md` | The pre-delivery gate |

Load a reference **only when the active step needs it** — never all at once.

## Why one skill instead of two

The router pays a fixed dispatch cost (this file + the one `modes/*.md` it selects) so a single skill can serve both greenfield and remediation. The trade-off versus approach A (two separate mode skills) is measurable: see `../integration/eval-methodology.md` and `../integration/results.md`.

## Hard constraints (both modes)

- Match the existing repo's code conventions; they outrank this skill.
- Don't introduce a library the project already has an equivalent for.
- Avoid premature abstraction — three lines of duplication beats the wrong abstraction.
- Minimal sufficient change; don't refactor unrelated code in passing.
- Prefer `@innate/ui` over re-inventing.
