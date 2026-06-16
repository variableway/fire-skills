---
name: dev-setup
description: Quick local development setup for innate-base and innate-apps projects. Use when the user wants to start developing, run the dev server, or set up the development environment. Trigger on "start dev", "run dev", "setup environment", "how to run", "development setup".
---

# Dev Setup

Quick local development setup and common commands.

## Prerequisites

- Node.js 20+
- pnpm 11+

## Initial Setup

```bash
# Clone and install
cd /Users/patrick/workspace/variableway/factory
git clone <repo-url> innate-apps
cd innate-apps
pnpm install
```

## Run Applications

### All Apps (Parallel)

```bash
pnpm dev
```

### Individual Apps

```bash
# Next.js admin (port 4002)
pnpm --filter @innate/admin-nextjs-demo dev

# TanStack admin (port 4001)
pnpm --filter @innate/admin-tanstack-demo dev
```

### From innate-base

```bash
cd ../innate-base
pnpm install
pnpm dev
```

## Build & Check

```bash
# Typecheck all packages
pnpm typecheck

# Build all packages
pnpm build

# Lint all packages
pnpm lint
```

## Working with @innate/ui

```bash
# The UI package is at innate-base/packages/ui
# It's referenced via workspace:* in all apps

# To add a new shadcn component:
cd ../innate-base/packages/ui
npx shadcn@latest add <component-name>
```

## Project Structure

```
factory/
├── innate-base/          # Web foundation (UI, templates, skills)
│   ├── packages/ui/      # @innate/ui (60+ components)
│   └── apps/             # Template demo apps
├── innate-runtime/       # AI Agent runtime packages
├── innate-desktop/       # Desktop app (Tauri)
└── innate-apps/          # Application holder
    └── apps/             # Your projects go here
```

## Common Tasks

### Add a New Page

```bash
# Next.js
mkdir -p apps/my-app/src/app/\(with-layout\)/new-page
echo 'export default function Page() { return <div>New Page</div> }' > apps/my-app/src/app/\(with-layout\)/new-page/page.tsx

# TanStack
echo 'import { createFileRoute } from "@tanstack/react-router"
export const Route = createFileRoute("/new-page")({ component: () => <div>New Page</div> })' > apps/my-app/src/routes/new-page.tsx
```

### Add a UI Component

```tsx
import { Button, Card, Dialog } from "@innate/ui"
```

### Check TypeScript

```bash
pnpm typecheck
# Or for a specific package:
pnpm --filter @innate/ui typecheck
```

## Troubleshooting

### Port Already in Use

```bash
# Find process on port
lsof -i :4001
# Kill it
kill -9 <PID>
```

### Type Errors

```bash
# Clean and reinstall
rm -rf node_modules packages/*/node_modules apps/*/node_modules
pnpm install
pnpm typecheck
```

### Build Failures

```bash
# Check workspace config
cat pnpm-workspace.yaml
# Ensure all workspace:* refs resolve correctly
pnpm ls --depth 0 -r | grep @innate
```
