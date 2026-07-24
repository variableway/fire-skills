---
name: frontend-build
description: Build distinctive frontend UI from scratch — new pages, components, landing pages, dashboards, SaaS interfaces. Use when the user wants to create, design, or build web UI ("build me a landing page", "make a hero", "create a dashboard", "I need a page for..."), or redesign from a URL they want rebuilt from scratch. Pulls the shared reference layer on demand; never preloads everything. Pairs with frontend-redesign (existing-code cleanup) — if the code already exists and looks AI-generated, use that instead.
---

# Frontend Build — new UI from scratch

You are building frontend UI that hasn't been written yet. The knowledge base lives in `../frontend-shared/` — load only what each step needs (progressive disclosure).

## Route first

Confirm this is **build**, not a sibling:

- Existing code to fix / de-slop → use `../frontend-redesign/SKILL.md`
- Presentation / deck / PPT conversion → use `../frontend-slides/SKILL.md`
- Directory reorganization / splitting a big file → use `../frontend/fe-code-structure/SKILL.md`

## Step 0 — Stack detection

Read the project once and pick exactly one adapter (do **not** mix assumptions from two stacks):

| Signal | Load |
|--------|------|
| `next.config.*` / `app/` / `next` dep | `../frontend-shared/stacks/nextjs.md` |
| `@tanstack/react-router` + `routes/` + `vite.config.*`, no `next` | `../frontend-shared/stacks/tanstack.md` |
| `svelte.config.js` / `@sveltejs/kit` | `../frontend-shared/stacks/sveltekit.md` |
| Single self-contained HTML artifact | `../frontend-shared/stacks/single-html.md` |

Project specifics in `../frontend/fe-foundation/SKILL.md` outrank the adapter when they disagree.

## Step 1 — Discovery → brief

Read `../frontend-shared/references/discovery.md`. Gather the brief in one batch (purpose, audience, content, style direction, brand identity, images, locale, constraints). Detect new vs URL-redesign. Generate and confirm the brief before any code. In auto/goal mode, state the assumption and keep it overridable.

## Step 2 — Commit a visual direction

Read `../frontend-shared/references/aesthetic-directions.md`. Pick ONE direction from the curated shortlist (or invent a hybrid that serves the brief). Tune the three dials (VARIANCE / MOTION / DENSITY). Commit the signature detail. For non-trivial surfaces, produce an ASCII mockup then a standalone HTML preview and get sign-off before touching real files.

## Step 3 — Source components

Read `../frontend-shared/references/component-sourcing.md`. Walk the priority tree (project lib → innate-base reference → shadcn → community). Never invent a component that exists; never pull one that violates the direction. Flag any new dependency before installing.

## Step 4 — Implement

Write production code on the chosen stack. Default Server Components in Next.js; `"use client"` only when needed. Follow the stack adapter's component rules (forwardRef, `cn()`, CVA variants, import order, services layer).

## Step 5 — Motion & accessibility

Read `../frontend-shared/references/accessibility-motion.md`. Apply the motion token system (`--duration-*`, `--ease-*`, asymmetric timing). CSS keyframes preferred; framer-motion/GSAP only when CSS can't express the effect. Ship the global `prefers-reduced-motion` override. Hit every a11y non-negotiable.

## Step 6 — Pre-delivery gate

Read `../frontend-shared/references/quality-checklist.md`. Run the full checklist (visual / interaction / light-dark / layout / accessibility / motion / performance / code). Then run the three success tests in `../frontend-shared/references/design-language.md` §5 (justified / coherent / not-a-re-run). Verify in the browser — a screenshot, not a passing type-check, is the proof.

## Hard constraints

- Match the existing repo's code conventions; they outrank this skill.
- Don't introduce a library the project already has an equivalent for.
- Avoid premature abstraction — three lines of duplication beats the wrong abstraction.
- Minimal sufficient change; don't refactor unrelated code in passing.
- Prefer `@innate/ui` over re-inventing.
