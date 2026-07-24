---
name: frontend-redesign
description: Audit and rewrite existing frontend UI to remove generic AI design patterns ("AI slop"). Use when the user says "de-slop this", "make it look less AI-generated", "audit/refactor the UI", or the code has glassmorphism, purple-blue gradients, decorative orbs, spinners, or empty corporate copy. Covers HTML/CSS and React/Tailwind/shadcn. Supports a detect-only mode that flags patterns without rewriting. Pairs with frontend-build (greenfield) — if the UI doesn't exist yet, use that instead. Pulls the shared reference layer on demand.
---

# Frontend Redesign — audit & rewrite existing UI

You are fixing frontend code that already exists. The point is not novelty — it is replacing defaults with decisions. The knowledge base lives in `../frontend-shared/`; load only what each step needs.

## Route first

Confirm this is **redesign**:

- Greenfield / new UI / rebuild-from-URL → `../frontend-build/SKILL.md`
- Presentation / deck → `../frontend-slides/SKILL.md`
- Directory reorganization → `../frontend/fe-code-structure/SKILL.md`

## Step 0 — Stack detection

Same table as build — read exactly one of `../frontend-shared/stacks/{nextjs,tanstack,sveltekit,single-html}.md`. The audit treats plain HTML/CSS and React+Tailwind+shadcn the same way; the catalog is framework-agnostic (untouched MUI/Chakra/Bootstrap defaults read as AI for the same reason — swap the class/token names).

## Step 1 — Scope & intake

Read `../frontend-shared/references/discovery.md` (redesign intake: scope, brand/reference, replacement posture, hard constraints). Identify what is under audit (component / page / whole app) and the mode.

## Step 2 — Modes

**`rewrite`** (default): audit → commit direction → rewrite.
**`detect`**: audit and score only, no edits. Trigger when the user says "just audit", "flag only", "scan", "don't change the code", or you're reviewing code you shouldn't change.

## Step 3 — Render if you can, then audit

Design is visual. If a screenshot/preview/dev-server tool is available, render the artifact and judge visual tells from pixels (palette dominance, spacing rhythm, hierarchy, motion). Read the source for code-level tells. If nothing can render, audit the source alone and mark visual tells as **inferred, lower-confidence**.

Read `../frontend-shared/references/design-language.md`. Walk every tell in the catalog (§1). For each: location, category, severity (P0/P1/P2), one line on *why it reads as AI*, and a **code-certain / inferred** tag. Note the context profile (`landing`/`app-component`/`inside-design-system`/`dashboard`) — it calibrates strictness.

## Step 4 — Commit one direction (rewrite mode)

Pick **one** aesthetic direction (from `../frontend-shared/references/aesthetic-directions.md`) and name it with 3–5 concrete moves: a type pairing, a palette stance, a layout stance, a motion idea, one signature detail. Show the direction + 1–2 alternatives in a sentence and pause before changing code. In non-interactive mode, choose the best fit, state the assumption, proceed.

## Step 5 — Calibrate depth

- Small component / inside a design system → **surgical** pass: swap tells, keep structure and tokens.
- Standalone page / artifact → **rebuild** around the direction.
- Full rebuild overlaps `frontend-build` — if ground-up, hand it the committed direction rather than duplicating.

## Step 6 — Rewrite (the replacement rule)

**Never remove without replacing.** Each removed element gets a substitute with *more* visual presence (see `../frontend-shared/references/design-language.md` §3 and `component-sourcing.md` §3). Edit the real files. Preserve functionality, props, state, routing, data flow, accessibility, and copy meaning. Name any dependency you introduce — never add silently.

When replacing with a 21st.dev component: reject glassmorphism/gradient/reflexive-shader candidates; every suggestion passes the design-language rules first.

## Step 7 — Re-audit & judge

Run the catalog over the result. No P0 surviving is **necessary but not sufficient** — then judge against the three success tests (`design-language.md` §5: justified / coherent / not-a-re-run). A token-swap (indigo→teal, Inter→Fraunces, drop emoji) clears every P0 and still leaves a forgettable template. Fix anything that fails.

## Step 8 — Pre-delivery gate

Read `../frontend-shared/references/quality-checklist.md`. Run the full checklist. Report: replaced, refactored, pending items.

## Output format

### rewrite mode
1. **Audit** — every tell grouped by severity, with location, one-line reason, code-certain/inferred tag.
2. **Direction** — the committed direction + defining moves + 1–2 alternatives. (Pause here if interactive.)
3. **Rewrite** — edited code at calibrated depth.
4. **What changed** — meaningful moves, not a line-by-line diff.
5. **Re-audit & judgment** — confirm no P0 survived; judge against the three tests.

### detect mode
1. **Audit** — every tell grouped by severity (P0/P1/P2), locations, code-certain/inferred tag.
2. **Assessment** — per flag: clear problem or judgment call. Say which to fix, which to leave.

## Guardrails

- Never break working code. Behavior is not yours to change.
- Don't trade one cliché for another (the Space Grotesk trap). Vary across runs.
- Respect hard constraints — an existing design system / brand guideline / named framework outranks your taste.
- Don't manufacture problems. If the UI is already distinctive, say so and stop. A clean audit is valid.
- Keep copy meaning; sharpen microcopy, never invent claims.
