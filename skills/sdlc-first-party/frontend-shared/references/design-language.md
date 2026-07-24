# Design language — anti-slop & the rules

The canonical catalog of what makes UI read as AI-generated, the rules that replace defaults with decisions, and the tests that judge whether the result is actually good (not just slop-free). This is the authoritative merge of `avoid-ai-design` (catalog + success tests), `deslopify` (rules 1–15), `frontend-design-masterclass` (§4 anti-slop mandate), `taste-skill` (anti-slop), and `21st-frontend-design` (anti-patterns).

**The point is not novelty.** A purple gradient is not bad because purple is bad; it is bad because no one chose it. Every fix below trades a reflex for an intention.

## 1 — The tell catalog (audit with this)

Grouped by severity. Tiers triage by **who notices**, not how much it annoys you. Context can move a tell up or down (a centered hero is P0 on a generic SaaS page, fine in a luxury layout).

### P0 — a layperson recognizes it as AI-made

| Category | Tell | Why it reads AI |
|----------|------|-----------------|
| Color | purple→blue (`#6366f1→#8b5cf6`) gradient on white | The single most common LLM default |
| Color | gradient `bg-clip-text` headline text | Reflexive, never chosen |
| Color | pure purple (H 270–280) as primary | Distributional safe-pick |
| Type | Inter / Roboto / Open Sans / system fonts for everything | The worn "safe" stack, no pairing |
| Layout | centered hero + 2 buttons + 3-card feature grid template | The default page shell |
| Components | untouched shadcn `zinc`/`slate` base, default blue buttons | Shipped as-is |
| Components | reflexive glassmorphism (`backdrop-blur`, `bg-white/10`) | "premium" reflex with no reason |
| Motion | none at all, OR the same `fade-in-up` on every element | Averaged-out |
| Icons | emoji as feature bullets / UI icons | The giveaway |

### P1 — a designer or developer recognizes it

- `rounded-2xl shadow-lg` on every surface
- the default page shell (`container mx-auto px-4`, `max-w-7xl`)
- icon-in-a-rounded-square
- default four-column footer
- dead hover/focus states; arrow glyphs stapled to CTAs (`→`)
- "Elevate your workflow" / "Seamless" / "Powerful" copy
- `text-gray-*` over dark (use `text-zinc-400`)

### P2 — craft and polish gaps

- flat uniform spacing (`gap-4`/`p-6`) with no rhythm
- no motion, or copy-paste motion
- card-within-card nesting; decorative status bars; floating card clusters in hero

### Card sickness (the #1 failure)

Wrapping everything in rounded cards/boxes regardless of need. **Homepages are not dashboards.**

- Default to **cardless** layouts — full-bleed backgrounds, typographic hierarchy, whitespace create separation.
- Cards are acceptable ONLY for: repeated data items (product grids, team), interactive elements needing affordance, or real dashboard widgets.
- Catch yourself generating a hero card? STOP → restructure to full-bleed editorial.

### Clutter sickness

- **No decorative pill clusters** — "AI Powered" / "New" pills that do nothing are clutter.
- **No stat strips** — `10K+ users | 99.9% uptime | 50+ integrations` below the hero.
- **No eyebrow titles** — small labels ("Our Approach") above a headline that needs no preface.
- **No icon rows** restating what the heading said.

### The Space Grotesk trap (second-order default)

Models reach for the same "tasteful" non-default every time (Space Grotesk, a slate palette, one stock gradient). A second-order default is **still a default**. Vary deliberately across runs and justify by context.

## 2 — The design rules (replace with these)

| # | Rule |
|---|------|
| 1 | **Zero AI purple/blue combos.** Replace with the chosen accent, applied solidly. |
| 2 | **Gradients used with intent, not reflex.** A gradient on text = 1–2 words max, one color family. One gradient per viewport. |
| 3 | **Glassmorphism only with reason.** Solid surfaces (`bg-card border-border shadow-sm`) by default. Structural shadows, not chromatic. |
| 4 | **Visual noise → real content.** Decorative orbs, stock avatars, unsourced "trusted by" → replaced with negative space, typographic emphasis, or structured placeholders. |
| 5 | **One accent, used everywhere.** Primary CTAs, active links, state indicators. Everything else neutral. Hierarchy from weight + spacing, not color overload. |
| 6 | **One typeface, used well.** Size, weight, tracking, spacing create hierarchy. Body `leading-relaxed`, headings `leading-tight`, never `leading-none` on running text. |
| 7 | **Depth via light, not borders.** Lift with radial glows, soft shadows, inner highlights. Borders only subtle (`border-white/10`) or when a glowing border IS the effect. |
| 8 | **Motion is quiet but constant.** Something always breathing — a shimmer, a slow marquee, a drifting gradient. Pick ONE ambient motion + ONE triggered motion per fold; three moving things reads as a screensaver. |
| 9 | **Banned copy words → direct description.** revolutionize / empower / seamless / powerful / next-gen / cutting-edge / game-changer / disruptive. Replace with what the product does, or mark `{/* TODO: real copy */}`. |
| 10 | **Feature cards → real evidence.** Icon + vague title → restructure for screenshot, real metric, or demo. |

### Em-dash ban

No em dashes in shipped copy (headlines, subheads, buttons, descriptions). Use commas, semicolons, periods, or parentheses. Em dashes are fine inside code comments.

## 3 — The replacement rule (redesign only)

**Never remove without replacing.** Stripping style without substitution produces dry, lifeless UI — as bad as slop. Each removed element gets a substitute with *more* visual presence, not less:

- Glassmorphism card → flat card + subtle border + generous spacing + optional structural shadow
- Gradient hero → clean hero + bold typography + solid accent + real product screenshot
- Spinner → structural skeleton matching the real loading layout
- Gradient text → solid hierarchized text (or shimmer in one specific context only)
- Fake testimonials → restructured section with real-data placeholders (not a stray TODO comment)
- Generic feature cards → bento grid / list with space for a screenshot or demo

## 4 — Context profiles (calibrate strictness)

Auto-detect from stack/structure; state which you use.

| Profile | Treatment |
|---------|-----------|
| `landing` / `artifact` | Full strength. Reward boldness — direction matters most here. |
| `marketing-page` | Full strength on type, color, layout, copy. |
| `app-component` | Surgical — fix tells, keep the component's contract and structure. |
| `inside-design-system` | Surgical only. Respect existing tokens/primitives. Flag system-level tells as advice, don't fight the system. |
| `dashboard` | Favor density, legibility, hierarchy over decoration. |

## 5 — The three success tests

A clean catalog pass (no P0) is **necessary but not sufficient**. A token-swap (indigo→teal, Inter→Fraunces, drop the emoji) clears every P0 and still leaves a forgettable template. Judge the result against:

1. **Justified** — every change serves the committed direction, not a different reflex.
2. **Coherent** — type pairing, palette stance, layout, signature detail reinforce one another. One committed idea, executed.
3. **Not a re-run** — you did not reach for the same safe default as recent passes. If it looks like the last de-slop (warm-paper-serif, one stock accent), it failed the second-order-default check.

A page can pass the catalog and fail all three. The catalog catches clichés; these tests catch mediocrity.

## 6 — Guardrails

- **Never break working code.** Props, state, routing, data flow, accessibility survive intact. Behavior is not yours to change.
- **Don't trade one cliché for another** (the Space Grotesk trap).
- **Respect hard constraints** — an existing design system, brand guidelines, or named framework outranks your taste. Work within them.
- **Don't manufacture problems.** If the UI is already distinctive and intentional, say so and stop. A clean audit is a valid result.
- **Keep copy meaning.** Sharpen generic microcopy; never invent claims or change what the product says about itself.

## 7 — Self-reference escape hatch

When the code is *about* AI design patterns (a demo, a teaching example, a "what not to do" gallery), illustrative slop is intentional. Exempt it only with a concrete signal: a sibling `slop-example` comment, a path under `examples/`/`fixtures/`/`__mocks__/`/`stories/`, or text labeled illustrative. Flag patterns in the real interface only.
