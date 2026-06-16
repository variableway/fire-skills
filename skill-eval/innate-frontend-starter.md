---
name: innate-frontend-starter
description: Create production-ready frontend applications using innate-base template with shadcn/ui, reui, and advanced components. Use when building admin dashboards, landing pages, data applications, or SaaS products. Triggers on "innate starter", "frontend template", "admin dashboard", "landing page", "data app", "saas starter".
---

# Innate Frontend Starter

Build production-ready frontend applications using the innate-base template ecosystem with shadcn/ui, reui, and advanced component patterns.

## When to Use This Skill

- Creating new admin dashboards with sidebar navigation
- Building landing pages with hero, features, pricing sections
- Developing data-heavy applications with tables, charts, forms
- Setting up SaaS applications with authentication and payments
- Rapid prototyping of ToB (To-Business) applications

## Reference Implementation

The reference project is at `/Users/patrick/workspace/variableway/factory/innate-base` with:
- **Dual Framework Support**: Next.js 16 App Router + TanStack Router/Vite
- **60+ UI Components**: `@innate/ui` shared library based on shadcn/ui + Radix UI
- **Block Components**: Pre-built Landing, Auth, Mail, Chat page blocks
- **Scene Catalog System**: PatternScene + SpecificScene page organization

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Next.js 16 / TanStack Router + Vite |
| Language | TypeScript (strict mode) |
| Styling | Tailwind CSS 4.x |
| UI | @base-ui/react + @innate/ui (shadcn/ui) |
| Theme | next-themes (dark/light/system) |
| Charts | Recharts / ApexCharts |
| Forms | React Hook Form + Zod |
| Package Mgr | pnpm workspaces |

## Creating a New Innate Frontend Project

### Step 1: Choose Framework

**Option A: Next.js 16 (Recommended for Admin Dashboards)**
```bash
# Copy from reference
cp -r /Users/patrick/workspace/variableway/factory/innate-base/apps/admin-nextjs /path/to/my-app
cd /path/to/my-app
rm -rf .next dist node_modules

# Or create fresh
npx create-next-app@latest my-app --typescript --tailwind --eslint --app --src-dir
cd my-app
pnpm add @innate/ui @base-ui/react next-themes lucide-react class-variance-authority clsx tailwind-merge
```

**Option B: TanStack Router + Vite (Recommended for Rapid Development)**
```bash
# Copy from reference
cp -r /Users/patrick/workspace/variableway/factory/innate-base/apps/admin-tanstack /path/to/my-app
cd /path/to/my-app
rm -rf dist node_modules

# Or create fresh
pnpm create vite my-app --template react-ts
cd my-app
pnpm add @tanstack/react-router @tanstack/react-start @innate/ui @base-ui/react
pnpm add -D @tailwindcss/vite tailwindcss vite-tsconfig-paths
```

### Step 2: Configure UI Components

**Install Core Dependencies:**
```bash
# shadcn/ui components
pnpm add @innate/ui @base-ui/react

# Theme system
pnpm add next-themes

# Form handling
pnpm add react-hook-form @hookform/resolvers zod

# Data tables
pnpm add @tanstack/react-table

# Charts
pnpm add recharts

# Icons
pnpm add lucide-react
```

**Setup Global Styles:**
```css
/* src/app/globals.css (Next.js) or src/styles.css (TanStack) */
@import "@innate/ui/globals.css";

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 240 10% 3.9%;
    /* ... full theme variables from @innate/ui/globals.css */
  }
  .dark {
    --background: 240 10% 3.9%;
    --foreground: 0 0% 98%;
    /* ... */
  }
}
```

### Step 3: Setup Theme Provider

**Next.js:**
```tsx
// src/app/providers.tsx
"use client"
import { ThemeProvider as NextThemesProvider } from "next-themes"

export function Providers({ children, ...props }: React.ComponentProps<typeof NextThemesProvider>) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>
}

// src/app/layout.tsx
import { Providers } from "./providers"
import { TooltipProvider } from "@innate/ui"

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html suppressHydrationWarning>
      <body>
        <Providers attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
          <TooltipProvider>
            {children}
          </TooltipProvider>
        </Providers>
      </body>
    </html>
  )
}
```

**TanStack Router:**
```tsx
// src/main.tsx
import { ThemeProvider } from "next-themes"
import { RouterProvider, createRouter } from "@tanstack/react-router"

const router = createRouter({ routeTree })

function App() {
  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
      <RouterProvider router={router} />
    </ThemeProvider>
  )
}
```

### Step 4: Create Layout Shell

**Admin Dashboard Layout:**
```tsx
// Next.js: src/app/(with-layout)/layout.tsx
// TanStack: src/routes/__root.tsx
"use client"
import { SidebarProvider, SidebarInset } from "@innate/ui"
import { AppSidebar } from "@/components/app-sidebar"
import { SiteHeader } from "@/components/site-header"

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <SidebarProvider>
      <AppSidebar />
      <SidebarInset>
        <SiteHeader />
        <main className="flex flex-1 flex-col gap-4 p-4 pt-0">
          {children}
        </main>
      </SidebarInset>
    </SidebarProvider>
  )
}
```

### Step 5: Create Pages Using Blocks

**Landing Page:**
```tsx
import {
  HeroSection,
  FeaturesSection,
  PricingSection,
  TestimonialsSection,
  FaqSection,
  CTASection,
} from "@innate/ui"

export default function LandingPage() {
  return (
    <main>
      <HeroSection
        badge={{ text: "New: Feature Released" }}
        title="Build Better Web Applications"
        subtitle="Accelerate development with our curated collection."
        primaryCta={{ text: "Get Started", href: "/signup" }}
        secondaryCta={{ text: "Watch Demo", href: "#demo" }}
      />
      <FeaturesSection
        badge="Features"
        title="Everything you need"
        features={[
          { icon: ZapIcon, title: "Fast", description: "Lightning-fast performance" },
          { icon: ShieldIcon, title: "Secure", description: "Enterprise-grade security" },
        ]}
      />
      <PricingSection
        badge="Pricing"
        title="Choose your plan"
        plans={[
          { name: "Free", price: 0, features: [...] },
          { name: "Pro", price: 19, features: [...], popular: true },
        ]}
      />
      <CTASection
        title="Get started today"
        primaryCta={{ text: "Sign Up", href: "/signup" }}
      />
    </main>
  )
}
```

**Admin Dashboard Page:**
```tsx
import { Card, CardContent, CardHeader, CardTitle } from "@innate/ui"
import { DataTable } from "@/components/data-table"
import { Chart } from "@/components/chart"

export default function DashboardPage() {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      <Card>
        <CardHeader><CardTitle>Total Users</CardTitle></CardHeader>
        <CardContent><p className="text-2xl font-bold">1,234</p></CardContent>
      </Card>
      <Card>
        <CardHeader><CardTitle>Revenue</CardTitle></CardHeader>
        <CardContent><p className="text-2xl font-bold">$45,678</p></CardContent>
      </Card>
      {/* Charts and tables */}
      <Card className="col-span-2">
        <CardHeader><CardTitle>Analytics</CardTitle></CardHeader>
        <CardContent><Chart data={chartData} /></CardContent>
      </Card>
    </div>
  )
}
```

## Available Components

### From `@innate/ui` (60+)

**Layout**: Card, Separator, Resizable, ScrollArea, Sidebar
**Navigation**: Tabs, Breadcrumb, Pagination, Menubar
**Forms**: Input, Textarea, Select, Checkbox, RadioGroup, Switch, Calendar, Form
**Feedback**: Dialog, Sheet, Drawer, AlertDialog, Tooltip, Sonner
**Data Display**: Table, Badge, Avatar, Progress, Skeleton, Chart
**Actions**: Button, Toggle, ToggleGroup, DropdownMenu, Command

### Block Components

**Landing**: HeroSection, FeaturesSection, PricingSection, TestimonialsSection, FaqSection, StatsSection, CTASection
**Auth**: LoginForm, SignupForm
**Mail**: Inbox, MailList, MailDisplay
**Chat**: ChatInterface, MessageList

### Advanced Components (from reui integration)

**Data**: DataGrid, Kanban, Timeline, Sortable
**Forms**: TagsInput, Mention, ComboboxAdvanced, ColorPicker
**Display**: Tree, Stepper, Rating, Signature, QRCode

## Scene Catalog System

Both admin apps use a scene catalog for organizing feature pages:

```tsx
// src/lib/scene-catalog.ts
export interface PatternSceneSample {
  id: string
  title: string
  description: string
  category: string
}

export interface SpecificSceneSample {
  id: string
  title: string
  description: string
  patternId: string
}
```

## Project Structure

```
src/
├── app/ (Next.js) or src/routes/ (TanStack)
│   ├── (with-layout)/           # Route group with shared shell
│   │   ├── layout.tsx           # SidebarProvider + AppSidebar + SiteHeader
│   │   ├── page.tsx             # Homepage
│   │   └── my-page/page.tsx     # /my-page route
│   ├── layout.tsx               # Root layout (ThemeProvider)
│   └── providers.tsx            # ThemeProvider wrapper
├── components/
│   ├── app-sidebar/             # Sidebar component
│   ├── site-header/             # Header component
│   ├── ui/                      # Local shadcn/ui components
│   └── blocks/                  # Custom block components
├── lib/
│   └── scene-catalog.ts         # Scene data
└── styles/
    └── globals.css              # Tailwind + theme variables
```

## Key Dependencies

```json
{
  "@innate/ui": "workspace:*",
  "@base-ui/react": "^1.4.1",
  "next": "^16.1.6",
  "next-themes": "^0.4.6",
  "tailwindcss": "^4.2.4",
  "class-variance-authority": "^0.7.1",
  "clsx": "^2.1.1",
  "tailwind-merge": "^3.5.0",
  "lucide-react": "^0.511.0",
  "recharts": "2.15.4",
  "sonner": "^2.0.7",
  "zod": "^4.3.6",
  "@tanstack/react-table": "^8.21.3",
  "react-hook-form": "^7.54.0",
  "@hookform/resolvers": "^3.9.0"
}
```

## Template References

| Template | Key Strength | Use Case |
|----------|-------------|----------|
| shadcn-ui | Official component library, 57+ components | Foundation |
| reui | 1000+ components, 17 in-house primitives | Advanced data UIs |
| shadcn-dashboard | 30+ pages, landing + dashboard | Full admin systems |
| tweakcn | Theme editor, AI integration | Theme prototyping |
| velocify | AI SaaS starter (Clerk + Stripe) | SaaS applications |

## Notes

- All components use `"use client"` where needed (App Router requirement)
- Data files in `lib/` must have zero UI imports (pure data/logic)
- Theme toggle uses `next-themes` with class strategy
- Both frameworks must stay compatible with `@innate/ui` updates
- For advanced data components, consider integrating reui primitives
