# Reference projects index

Provenance of everything the `frontend-shared` / `frontend-build` / `frontend-redesign` / `frontend-studio` integration draws on. Each row says **what was referenced** (the specific idea, rule, or asset) and **where it now lives** in the integrated set. Use this to trace any rule back to its origin and to decide which upstream skill to keep as a deep-reference appendix vs. retire.

Paths are relative to `skills/sdlc/`.

## 1 — Source skills (in this repo's `skills/sdlc/`)

| Source skill (`name:`) | Location | Referenced for | Now lives in |
|---|---|---|---|
| `frontend-dev` | `frontend/fe-foundation/SKILL.md` | Engineering baseline: Next.js/TanStack detection, `@innate/ui` priority, innate-base reference paths, component rules, import order, RHF+Zod, tanstack-table, pnpm | `frontend-shared/stacks/nextjs.md`, `stacks/tanstack.md`, `component-sourcing.md`; kept as-is as the project engineering baseline |
| `frontend-code-organization` | `frontend/fe-code-structure/SKILL.md` | Directory reorg methodology, deletion test, page-shell splitting, shared-export convergence | Not folded in (different product: structure, not design). Referenced as a sibling in every mode's route table |
| `frontend-design-engineer` | `frontend-design-engineer-skill/frontend-design-engineer/SKILL.md` | 8 curated visual directions (+ token sets), Fase 0–5 intake/redesign flow, component source decision tree (shadcn→MagicUI→ReactBits→21st→Aceternity + license rules), GSAP mandatory rules, delivery checklist | `aesthetic-directions.md` (§2 directions), `discovery.md` (intake), `component-sourcing.md` (priority tree), `accessibility-motion.md` (GSAP canon), `quality-checklist.md` |
| `frontend-design-masterclass` | `frontend-design-masterclass/SKILL.md` | SvelteKit/Bun/Hono stack + shadcn-svelte/LayerChart/Svelte Motion; product-type→style compass; the anti-slop mandate (card sickness, pill clutter, composition rule); motion token system (`--duration-*`/`--ease-*`, asymmetric timing); the 8-section pre-delivery checklist; references/ library structure | `stacks/sveltekit.md`, `aesthetic-directions.md` (§1 compass, §8 signature detail), `design-language.md` (§1 card/clutter sickness), `accessibility-motion.md` (token system), `quality-checklist.md` (structure). Its `references/` kept as deep Svelte implementation detail |
| `21st-frontend-design` | `21st-frontend-design/SKILL.md` | 21st.dev pattern map (surface→pattern family), preview-first workflow (ASCII mockup → standalone HTML → sign-off), performance guardrails (refs on refs, `prefers-reduced-motion`), anti-patterns list | `aesthetic-directions.md` (§5 pattern map, §9 preview), `accessibility-motion.md` (§4 guardrails), `design-language.md` (anti-patterns) |
| `ui-pro-magic` | `ui-pro-magic/SKILL.md` | Two-layer orchestrator idea (strategy→implementation); Magic MCP component-builder/refiner/inspiration/logo tools; inject-design-system rule; ui-ux-pro-max as optional design-DB backend; escalation/fallback handling | `component-sourcing.md` (§4 optional backends, injection rule); the orchestrator *pattern* informed approach B (`frontend-studio`) |
| `design-taste-frontend` (+ 12 siblings) | `taste-skill/skills/*` | The three dials (VARIANCE / MOTION / DENSITY); anti-slop framing; GSAP code skeletons; redesign-audit protocol; pre-flight check; the variety test; imagegen skills (kept separate — images, not code) | `aesthetic-directions.md` (§3 dials), `design-language.md` (anti-slop), `accessibility-motion.md` (GSAP), `quality-checklist.md` (variety test). Imagegen sub-skills intentionally out of scope |
| `avoid-ai-design` | `avoid-ai-design/SKILL.md` | **Authoritative** AI-tell catalog (P0/P1/P2), context profiles, the three success tests (justified/coherent/not-a-re-run), the Space Grotesk trap, detect/rewrite modes, code-certain vs inferred tagging, self-reference escape hatch | `design-language.md` (§1 catalog, §4 profiles, §5 success tests, §6 guardrails, §7 escape hatch) — the backbone of that file |
| `deslopify` | `UI-Deslopify-Skill/SKILL.md` | The golden rule "never remove without replacing"; 15 design/typo/copy/UX/engineering rules; per-component 3-option questionnaire; 21st.dev replacement map; brand-identity/reference profiles; EN/PT bilingual copy rules | `design-language.md` (§2 rules, §3 replacement rule), `component-sourcing.md` (§3 replacement map), `discovery.md` (redesign intake one-at-a-time) |
| `frontend-slides` | `frontend-slides/SKILL.md` | Single-file HTML presentation: zero-dependency principle, fixed 1920×1080 stage, content density limits, show-don't-tell style discovery, PPT conversion pipeline, deploy/PDF export | `stacks/single-html.md`; the mood→preset table in `aesthetic-directions.md` §4 |
| `frontend-slides-editable` | `frontend-slides-editable/SKILL.md` | Editable-deck runtime (object editing, Pages sidebar, undo/redo, slot editing), viewport-fit stage model, PPT/PDF extraction parity | `stacks/single-html.md` (editable runtime section); declared a fork of `frontend-slides` — recommend merging with an edit-mode switch |

## 2 — Reference implementation (project-local)

| Project | Path | Referenced for |
|---|---|---|
| `innate-base` (Next.js branch) | `innate-base/apps/admin-nextjs/src/` | Worked component patterns: `ui/`, `layout/`, `data` (data-table, section-cards), `charts/`, `form-elements/`, `auth/`, `theme-*`. Read **only** for Next.js projects |
| `innate-base` (TanStack branch) | `innate-base/apps/admin-tanstack/src/` | Same groups, TanStack-flavored. Read **only** for TanStack projects. Hard rule: never cross-read the other framework's branch |

## 3 — External component libraries (sourced, not vendored)

| Library | License | Referenced for |
|---|---|---|
| shadcn/ui | MIT | Base structural components — copy-paste into `components/ui/*`, edit directly. Default primitives |
| Magic UI | MIT | Visual effects, landing animations, motion/decorative components |
| React Bits | MIT + Commons Clause | Text animations, micro-interactions (check commercial use) |
| 21st.dev | per-component (verify MIT) | Premium community components; also the Magic MCP registry. Curated, not automatic — reject glassmorphism/gradient/shader candidates |
| Aceternity UI | Free=MIT / Pro=commercial | Advanced animations (Pro needs commercial license) |

**Rejected on principle:** GPL libraries, abandoned (>12 months no commits), webpack-only bundlers, invented URLs.

## 4 — External tooling & backends (optional)

| Tool | Referenced for |
|---|---|
| 21st.dev Magic MCP (`@21st-dev/magic`) | `component_builder` / `component_refiner` / `component_inspiration` / `logo_search` — optional component generation, constrained by the locked design system |
| ui-ux-pro-max (Python skill) | Optional searchable design-DB (50+ styles, 97 palettes, 57 font pairings, 99 UX rules). Resolve path from `UI_UX_PRO_MAX_PATH` |
| Vercel CLI | Deploy single-file HTML presentations to a live URL (`scripts/deploy.sh`) |
| Playwright | Headless browser for PDF export and visual-regression screenshots |
| python-pptx / PyMuPDF | PPTX / PDF content extraction to `extracted-slides.json` |

## 5 — Repo infrastructure (the skill manager)

| Resource | Referenced for |
|---|---|
| `skills/skill-shared/_shared/` convention | The pattern this integration follows — shared fragments referenced by sibling skills (e.g. `find-skills`, `scaffold-app`) |
| `skill-spark` CLI (`package.json`) | The repo's skill manager; build/lint via bun + biome |
| `overall.md` (sdlc) | House rules applied to every workflow: think-before-code, minimal sufficient change, surgical edits, goal-driven execution, root-cause debugging, traceable records |
| skills.sh / flins.tech / SkillsLLM | External skill marketplaces (referenced by `find-skills`, not by this integration) |

## 6 — Fonts & icon sets referenced

| Resource | Referenced for |
|---|---|
| Lucide React / Heroicons | Icon systems (one set per project, matching `viewBox` 24×24). Emoji is never an icon |
| Simple Icons | Verified brand logos |
| Fontshare / Google Fonts | Distinctive typefaces for static HTML (never system fonts); `next/font` for Next.js |

## How to use this index

- **Tracing a rule:** find the rule in a `frontend-shared/references/*.md` file, then locate the source-skill row above to see where it came from and whether the upstream still has richer detail.
- **Deciding retire-vs-keep:** skills whose *only* contribution is now in `frontend-shared` (e.g. `avoid-ai-design`, `deslopify`) can be retired as triggers and kept as deep-reference appendices. Skills with a distinct product (`frontend-slides`, `fe-code-structure`, masterclass's Svelte `references/`) stay.
- **Attribution:** every external library above is *sourced at generation time*, not vendored into the repo. License obligations attach to the generated output, not to this skill set.
