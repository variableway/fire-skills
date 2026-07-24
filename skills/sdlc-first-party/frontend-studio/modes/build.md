# Mode: build — new UI from scratch

You are building frontend UI that hasn't been written yet. The router (`../SKILL.md`) already chose stack + route. This file holds the build workflow; the shared reference docs live at `../../frontend-shared/references/*`.

## Step 1 — Discovery → brief

Read `../../frontend-shared/references/discovery.md`. Gather the brief in one batch (purpose, audience, content, style direction, brand identity, images, locale, constraints). Detect new vs URL-redesign. Generate and confirm the brief before any code. In auto/goal mode, state the assumption and keep it overridable.

## Step 2 — Commit a visual direction

Read `../../frontend-shared/references/aesthetic-directions.md`. Pick ONE direction from the curated shortlist (or a hybrid that serves the brief). Tune the three dials (VARIANCE / MOTION / DENSITY). Commit the signature detail. For non-trivial surfaces, produce an ASCII mockup then a standalone HTML preview and get sign-off before touching real files.

## Step 3 — Source components

Read `../../frontend-shared/references/component-sourcing.md`. Walk the priority tree (project lib → innate-base reference → shadcn → community). Never invent a component that exists; never pull one that violates the direction. Flag any new dependency before installing.

## Step 4 — Implement

Write production code on the chosen stack. Default Server Components in Next.js; `"use client"` only when needed. Follow the stack adapter's component rules (forwardRef, `cn()`, CVA variants, import order, services layer).

## Step 5 — Motion & accessibility

Read `../../frontend-shared/references/accessibility-motion.md`. Apply the motion token system (`--duration-*`, `--ease-*`, asymmetric timing). CSS keyframes preferred; framer-motion/GSAP only when CSS can't express the effect. Ship the global `prefers-reduced-motion` override. Hit every a11y non-negotiable.

## Step 6 — Pre-delivery gate

Read `../../frontend-shared/references/quality-checklist.md`. Run the full checklist, then the three success tests in `../../frontend-shared/references/design-language.md` §5 (justified / coherent / not-a-re-run). Verify in the browser — a screenshot, not a passing type-check, is the proof.
