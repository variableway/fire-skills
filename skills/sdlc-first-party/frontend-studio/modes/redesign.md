# Mode: redesign — audit & rewrite existing UI

You are fixing frontend code that already exists. The point is not novelty — it is replacing defaults with decisions. The router (`../SKILL.md`) already chose stack + route. This file holds the redesign workflow; the shared reference docs live at `../../frontend-shared/references/*`.

## Step 1 — Scope & intake

Read `../../frontend-shared/references/discovery.md` (redesign intake: scope, brand/reference, replacement posture, hard constraints). Identify what is under audit (component / page / whole app) and the mode.

## Step 2 — Modes

**`rewrite`** (default): audit → commit direction → rewrite.
**`detect`**: audit and score only, no edits. Trigger on "just audit", "flag only", "scan", "don't change the code", or when reviewing code you shouldn't change.

## Step 3 — Render if you can, then audit

Design is visual. If a screenshot/preview/dev-server tool is available, render the artifact and judge visual tells from pixels (palette dominance, spacing rhythm, hierarchy, motion). Read the source for code-level tells. If nothing can render, audit the source alone and mark visual tells as **inferred, lower-confidence**.

Read `../../frontend-shared/references/design-language.md`. Walk every tell in the catalog (§1). For each: location, category, severity (P0/P1/P2), one line on *why it reads as AI*, and a **code-certain / inferred** tag. Note the context profile (`landing`/`app-component`/`inside-design-system`/`dashboard`) — it calibrates strictness.

## Step 4 — Commit one direction (rewrite mode)

Pick **one** direction (from `../../frontend-shared/references/aesthetic-directions.md`) and name it with 3–5 concrete moves: type pairing, palette stance, layout stance, motion idea, one signature detail. Show it + 1–2 alternatives in a sentence and pause before changing code. In non-interactive mode, choose the best fit, state the assumption, proceed.

## Step 5 — Calibrate depth

- Small component / inside a design system → **surgical** pass: swap tells, keep structure and tokens.
- Standalone page / artifact → **rebuild** around the direction.
- Full rebuild overlaps the build mode — if ground-up, hand it the committed direction rather than duplicating.

## Step 6 — Rewrite (the replacement rule)

**Never remove without replacing.** Each removed element gets a substitute with *more* visual presence (`design-language.md` §3, `component-sourcing.md` §3). Edit the real files. Preserve functionality, props, state, routing, data flow, accessibility, copy meaning. Name any dependency you introduce — never add silently.

When replacing with a 21st.dev component: reject glassmorphism/gradient/reflexive-shader candidates; every suggestion passes the design-language rules first.

## Step 7 — Re-audit & judge

Run the catalog over the result. No P0 surviving is **necessary but not sufficient** — then judge against the three success tests (`design-language.md` §5). A token-swap clears every P0 and still leaves a forgettable template. Fix anything that fails.

## Step 8 — Pre-delivery gate

Read `../../frontend-shared/references/quality-checklist.md`. Run the full checklist. Report: replaced, refactored, pending items.

## Output format

### rewrite mode
1. **Audit** — every tell grouped by severity, location, one-line reason, code-certain/inferred tag.
2. **Direction** — committed direction + defining moves + 1–2 alternatives. (Pause if interactive.)
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
- Don't manufacture problems. If the UI is already distinctive, say so and stop.
- Keep copy meaning; sharpen microcopy, never invent claims.
