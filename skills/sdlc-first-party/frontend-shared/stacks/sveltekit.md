# Stack adapter — SvelteKit

SvelteKit 5 (Runes) + Bun + Hono + shadcn-svelte + Tailwind v4. Distilled from `frontend-design-masterclass`. Use only when the project is genuinely SvelteKit — the repo's primary stacks are Next.js and TanStack.

## Detection

A project is SvelteKit if `svelte.config.js`, `.svelte-kit/`, `@sveltejs/kit` dependency, or `$state`/`$derived` Runes in `.svelte` files.

## Versions & layers

| Layer | Choice |
|-------|--------|
| Framework | SvelteKit 5 with Runes (`$state`, `$derived`, `$effect`) |
| Runtime | Bun (server, packages) |
| Backend/API | Hono (edge-first routes, middleware) |
| UI primitives | shadcn-svelte (headless, fully customizable — override ALL defaults) |
| Charts | LayerChart (on Layer Cake; powers shadcn-svelte charts) |
| Animation | Svelte Motion (`@humanspeak/svelte-motion`) for orchestration; `svelte/transition` + `svelte/animate` for standard; CSS keyframes for loops |
| Mermaid | `beautiful-mermaid` (themed SVG + Shiki) |
| Styling | Tailwind CSS v4 extended with CSS custom properties |
| Testing | Playwright (visual regression) |
| Deployment | `@sveltejs/adapter-static` (static) or `adapter-vercel` (SSR) |

## Motion tier (Svelte-specific)

1. CSS keyframes (preferred — no client cost)
2. `svelte/transition` + `svelte/animate` (standard)
3. Svelte Motion (complex orchestration only)
4. (GSAP not native to this stack — only if explicitly added)

Motion tokens (`--duration-*`, `--ease-*`), asymmetric timing, `prefers-reduced-motion` — all apply unchanged from `../references/accessibility-motion.md`.

## Resource-loading protocol

SvelteKit has its own reference-file library (`references/landing-pages.md`, `typography.md`, `color-system.md`, `imagery.md`, `data-graphics.md`, `microanimations.md`, `visual-kinetics.md`, `data-visualization.md`, `mermaid-theming.md`, `web-design-themes.md`). When this adapter is active, those masterclass references are the deep implementation detail; this shared layer is the design *direction*. The two compose: pick direction here, load the Svelte-specific implementation from masterclass `references/` when needed.

## Hard rules (masterclass)

- **Card sickness** is the #1 failure here too — homepages are not dashboards.
- NEVER Inter/Roboto/system fonts; NEVER converge on Space Grotesk; NEVER pure purple primary.
- Every interactive element provides motion feedback; all durations use tokens.
- Production-ready code, no placeholders; vary themes/fonts/layouts/animation across generations.
