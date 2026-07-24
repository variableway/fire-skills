# Aesthetic directions — choosing the look

How to pick a visual direction and commit to it. Merges `frontend-design-engineer` (8 curated directions), `frontend-design-masterclass` (product-type compass + 8 timeless styles + 20 themes), `21st-frontend-design` (pattern map), `frontend-slides` (mood→preset), and `taste-skill` (the three dials). Pick ONE and commit fully.

## 1 — Product-type compass (starting point, not a constraint)

Identify what is being built. Each type implies style/color/layout norms — use as a compass, then customize.

| Product category | Recommended styles | Color direction |
|------------------|---------------------|------------------|
| SaaS / B2B / productivity | Swiss Grid, Flat | Trust blue + accent contrast |
| E-commerce / retail | Vibrant block, feature showcase | Brand primary + success green |
| E-commerce luxury | Liquid glass, cinematic | Dark neutrals + gold/champagne |
| Fintech / crypto | Data-dense, dark OLED | Deep navy/charcoal + neon accent |
| Healthcare / wellness | Organic flow, soft UI | Soft teal/sage + warm neutral |
| Creative / portfolio | Neo-brutalist, kinetic type | High-contrast + one bold accent |
| Gaming / entertainment | Cyberpunk, HUD/sci-fi | Deep dark + neon multi-accent |
| Education / docs | Editorial broadsheet, minimal | Warm paper + ink hierarchy |
| AI / ML platform | Aurora UI, motion-driven | Gradient primary + dark surface |
| Dashboard / analytics | Bento grid, data-dense | Neutral surface + semantic data colors |

## 2 — The curated directions (commit to one)

Each direction implies a full token set (color, type, spacing, radius, shadow). The names below are the canonical shortlist; invent a hybrid only if it serves the brief better.

| Direction | Best for | Defining moves |
|-----------|----------|----------------|
| **Editorial Serif** | Consultancies, media, publications | Serif display, ink + one vermilion accent, strict grid, real dashboard views |
| **Swiss Minimal** | SaaS, DevTools, dashboards | Tight confident sans, grid-breaking, 1 accent, generous whitespace |
| **Luxury Dark Warm** | Premium brands, jewelry, fashion, hospitality | Near-black with warm tint, gold/champagne accent, off-white text |
| **Corporate Bold** | Enterprise, B2B, fintech | Heavy typography, thin lines, hard shadows, trust color + sharp accent |
| **Understated Elegance** | Creative agencies, wellness, portfolios | Soft contrast, restrained palette, spring motion |
| **Neo-Brutalist** | Disruptive startups, art, communities | Swiss type, sharp contrast, experimental layout, mechanical language |
| **Playful Gradient** | Modern consumer apps | One committed gradient (not rainbow), rounded geometry, motion |
| **Retro Terminal** | DevTools, CLIs, developer docs | Monospace, scanlines, CRT — **avoid unless explicitly requested** (cringe risk across models) |

**Fallback when ambiguous:** Swiss Minimal.

## 3 — The three dials (taste-skill)

Once a direction is chosen, tune three dials. State the values up front so the whole surface stays coherent.

- **VARIANCE** — how far from "on-distribution" defaults (low = safe/restrained, high = experimental)
- **MOTION** — how much and what kind (none → quiet-ambient → kinetic)
- **DENSITY** — breathing room vs information-rich (consumer → enterprise)

Two surfaces in the same session should differ on layout structure, font pairing, animation approach, and section flow — not just a color swap. Identical structure + different colors = the hallmark of too few internal templates.

## 4 — Mood → preset (for presentations / quick starts)

When the user can't articulate taste, anchor on feeling. Generate visual previews, not abstract choices ("show, don't tell").

| Mood | Suggested presets |
|------|-------------------|
| Impressed / confident | Bold Signal, Electric Studio, Dark Botanical |
| Excited / energized | Creative Voltage, Neon Cyber, Split Pastel |
| Calm / focused | Notebook Tabs, Paper & Ink, Swiss Modern |
| Inspired / moved | Dark Botanical, Vintage Editorial, Pastel Geometry |

## 5 — The 21st.dev pattern map (component-level)

When the direction is set and you need a specific surface, follow the map to the right pattern family. Read the deeper reference only when that surface is in play.

| User wants… | Reach for |
|-------------|-----------|
| Hero / above-the-fold | grid-beams, aurora, spotlight |
| Primary CTA | shimmer, glow-border, magnetic |
| Social proof | marquee, avatar stack, logo row |
| Pricing | highlighted tier, gradient border |
| Features grid | bento, hover-lift, icon cards |
| Section divider / ambient bg | noise, radial glow, grid fade |
| Animated entrance | framer-motion or CSS keyframes |
| Tokens / type scale / spacing | base tokens |

## 6 — Color (the structured palette)

Build a 3-group palette: **Base Tones** (neutrals/surfaces), **Primary Tones** (brand), **Accent Tones** (one sharp highlight).

- Light themes: hard shadows, heavy typography, thin lines.
- Dark themes: colored glows, off-white text (`#E8E8E8`), subtle surface gradients — never flat solid black; near-black with a tint reads produced.
- NEVER pure purple (H 270–280) as primary → shift to indigo, teal, coral, or emerald.
- Derive the accent via color-theory harmony (complement / analogous / triad), not a guess.

## 7 — Typography

Choose a display + body (+ mono) trio. Distinctive, characterful — never the worn stack.

- NEVER Inter / Roboto / Open Sans / Lato / system fonts unless heavily modified.
- NEVER converge on Space Grotesk across generations.
- Build a mathematical type scale (ratio), use `clamp()` for responsive, load via `next/font` (or Fontshare/Google Fonts for static HTML), `display: swap`.
- Reserve text gradients for 1–2 words max, one color family.

## 8 — The signature detail

Commit to ONE element the user will remember (the grid-beam hero, the aurora glow, the Swiss red bar, the dithered texture). Everything else supports it. Maximalist direction = elaborate detail; minimalist = surgical precision.

## 9 — Preview before you code (show, don't tell)

For anything non-trivial, produce a preview the user approves before touching real files:

1. ASCII mockup of the layout (cheap, catches bad structure in 30s)
2. Standalone single-file HTML preview (real fonts/colors/motion, no build step) — Tailwind via Play CDN for static; or a route in the dev project
3. Get sign-off, then implement and verify in the browser

Tiny tweaks (a color swap, copy-only, second iteration of an approved surface) → go straight to code. Everything else → preview first.
