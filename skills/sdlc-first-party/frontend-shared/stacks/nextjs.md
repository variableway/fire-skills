# Stack adapter — Next.js

Next.js (App Router) + `@innate/ui` + Tailwind + TypeScript strict. This is the **primary stack** for this repo's projects. Distilled from `frontend/fe-foundation` with the GSAP specifics from `frontend-design-engineer`.

> Project specifics in `frontend/fe-foundation` outrank this file when they disagree — fe-foundation reflects the real repo (`innate-base`).

## Detection

A project is Next.js if any of: `next.config.*`, `app/` directory, `next` dependency.

## Versions & layers

| Layer | Choice |
|-------|--------|
| Framework | Next.js 16 App Router (Server Components by default) |
| Language | TypeScript (strict mode) |
| Styling | Tailwind CSS 4.x, `darkMode: 'class'`, CSS vars in `globals.css` |
| UI components | `@innate/ui` (60+ base shadcn wrappers) + admin-local components |
| Class merge | `cn()` from `@innate/ui` or local `lib/utils` |
| Theme | next-themes |
| Forms | React Hook Form + Zod |
| Icons | Lucide React |
| Tables | `@tanstack/react-table` |
| Package mgr | pnpm workspaces |

## Reference implementation

`innate-base/apps/admin-nextjs/src/` — read **only** this branch for a Next.js project. Never read `admin-tanstack`. Component groups available there: `ui/` (22+ base), `layout/` (sidebar, header), `data` (data-table, section-cards), `charts/`, `form-elements/`, `auth/`, `theme-*`.

## Directory structure

```
src/
├── app/                    # App Router routes
│   ├── layout.tsx
│   ├── page.tsx
│   └── (routes)/
├── components/
│   ├── ui/                 # shadcn base
│   ├── blocks/             # page blocks
│   └── layout/             # sidebar, header
├── lib/                    # pure functions (no UI imports)
├── hooks/
├── services/              # API layer — pages never fetch directly
└── styles/
```

## Component rules

1. Full Props TypeScript types.
2. `React.forwardRef` to expose refs.
3. `cn()` for className; support variant/size via CVA.
4. `"use client"` only when hooks/browser APIs are needed.
5. shadcn base components already in the project must not be re-implemented with raw HTML.

## Import order

1. External libs
2. UI components (`@innate/ui`, `@/components/ui/...`)
3. Internal hooks/tools

## GSAP (optional, only when motion needs it)

`gsap >= 3.12` + `@gsap/react`. Always `useGSAP()` (never `useEffect`), `autoAlpha` (never opacity/visibility split), hardware aliases (`x`/`y`/`scale`), `scope: container`, register `ScrollTrigger` before the component, wrap in `prefers-reduced-motion`. Full canon in `../references/accessibility-motion.md`.

## Server / client boundary

Default Server Components. Add `'use client'` only for DOM refs, framer-motion, or interactive state. Fonts via `next/font`. Images via `<Image />`.
