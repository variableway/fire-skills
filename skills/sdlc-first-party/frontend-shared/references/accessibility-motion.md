# Accessibility & motion

Non-negotiable a11y rules + the motion token system + the GSAP canon. Merges `frontend-design-masterclass` (motion tokens, a11y mandates), `taste-skill` (GSAP skeletons, pre-flight), `frontend-design-engineer` (Fase 4 GSAP mandatory rules), and `21st-frontend-design` (performance guardrails).

## 1 — Accessibility (non-negotiable)

- **Semantic HTML:** `<article>`, `<section>`, `<nav>`, `<aside>`, `<main>`.
- **Focus states:** NEVER `outline: none`. Style as `outline: 2px solid var(--accent); outline-offset: 4px`. `:focus-visible` on every interactive element.
- **Contrast:** WCAG AA minimum (4.5:1 body). Color is never the sole state indicator.
- **ARIA:** labels on all custom interactive components; `role="img"` + `aria-label` on canvas/Spline.
- **Images:** `alt` text on all; `<Image />` from Next.js (never raw `<img>` in Next), `width`/`height` set.
- **Forms:** every input has an associated `<label>` or `aria-label`.
- **Touch targets:** ≥ 44×44px on mobile.
- **`prefers-reduced-motion`:** disable parallax, tilt, complex animations. Ship the override once globally; do not re-implement per component.

## 2 — The motion token system

All durations and easing curves **must** use CSS custom property tokens. NEVER hardcode `transition: 0.3s ease`.

```css
:root {
  --duration-fast: 150ms;
  --duration-base: 200ms;
  --duration-slow: 300ms;
  --ease-enter: cubic-bezier(0.22, 1, 0.36, 1);   /* decelerate — entrances */
  --ease-exit: cubic-bezier(0.4, 0, 1, 1);         /* accelerate — exits */
  --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1); /* modals/dialogs */
}
```

Rules:
- **Asymmetric timing:** enters use `--ease-enter` (decelerate), exits use `--ease-exit` (accelerate). Enters are always ~1.25–1.5× longer than exits.
- **Durations:** 150–300ms for UI. Never >500ms for UI, never 0ms.
- **GPU only:** animate `transform` and `opacity` only. Never animate `top/left/width/height` in hot paths.
- Hover feedback via **color/opacity**, never layout-shifting `scale` transforms (a hover that moves content reads as AI slop and causes thrash).

## 3 — GSAP canon (React/Next.js)

When the stack uses GSAP (`gsap >= 3.12`, `@gsap/react`):

```tsx
"use client";
import { useGSAP } from "@gsap/react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
gsap.registerPlugin(ScrollTrigger);
```

Mandatory:
- `useGSAP()` **always** — never `useEffect` for GSAP in React/Next.
- `autoAlpha` **always** — never manipulate `opacity` and `visibility` separately.
- Hardware aliases (`x`, `y`, `scale`, `rotation`) — never `transform: translateX(...)` directly.
- `scope: container` when there's a parent ref.
- Register `ScrollTrigger` before the component.
- Wrap animations in `prefers-reduced-motion`:

```tsx
useGSAP(() => {
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (!reduced) gsap.from(".animated-el", { autoAlpha: 0, y: 20, duration: 0.6 });
}, { scope: container });
```

## 4 — Performance guardrails (pointer/scroll effects)

The visual patterns here lean on `pointermove` listeners, CSS animations, and motion libs. Three rules keep them cheap:

- **Transient values on refs, not state.** Spotlight mouse position, magnetic-button offsets, marquee progress update the DOM directly (CSS vars or `el.style.transform`). State updates at 60fps pointer input stutter on mid-tier laptops.
- **Defer heavy effects off the critical path.** WebGL shaders / large SVGs → `next/dynamic` with `ssr: false`. Max 3 WebGL canvases per page; <20k polygons, blur placeholder while loading.
- **`prefers-reduced-motion` once, globally.** Don't re-implement per component.

## 5 — Reduced motion (the global override)

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

Ship this on every project. It covers every animation the skill produces in one pass.

## 6 — Server / client boundary (Next.js)

- Default to Server Components. Add `'use client'` only when a pattern needs DOM refs, framer-motion, or interactive state.
- Interactive components marked `"use client"`; non-interactive stay Server Components.
- Fonts via `next/font` (Google Fonts) — never a direct `<link>` in `<head>`.

## 7 — Print / PDF

Sites should double as printable reports under `@media print`:
- Hide nav/footer/buttons, force white background, preserve SVG charts.
- `break-inside: avoid` on cards/charts/tables.

## 8 — Motion tier system

Prefer the cheapest tier that expresses the effect:

1. **CSS keyframes** (preferred — no client boundary, lighter bundle)
2. **`svelte/transition` + `svelte/animate`** (Svelte stack — standard motion)
3. **Svelte Motion / framer-motion** (complex orchestration only)
4. **GSAP** (scroll-triggered, timelines — heaviest)

If a fade can be a CSS keyframe, do not reach for framer-motion.
