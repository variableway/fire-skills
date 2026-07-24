# Project Constraints Methods

## Purpose

This document provides methods and first version documentation for establishing project constraints when using the innate-frontend-starter skill.

## Constraint Categories

### 1. Technical Constraints

#### Framework Constraints
- **Next.js Projects**: Must use App Router (not Pages Router)
- **TanStack Projects**: Must use file-based routing
- **TypeScript**: Strict mode required (`"strict": true`)
- **Node.js**: Version 18+ required

#### Styling Constraints
- **Tailwind CSS**: Version 4.x required
- **CSS Variables**: Must use CSS variables for theming
- **Component Styling**: Use `class-variance-authority` for variants
- **Utility Function**: Use `cn()` from `@innate/ui` for class merging

#### UI Component Constraints
- **Base Library**: Must use `@innate/ui` as primary component source
- **Custom Components**: Must follow shadcn/ui conventions
- **Accessibility**: Must use Radix UI primitives for accessibility
- **Icons**: Use Lucide React for icons

### 2. Architecture Constraints

#### Project Structure
```
src/
├── app/ or routes/           # Framework-specific routing
├── components/
│   ├── ui/                   # shadcn/ui components
│   ├── blocks/               # Block components
│   └── layout/               # Layout components (sidebar, header)
├── lib/                      # Pure data/logic (no UI imports)
├── hooks/                    # Custom React hooks
├── services/                 # API service layer
└── styles/                   # Global styles
```

#### File Naming Conventions
- **Components**: PascalCase (e.g., `UserProfile.tsx`)
- **Hooks**: camelCase with `use` prefix (e.g., `useAuth.ts`)
- **Utils**: camelCase (e.g., `formatDate.ts`)
- **Types**: PascalCase (e.g., `UserType.ts`)

#### Import Order
```typescript
// 1. External libraries
import React from "react"
import { useForm } from "react-hook-form"

// 2. Internal components
import { Button } from "@innate/ui"
import { Card } from "@/components/ui/card"

// 3. Internal hooks/utils
import { useAuth } from "@/hooks/use-auth"
import { formatDate } from "@/lib/utils"
```

### 3. Component Constraints

#### Component Creation Rules
1. **Must use TypeScript** with proper typing
2. **Must support props** with default values
3. **Must use `"use client"`** if using React hooks or browser APIs
4. **Must follow compound component pattern** for complex components
5. **Must include accessibility attributes** (aria-labels, roles)

#### Component File Structure
```typescript
// components/ui/my-component.tsx
import * as React from "react"
import { cn } from "@/lib/utils"

interface MyComponentProps {
  variant?: "default" | "secondary"
  size?: "sm" | "md" | "lg"
  children: React.ReactNode
  className?: string
}

const MyComponent = React.forwardRef<HTMLDivElement, MyComponentProps>(
  ({ variant = "default", size = "md", children, className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn(
          "base-styles",
          variantStyles[variant],
          sizeStyles[size],
          className
        )}
        {...props}
      >
        {children}
      </div>
    )
  }
)
MyComponent.displayName = "MyComponent"

export { MyComponent }
```

### 4. Page Constraints

#### Page Creation Rules
1. **Must use layout system** (route groups for Next.js, root route for TanStack)
2. **Must include proper metadata** (title, description)
3. **Must use block components** when available
4. **Must follow scene catalog pattern** for navigation

#### Page File Structure
```typescript
// app/(with-layout)/dashboard/page.tsx
import type { Metadata } from "next"
import { Card, CardContent, CardHeader, CardTitle } from "@innate/ui"

export const metadata: Metadata = {
  title: "Dashboard",
  description: "Admin dashboard overview"
}

export default function DashboardPage() {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      <Card>
        <CardHeader>
          <CardTitle>Total Users</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-2xl font-bold">1,234</p>
        </CardContent>
      </Card>
    </div>
  )
}
```

### 5. Theme Constraints

#### Theme System Rules
1. **Must use CSS variables** for all colors
2. **Must support dark/light/system** modes
3. **Must use `next-themes`** for theme switching
4. **Must include `suppressHydrationWarning`** on `<html>` tag

#### Theme Variable Structure
```css
:root {
  /* Base colors */
  --background: 0 0% 100%;
  --foreground: 240 10% 3.9%;
  
  /* Card */
  --card: 0 0% 100%;
  --card-foreground: 240 10% 3.9%;
  
  /* Primary */
  --primary: 240 5.9% 10%;
  --primary-foreground: 0 0% 98%;
  
  /* Secondary */
  --secondary: 240 4.8% 95.9%;
  --secondary-foreground: 240 5.9% 10%;
}

.dark {
  --background: 240 10% 3.9%;
  --foreground: 0 0% 98%;
  /* ... */
}
```

### 6. Performance Constraints

#### Bundle Optimization
1. **Tree-shaking**: Use named imports
2. **Code splitting**: Use dynamic imports for large components
3. **Image optimization**: Use Next.js Image component
4. **Font optimization**: Use Next.js font optimization

#### Rendering Performance
1. **Server Components**: Use for static content
2. **Client Components**: Use only when needed (hooks, browser APIs)
3. **Memoization**: Use `React.memo` for expensive computations
4. **Virtualization**: Use for large lists (react-window)

### 7. Security Constraints

#### Input Validation
1. **Client-side**: Use Zod schemas with React Hook Form
2. **Server-side**: Always validate on server
3. **Sanitization**: Sanitize user inputs
4. **XSS Prevention**: Use React's built-in XSS protection

#### Authentication
1. **Session Management**: Use secure HTTP-only cookies
2. **Token Handling**: Store tokens securely
3. **Route Protection**: Implement middleware for protected routes
4. **CORS**: Configure proper CORS policies

## First Version Documentation

### Constraint Checklist

#### Before Starting Project
- [ ] Choose framework (Next.js or TanStack)
- [ ] Setup TypeScript with strict mode
- [ ] Install @innate/ui and dependencies
- [ ] Configure Tailwind CSS 4.x
- [ ] Setup theme system with next-themes

#### During Development
- [ ] Follow project structure constraints
- [ ] Use proper component patterns
- [ ] Implement accessibility features
- [ ] Follow naming conventions
- [ ] Use proper import order

#### Before Deployment
- [ ] Run type checking (`pnpm typecheck`)
- [ ] Run linting (`pnpm lint`)
- [ ] Test accessibility
- [ ] Optimize bundle size
- [ ] Security audit

### Constraint Violation Examples

#### ❌ Wrong: Direct color values
```css
.my-component {
  color: #000000;
  background: #ffffff;
}
```

#### ✅ Correct: CSS variables
```css
.my-component {
  color: var(--foreground);
  background: var(--background);
}
```

#### ❌ Wrong: Missing "use client"
```typescript
// This will fail in Next.js App Router
import { useState } from "react"

export function MyComponent() {
  const [count, setCount] = useState(0)
  return <div>{count}</div>
}
```

#### ✅ Correct: Added "use client"
```typescript
"use client"
import { useState } from "react"

export function MyComponent() {
  const [count, setCount] = useState(0)
  return <div>{count}</div>
}
```

#### ❌ Wrong: Inline styles
```tsx
<div style={{ color: 'red', fontSize: '16px' }}>
  Hello
</div>
```

#### ✅ Correct: Tailwind classes
```tsx
<div className="text-red-500 text-base">
  Hello
</div>
```

## Constraint Enforcement Tools

### 1. ESLint Rules
```javascript
// .eslintrc.js
module.exports = {
  extends: [
    "next/core-web-vitals",
    "plugin:@typescript-eslint/recommended"
  ],
  rules: {
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/explicit-function-return-type": "warn",
    "react-hooks/rules-of-hooks": "error",
    "react-hooks/exhaustive-deps": "warn"
  }
}
```

### 2. TypeScript Configuration
```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  }
}
```


