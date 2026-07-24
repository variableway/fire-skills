# Component sourcing — where components come from

The unified priority tree for choosing components, with license notes and optional component-generation backends. Merges `frontend/fe-foundation` (`@innate/ui` priority + innate-base reference), `frontend-design-engineer` (shadcn→MagicUI→ReactBits→21st→Aceternity tree), `ui-pro-magic` (Magic MCP injection), and `deslopify` (21st replacement map).

**Core rule:** never invent a complex component from scratch if one already exists in an approved source. But also never pull a component that violates the design language (no glassmorphism/gradient components in a solid-surface direction — see `design-language.md`).

## 1 — Priority tree

Walk top-down. Stop at the first source that has a suitable component.

| # | Source | What it gives you | License / note |
|---|--------|-------------------|----------------|
| 1 | **Project library** — `@innate/ui` (this repo) + the active stack's local components | 60+ base shadcn/ui wrappers + admin components (data-table, charts, form-elements, auth, theme) | Repo-owned, always preferred |
| 2 | **innate-base reference implementation** — `innate-base/apps/admin-nextjs` (or `admin-tanstack`) | Real worked components to copy patterns from | Reference only — match the project's framework branch, never read the other framework's |
| 3 | **shadcn/ui** | Base structural components (MIT) | Copy-paste into `components/ui/*`; edit directly |
| 4 | **Magic UI** | Visual effects, landing animations (MIT) | Motion / decorative |
| 5 | **React Bits** | Text animations, micro-interactions | MIT + Commons Clause — check commercial use |
| 6 | **21st.dev** | Premium community components | Verify MIT per component; reject glassmorphism/gradient/reflexive-shader ones |
| 7 | **Aceternity UI** | Advanced animations | Free tier MIT; Pro = commercial license |

**Not allowed:** GPL libraries, abandoned libraries (>12 months no commits), webpack-only bundlers, invented URLs.

## 2 — Stack-matched sourcing

Only read the reference implementation matching the project's framework:

- Next.js project → `innate-base/apps/admin-nextjs/src/` only. Never read `admin-tanstack`.
- TanStack project → `innate-base/apps/admin-tanstack/src/` only. Never read `admin-nextjs`.

This is a hard rule in `fe-foundation`: Next.js projects don't look at the TanStack reference and vice versa.

## 3 — The 21st.dev replacement filter (redesign)

When replacing a slop element with a 21st.dev component, the registry is **curated, not automatic**. Reject any candidate with:

- glassmorphism (`backdrop-blur`, `bg-white/10`)
- decorative gradients / `bg-clip-text`
- purposeless shaders

Every suggested component passes the same `design-language.md` rules before being offered.

### Category → default replacement (deslopify map)

| Slop element | Replace with |
|--------------|--------------|
| Glassmorphism card | flat card + subtle border + generous spacing + structural shadow |
| Gradient hero | clean hero + bold typography + solid accent + real screenshot |
| Spinner | structural skeleton matching the real loading layout |
| Gradient text | solid hierarchized text, or shimmer in one specific context only |
| Fake testimonials | restructured section with real-data placeholders |
| Generic feature cards | bento grid / list with space for a demo |

## 4 — Optional component-generation backends

When a component doesn't exist in any source and must be generated, these backends can produce it — **constrained by the locked design system**. They are optional, never required.

| Backend | Provides | When usable |
|---------|----------|-------------|
| **21st.dev Magic MCP** (`@21st-dev/magic`) | `component_builder` / `component_refiner` / `component_inspiration` / `logo_search` | Configured with an API key from 21st.dev |
| **ui-ux-pro-max** (external Python skill) | Searchable design-system DB: 50+ styles, 97 palettes, 57 font pairings, 99 UX rules | Installed; resolve path from `UI_UX_PRO_MAX_PATH` |

**Critical rule:** never call a generator with a bare component description. Always inject the locked design system (style, palette, typography, effects, anti-patterns) so the output matches. If a backend is unavailable, fall back to hand-writing with the design system as a strict prompt constraint — never silently degrade to defaults.

## 5 — Escalation

- **Conflict between a component and an anti-pattern?** Surface it; propose two paths: respect the anti-pattern (pick a different component), or override with a documented justification.
- **A needed component exists only in a non-permissive source?** Build a clean-room equivalent; do not vendor the non-permissive one.
- **New dependency beyond framer-motion / the stack baseline?** Flag it and let the user approve before `install`. Never add silently.

## 6 — Customization (don't ship defaults)

Once component code is obtained, audit it against the direction:

1. **Colors** — remove ALL generic classes (`bg-blue-500`, `text-gray-700`); replace with the direction's tokens.
2. **Typography** — replace `font-sans`/`font-serif` with `--font-heading` / `--font-body`.
3. **Spacing** — verify margins/paddings follow the spacing unit (multiples of 8 or 12px per direction).
4. **Mobile-first** — every component has `sm:`/`md:`/`lg:` before desktop variants.
5. **Dark mode** — if the project uses `dark:`, tokens have dark counterparts.

shadcn/ui base components already in the project must **not** be re-implemented with raw HTML. Prefer `cn()` from `@innate/ui` (or local `lib/utils`) for class merging.
