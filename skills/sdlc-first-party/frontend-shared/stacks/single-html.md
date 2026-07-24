# Stack adapter — single-file HTML (zero dependencies)

Zero-dependency, animation-rich HTML that runs entirely in the browser. Used for presentations, artifacts, and standalone pages. Distilled from `frontend-slides` and `frontend-slides-editable`.

## Detection

Use when the deliverable is a single self-contained `.html` file: a presentation/deck, a PPT/PDF→web conversion, or a standalone artifact. **Different product** from a frontend app — for app UI use the framework adapters.

## Core principles

1. **Zero dependencies** — single HTML file, all CSS/JS inline. No npm, no build tools, no Motion library (CSS keyframes only).
2. **Show, don't tell** — generate visual previews, not abstract choices.
3. **Distinctive design** — no AI slop; every artifact feels custom-crafted.
4. **Stage fitting is non-negotiable** — content must fit the stage; overflow → split into more slides/pages, never scroll.

## Two stage models

| Model | Rule | When |
|-------|------|------|
| **Fixed 16:9 stage** (`frontend-slides`) | 1920×1080 canvas scaled as a whole to the viewport; letterbox/pillarbox allowed; never reflow content for phones | Presentations, decks |
| **Viewport-fit** (`frontend-slides-editable`) | `.slide { height: 100vh; overflow: hidden }`; all sizes via `clamp(min, pref, max)`; breakpoints at 700/600/500px | Editable decks, phone-adapted |

Pick one and commit. Read `viewport-base.css` and include its **full contents** in every file. Include `prefers-reduced-motion` support. Never negate CSS functions directly (`-clamp()` is silently ignored) — use `calc(-1 * clamp(...))`.

## Content density limits (per slide/page)

| Slide type | Max content |
|------------|-------------|
| Title | 1 heading + 1 subtitle + optional tagline |
| Content | 1 heading + 4–6 bullets OR 1 heading + 2 paragraphs |
| Feature grid | 1 heading + 6 cards max (2×3 / 3×2) |
| Code | 1 heading + 8–10 lines |
| Quote | 1 quote (≤3 lines) + attribution |
| Image | 1 heading + 1 image (≤60vh) |

Exceeds limits → split. Never cram, never scroll.

## Style discovery (show, don't tell)

Generate 3 single-slide HTML previews (1 safe preset + 1 bold template + 1 wildcard), open them, let the user pick visually. Mood→preset mapping in `../references/aesthetic-directions.md` §4. Never render internal workflow text, template names, or "Option A/B/C" on the slide itself — only real deck chrome (title, section, date, author, page number).

## PPT/PDF conversion

`python scripts/extract-pptx.py` / `extract-pdf.py` → `extracted-slides.json` + `assets/`. Both emit the same intermediate. PDF has no speaker notes (`notes: ""`). After extraction, still run discovery for style/length/locale/image handling — extraction decides content, not design.

## Editable runtime (optional)

If the artifact must stay editable in-browser: object-level layout editing, multi-select (Ctrl+click), alignment snapping, font/size controls, undo/redo, a Pages sidebar (thumbnails, reorder, delete), Ctrl+S persistence, export HTML. Treat `data-edit-slot` as editable content (not draggable); user-added `[data-slide-object]` are the draggable components. Native template layout stays locked unless an explicit "unlock layout" action runs.

## Delivery

Open in default browser (`open file.html`). Verify no in-slide scrolling at ~1280×720 (and phone viewports if mobile was selected). Tell the user: file location, style name, slide count, navigation keys, edit-mode entry, and how to customize (`:root` variables, font link, `.reveal` animations).
