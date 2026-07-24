# Discovery & brief

The intake phase. Before any code, turn a vague request into a verifiable brief and distinguish facts from assumptions. This collapses the intake flows of `frontend-design-engineer` (Fase 0), `deslopify` (Phase 0), `frontend-slides` (Phase 1), and `frontend-design-masterclass` (§5) into one protocol that adapts depth to mode.

> House rule (repo `overall.md`): think before coding. If uncertainty affects scope, interface, data, or delivery, confirm with the human partner. In goal/auto mode, decide by best practice + lowest risk and record to `tracing/autonomous_decisions`.

## 0 — Route first

Confirm you are in the right mode before intake:

| Signal | Mode |
|--------|------|
| "build / make / create / design a page", greenfield, or a URL to redesign from scratch | **build** |
| "this looks AI-generated / de-slop / refactor the UI", existing code to fix | **redesign** |
| "presentation / slides / deck / convert PPT" | **slides** (different product — use `frontend-slides`) |
| "reorganize this directory / split this big file" | **structure** (use `frontend/fe-code-structure`) |

If the request is ambiguous, ask one routing question. Do not start building the wrong artifact.

## 1 — Detect new vs redesign (build mode only)

- A URL in the prompt → redesign-from-existing path: scrape (curl → headless render → user-guided fallback), produce `.brief/analysis.md`, then ask only the redesign questions.
- No URL → new-project path: ask the full brief.

Keep the scraping cascade silent (try each level, escalate only on failure). Never block the user on a tool failure.

## 2 — Ask everything in one batch

Do **not** dribble questions across turns. Deliver the checklist in one grouped message (use a structured-question UI when available). If the first answer is incomplete, the next message asks **only** the missing items — never re-asks answered ones, never infers missing answers from topic alone.

### The brief (build / new project)

| # | Dimension | "done" means |
|---|-----------|--------------|
| 1 | **Purpose** | Landing page / app UI / dashboard / portfolio / marketing — concrete, not "a website" |
| 2 | **Audience** | Who uses it; enterprise tolerates density, consumer needs breathing room |
| 3 | **Content** | Pasted outline/bullets/copy **or** "topic only" (then you draft, they edit) |
| 4 | **Style direction** | A named direction, a reference URL/product, **or** explicit delegation ("you choose") — never inferred from topic alone |
| 5 | **Brand identity** | Logo / palette / typeface if any; "none" is a valid answer |
| 6 | **Images** | No / yes-will-provide / unsure; if yes, evaluate assets *when they exist*, not now |
| 7 | **Locale / language** | Monolingual / bilingual / per-locale files, when audience-facing prose is involved |
| 8 | **Constraints** | Stack locked? Existing design system? Hard don'ts? |

### The intake (redesign mode)

Lighter — you already have an artifact. Ask only what the audit cannot tell you:

1. Scope — which files/sections to touch (default: highest-impact surfaces first)
2. Brand identity / visual reference (if not already in the code)
3. Replacement posture — (a) you choose from options, (b) I recommend, you confirm, (c) manual refactor only
4. Hard constraints — must preserve routing, props, data flow, accessibility, copy meaning

> `deslopify` asks these one-at-a-time with a recommendation each. That is good for redesign; for build, batch them.

## 3 — Co-design outline ↔ images

Only when the user has real assets or links. Not "plan slides then add images" — design around both from the start (3 screenshots → 3 feature slides; 1 logo → title/closing). If images are pending, capture "yes, will provide" and proceed; evaluate later.

## 4 — Commit the brief

Generate `.brief/project-brief.md` (or an in-context brief for non-filesystem runs):

- Identity, page architecture, content status
- Suggested visual direction **with a one-line reason** (tie to purpose + audience)
- Required functionalities, restrictions, what **not** to include

Present the summary and **pause for confirmation** before any code. In auto/goal mode, skip the pause, state the assumption in one line, and keep it overridable.

## 5 — Pre-code design thinking

Before pixels, commit to a direction (loads `aesthetic-directions.md`):

1. **Purpose** — what this solves, for whom
2. **Product type** — initial compass from the type→style table
3. **Aesthetic tone** — pick ONE and commit fully
4. **Color direction** — primary hue + accent via color theory
5. **Typography** — display + body (+ mono) trio
6. **The memorable detail** — the one element the user remembers
7. **Complexity match** — maximalist = elaborate; minimalist = surgical

## What "done" looks like

- Every dimension answered by the user or explicitly delegated — none inferred from topic.
- A written brief the user confirmed (or, in auto mode, a stated assumption).
- A committed visual direction with a reason.
- Only then proceed to `aesthetic-directions.md` and `component-sourcing.md`.

## Anti-patterns

- Starting code before the brief is confirmed.
- Inferring slide count / length / preset / locale from the topic alone.
- Asking answered questions again, or batching unrelated follow-ups across many turns.
- Treating "you choose" as license to skip showing the user options — in build, still surface 2–4 grounded candidates; in redesign, still offer per-element options.
