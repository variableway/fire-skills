---
name: frontend-shared
description: Shared knowledge layer for frontend design skills. Holds the canonical, de-duplicated reference docs (discovery, design language, aesthetic directions, quality checklist, component sourcing, accessibility & motion) and stack adapters (Next.js / TanStack / SvelteKit / single-file HTML). Loaded on demand by frontend-build and frontend-redesign (approach A) or frontend-studio (approach B). Do NOT load every file at once — read only what the active mode tells you to.
---

# Frontend Shared — reference layer

This is the **single source of truth** for the knowledge that every frontend design skill used to duplicate. It is not a workflow itself — a mode skill (`frontend-build`, `frontend-redesign`, or the `frontend-studio` router) decides which files to load.

## Why this exists

Six upstream skills each carried their own copy of the anti-slop catalog, the delivery checklist, the intake questions, and the visual-direction library — six copies that drifted apart. This layer collapses them to one canonical copy. See `integration/index.md` for the provenance of every rule below.

## Progressive disclosure (do not preload)

Read a reference **only when the active workflow step needs it**. Loading all six at once defeats the purpose and wastes context.

| File | Read it when… |
|------|---------------|
| `references/discovery.md` | You are gathering requirements / building a brief (build) or scoping an audit (redesign) |
| `references/design-language.md` | You are auditing or choosing the anti-slop / design rules (the "what not to do" + "what to commit to") |
| `references/aesthetic-directions.md` | You are picking a visual direction, palette, type pairing, or tuning variance/motion/density |
| `references/component-sourcing.md` | You are choosing where a component comes from (project lib → shadcn → community) and its license |
| `references/accessibility-motion.md` | You are writing motion / a11y rules, GSAP, or motion tokens |
| `references/quality-checklist.md` | You are about to declare a surface done — the pre-delivery gate |

## Stack adapters

Pick the one matching the project. Do **not** mix assumptions from two stacks.

| File | Use when the project is… |
|------|--------------------------|
| `stacks/nextjs.md` | Next.js (App Router) + `@innate/ui` / shadcn + Tailwind (+ optional GSAP) |
| `stacks/tanstack.md` | TanStack Router + Vite + shadcn + Tailwind |
| `stacks/sveltekit.md` | SvelteKit 5 (Runes) + Bun + Hono + shadcn-svelte + Tailwind v4 |
| `stacks/single-html.md` | Zero-dependency single-file HTML (presentations, artifacts) |

## How to reference from a mode skill

Use relative paths from the mode skill's directory:

- From `../frontend-build/SKILL.md` → `../frontend-shared/references/discovery.md`
- From `../frontend-studio/modes/build.md` → `../frontend-shared/references/discovery.md`

## Relationship to `frontend/fe-foundation`

`frontend/fe-foundation` is the **project engineering baseline** (Next.js/TanStack + `@innate/ui` + innate-base + pnpm, strict TS, RHF+Zod). This shared layer is the **design** knowledge. They compose: fe-foundation says *how the project is built*; this layer says *how the UI should look and be audited*. When a stack adapter and fe-foundation disagree on project specifics, fe-foundation wins (it reflects the real repo).
