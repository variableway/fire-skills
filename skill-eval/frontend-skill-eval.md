# Frontend Skill Evaluation

## Purpose

This document evaluates and recommends frontend development skills for rapid small program development, based on the innate-base template project and existing skill ecosystem.

## Top 15 Recommended Skills

### 1. shadcn-ui (Official)
- **Description**: Official shadcn/ui component library with 57+ base components and 75+ blocks
- **Tech Stack**: Next.js 16, React 19, Tailwind CSS, Radix UI
- **Strengths**: Copy-paste model, full customization, CSS variable theming
- **Use Case**: Foundation for all UI components

### 2. reui (Design-Forward)
- **Description**: 1000+ components across 68 categories with 17 in-house primitives
- **Tech Stack**: Next.js, React 18+, Tailwind CSS v4
- **Strengths**: Advanced data components (Data Grid, Kanban, Timeline), dual library support
- **Use Case**: Complex data-heavy applications

### 3. awesome-shadcn-ui (Resource Directory)
- **Description**: Community resource directory with 60+ components and OKLCH color space
- **Tech Stack**: Next.js 16, React 19, Tailwind CSS v4
- **Strengths**: Directory/catalog patterns, search/filter/sort components
- **Use Case**: Directory and showcase interfaces

### 4. admin-nextjs-starter (Innate Template)
- **Description**: Production-ready admin dashboard with Next.js 16 App Router
- **Tech Stack**: Next.js 16, @innate/ui, next-themes
- **Strengths**: Route groups, scene catalog system, theme toggle
- **Use Case**: Admin panels with sidebar navigation

### 5. admin-tanstack-starter (Innate Template)
- **Description**: Admin dashboard with TanStack Router + Vite
- **Tech Stack**: TanStack Router, Vite, @innate/ui
- **Strengths**: File-based routing, fast development, local shadcn/ui components
- **Use Case**: Rapid admin dashboard development

### 6. shadcn-ui-blocks (Innate Template)
- **Description**: Pre-built landing, auth, mail, and chat page blocks
- **Tech Stack**: Next.js, @innate/ui, block components
- **Strengths**: Data-driven blocks, reusable patterns
- **Use Case**: Quick page assembly

### 7. tweakcn (Theme Editor)
- **Description**: Theme editor with AI integration and live preview
- **Tech Stack**: Next.js, shadcn/ui
- **Strengths**: Visual theme customization, AI-assisted design
- **Use Case**: Theme prototyping and customization

### 8. shadcn-dashboard (Dashboard Template)
- **Description**: 30+ pages with landing + dashboard, dual framework support
- **Tech Stack**: Next.js, React, shadcn/ui
- **Strengths**: Comprehensive page collection, production-ready
- **Use Case**: Full-featured admin dashboards

### 9. velocify (AI SaaS Starter)
- **Description**: AI SaaS starter with Clerk + Stripe + Claude integration
- **Tech Stack**: Next.js, Clerk, Stripe, AI SDK
- **Strengths**: Authentication, payments, AI integration
- **Use Case**: SaaS applications with auth and payments

### 10. ai-sdk-rag (RAG Chatbot)
- **Description**: RAG chatbot starter with vector database integration
- **Tech Stack**: Next.js, AI SDK, vector DB
- **Strengths**: AI-powered chat, document retrieval
- **Use Case**: AI chatbots and document Q&A

### 11. nextra-starter (Documentation Site)
- **Description**: Documentation site with i18n support
- **Tech Stack**: Next.js, Nextra, MDX
- **Strengths**: Internationalization, documentation patterns
- **Use Case**: Technical documentation sites

### 12. shadcn-cheatsheet (Interactive Reference)
- **Description**: Interactive component reference and playground
- **Tech Stack**: Next.js, shadcn/ui
- **Strengths**: Live component examples, interactive demos
- **Use Case**: Component reference and learning

### 13. ui-creative-tim (Premium Blocks)
- **Description**: Premium marketing, e-commerce, and Web3 blocks
- **Tech Stack**: Next.js, React, shadcn/ui
- **Strengths**: High-quality design, business-focused components
- **Use Case**: Marketing sites and e-commerce

### 14. form-builder (Form Patterns)
- **Description**: Advanced form patterns with React Hook Form + Zod
- **Tech Stack**: React Hook Form, Zod, shadcn/ui
- **Strengths**: Form validation, multi-step forms, complex forms
- **Use Case**: Data entry applications

### 15. data-table (Table Patterns)
- **Description**: Advanced data table with sorting, filtering, pagination
- **Tech Stack**: TanStack Table, shadcn/ui
- **Strengths**: Inline editing, bulk actions, column management
- **Use Case**: Data-heavy admin interfaces

## Evaluation Criteria

### 1. Component Quality
- Accessibility (WCAG compliance)
- TypeScript support
- Customization flexibility
- Documentation quality

### 2. Developer Experience
- Setup complexity
- Learning curve
- Community support
- Maintenance status

### 3. Project Fit
- Compatibility with innate-base
- Integration with @innate/ui
- Support for admin/dashboard patterns
- Theme system compatibility

### 4. Performance
- Bundle size
- Rendering performance
- SSR/SSG support

## Recommended Skill Combinations

### For Admin Dashboards
1. **Base**: admin-nextjs-starter or admin-tanstack-starter
2. **Components**: shadcn-ui + reui (for advanced data components)
3. **Blocks**: shadcn-ui-blocks
4. **Theme**: tweakcn

### For Landing Pages
1. **Base**: shadcn-ui-blocks
2. **Components**: shadcn-ui
3. **Design**: ui-creative-tim
4. **Theme**: tweakcn

### For Data Applications
1. **Base**: admin-tanstack-starter
2. **Components**: reui (Data Grid, Kanban, Filters)
3. **Tables**: data-table
4. **Forms**: form-builder

### For AI/SaaS Applications
1. **Base**: velocify
2. **AI**: ai-sdk-rag
3. **Components**: shadcn-ui
4. **Auth**: Clerk integration

## Next Steps

1. Create preliminary skill based on Top 15 and innate-base
2. Develop project constraint methods
3. Implement skill evaluation code
