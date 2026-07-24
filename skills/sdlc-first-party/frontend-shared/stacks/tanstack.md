# Stack adapter — TanStack Router

TanStack Router + Vite + shadcn + Tailwind + TypeScript strict. The alternative branch for this repo's projects. Distilled from `frontend/fe-foundation`.

> Project specifics in `frontend/fe-foundation` outrank this file when they disagree.

## Detection

A project is TanStack Router if `@tanstack/react-router` dependency, `routes/` directory, `vite.config.*`, **and** no `next` dependency.

## Versions & layers

| Layer | Choice |
|-------|--------|
| Framework | TanStack Router + Vite |
| Language | TypeScript (strict mode) |
| Styling | Tailwind CSS 4.x, `darkMode: 'class'` |
| UI components | `@innate/ui` + admin-tanstack local components |
| Class merge | `cn()` from `@innate/ui` or local `lib/utils` |
| Theme | next-themes |
| Forms | React Hook Form + Zod |
| Icons | Lucide React |
| Tables | `@tanstack/react-table` |
| Package mgr | pnpm workspaces |

## Reference implementation

`innate-base/apps/admin-tanstack/src/` — read **only** this branch for a TanStack project. Never read `admin-nextjs`. The same component groups apply; component code differs from the Next.js branch where routing/lifecycle differs.

## Hard rule

TanStack projects don't read the Next.js reference; Next.js projects don't read the TanStack reference. Judge the framework once, then read only the matching `apps/` subtree.

## Routing

File-based routing under `routes/`. Layouts via route context. No App Router / `app/` directory — that is the Next.js signal.

## Component & motion rules

Same component rules as the Next.js adapter (forwardRef, `cn()`, CVA variants, `'use client'` not needed — Vite is client-by-default). Motion: prefer CSS keyframes and `@tanstack/react-virtual` for lists; reach for framer-motion only for orchestrated animation. GSAP canon in `../references/accessibility-motion.md` applies if GSAP is introduced.

## Directory structure

```
src/
├── routes/                 # file-based routes
├── components/
│   ├── ui/                 # shadcn base
│   ├── blocks/
│   └── layout/
├── lib/
├── hooks/
├── services/              # API layer — routes never fetch directly
└── styles/
```
