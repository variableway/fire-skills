---
name: "frontend-dev"
description: "Next.js 或者tanstack + TypeScript + shadcn/ui 前端开发。适用于创建页面、组件、表单、数据表、Dashboard 和 SaaS 界面。"
---

# Frontend 开发技能

## 角色

你是前端开发工程师。根据项目实际情况选择 Next.js 或 TanStack Router 技术栈，以 innate-base 为基础框架进行开发。

## 框架选取规则

**判断当前项目使用的框架：**

- 存在 `next.config.*`、`app/` 目录、`next` 依赖 → **Next.js**
- 存在 `@tanstack/react-router` 依赖、`routes/` 目录、`vite.config.*` 且无 `next` 依赖 → **TanStack Router**

| 当前项目框架 | 参考实现 | 不允许查看 |
|--------------|----------|------------|
| Next.js | `/Users/patrick/workspace/variableway/factory/innate-base/apps/admin-nextjs` | ~~admin-tanstack~~ |
| TanStack Router | `/Users/patrick/workspace/variableway/factory/innate-base/apps/admin-tanstack` | ~~admin-nextjs~~ |

> 核心原则：**Next.js 项目不看 TanStack 参考，TanStack 项目不看 Next.js 参考。** 判断后只读取对应项目的代码和组件。

## 技术栈

| 层 | Next.js | TanStack Router |
|---|---|---|
| 框架 | Next.js 16 (App Router) | TanStack Router + Vite |
| 参考实现 | `innate-base/apps/admin-nextjs` | `innate-base/apps/admin-tanstack` |
| 语言 | TypeScript (strict mode) | TypeScript (strict mode) |
| 样式 | Tailwind CSS 4.x | Tailwind CSS 4.x |
| UI 组件 | `@innate/ui` + admin-nextjs 本地组件 | `@innate/ui` + admin-tanstack 本地组件 |
| 主题 | next-themes | next-themes |
| 表单 | React Hook Form + Zod | React Hook Form + Zod |
| 图标 | Lucide React | Lucide React |
| 表格 | @tanstack/react-table | @tanstack/react-table |
| 包管理 | pnpm workspaces | pnpm workspaces |

## 基础参考

innate-base 是参考实现项目，位于 `/Users/patrick/workspace/variableway/factory/innate-base`。开发时优先参考与当前项目框架一致的 `apps/` 子项目。

**Next.js 参考代码结构**（`innate-base/apps/admin-nextjs/src/`）：

```
src/
├── app/                        # App Router 路由（layout, providers, 业务路由）
├── components/
│   ├── admin/components/ui/   # shadcn 基础组件（22+）
│   ├── admin/components/layout/ # app-sidebar, nav-secondary, nav-user, site-header
│   ├── admin/components/      # data-table, section-cards
│   ├── auth/                  # signin, signup, google-signin-button
│   ├── charts/                # campaign-visitors, payments-overview, used-devices, weeks-profit
│   ├── form-elements/         # checkbox, date-picker, input-group, multi-select, radio, select, switch, switcher, text-area
│   ├── theme-provider/        # 主题系统
│   ├── theme-selector/        # 主题选择器
│   └── theme-toggle/          # 主题切换
├── lib/                       # auth, db, utils, scene-catalog
├── hooks/                     # use-click-outside, use-mobile
├── services/                  # charts.services
├── styles/                    # globals.css, nextjs-theme.css
└── themes/                    # linear.css, notion.css
```

## 组件来源

开发时按以下优先级选择组件：

| 优先级 | 来源 | 说明 |
|--------|------|------|
| 1 | `@innate/ui` | 基础 shadcn/ui 封装（60+ 组件），全局安装 |
| 2 | 对应框架的 admin 本地组件 | Next.js → `innate-base/apps/admin-nextjs/src/components/`，TanStack → `innate-base/apps/admin-tanstack/src/components/` |

**admin-nextjs 可用组件清单**（`innate-base/apps/admin-nextjs/src/components/`）：

- **UI 基础组件** (`admin/components/ui/`)：avatar, badge, breadcrumb, button, card, checkbox, dialog, dropdown-menu, empty, field, input, label, scroll-area, select, separator, sheet, sidebar, skeleton, sonner, table, tabs, tooltip
- **布局组件** (`admin/components/layout/`)：app-sidebar, nav-secondary, nav-user, site-header
- **数据组件** (`admin/components/`)：data-table, section-cards
- **图表组件** (`charts/`)：campaign-visitors, payments-overview, used-devices, weeks-profit
- **表单组件** (`form-elements/`)：checkbox, date-picker, input-group, multi-select, radio, select, switch, switcher, text-area
- **认证组件** (`auth/`)：signin, signup, google-signin-button
- **主题组件**：theme-provider, theme-selector, theme-toggle

- class 合并工具：`cn()` from `@innate/ui` 或项目本地的 `lib/utils`

## 目录结构

```
src/
├── app/                    # Next.js App Router 路由
│   ├── layout.tsx          # Root Layout
│   ├── page.tsx            # 首页
│   └── (routes)/           # 路由分组
├── components/
│   ├── ui/                 # shadcn/ui 基础组件
│   ├── blocks/             # 页面块组件
│   └── layout/             # 布局组件 (sidebar, header)
├── lib/                    # 纯函数/工具（不依赖 UI）
├── hooks/                  # 自定义 React Hooks
├── services/               # API 服务层
└── styles/                 # 全局样式
```

## 核心规则

### 组件规范

1. 使用 TypeScript，提供完整的 Props 类型定义
2. 使用 `React.forwardRef` 暴露 ref
3. 使用 `cn()` 合并 className，支持 variant/size 变体
4. 涉及 hooks 或浏览器 API 时加 `"use client"` 指令
5. shadcn/ui 已有的基础组件不得用 raw HTML 重造

```typescript
// components/ui/my-component.tsx
import * as React from "react"
import { cn } from "@innate/ui"

interface MyComponentProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: "default" | "secondary"
  size?: "sm" | "md" | "lg"
}

const MyComponent = React.forwardRef<HTMLDivElement, MyComponentProps>(
  ({ variant = "default", size = "md", className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn(
          "base-styles",
          variant === "secondary" && "secondary-styles",
          size === "sm" && "text-sm",
          size === "lg" && "text-lg",
          className
        )}
        {...props}
      />
    )
  }
)
MyComponent.displayName = "MyComponent"

export { MyComponent }
```

### 文件命名

| 类型 | 规则 | 示例 |
|------|------|------|
| 组件 | PascalCase | `UserProfile.tsx` |
| Hooks | camelCase + use 前缀 | `useAuth.ts` |
| 工具函数 | camelCase | `formatDate.ts` |
| 类型 | PascalCase | `UserType.ts` |

### 导入顺序

```typescript
// 1. 外部库
import React from "react"
import { useForm } from "react-hook-form"

// 2. UI 组件
import { Button } from "@innate/ui"
import { Card } from "@/components/ui/card"

// 3. 内部 hooks/tools
import { useAuth } from "@/hooks/use-auth"
import { formatDate } from "@/lib/utils"
```

### 表单规范

使用 React Hook Form + Zod 验证：

```typescript
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"

const schema = z.object({
  name: z.string().min(1, "必填"),
  email: z.string().email("格式错误"),
})

type FormData = z.infer<typeof schema>

function MyForm() {
  const form = useForm<FormData>({
    resolver: zodResolver(schema),
  })
  // ...
}
```

### 数据表规范

使用 `@tanstack/react-table`，支持排序、筛选、分页、行选择。

### API 调用规范

API 调用集中在 `services/` 目录中，使用 typed service 方式调用。页面组件不直接写 fetch/axios。

## 关联 Skill

当涉及以下场景时，需同时加载对应 Skill：

| Skill | 触发场景 |
|-------|----------|
| `fe-code-structure`（`frontend-code-organization`）| 代码目录重组、模块拆分合并、大文件降维、共享出口收敛 |

## 关键约束

- 项目已有代码约定优先于本规则；与现有代码保持一致
- 不引入项目中已有等价方案的新库
- 避免过早抽象，三行重复好过错误抽象
- 改动做最小充分修复，不顺手重构无关代码
- 优先复用 `@innate/ui` 已有组件，不重复造轮子
