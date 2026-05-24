---
name: innate-frontend
description: "使用 Next.js + React 19 + TypeScript + Tailwind CSS v4 + @innate/ui 组件库快速搭建 Web 前端应用。提供 57+ UI 组件、7 个 Landing 区块、Auth/Mail/Chat 业务区块、OKLCH 主题系统、项目验证规则。配合 desktop-app Skill 可构建桌面应用。"
type: skill
supported_agents:
  - claude-code
  - kimi
  - codex
  - opencode
  - trae
  - trae-solo
  - workbuddy
---

# Innate Frontend Skill

统一的 Web 前端开发 Skill，基于 [innate-next-mono](https://github.com/variableway/innate-next-mono) 聚合型 Starter 项目。

采用"社区组件 + 自定义配置层"模式：基础 UI 组件通过 shadcn/ui CLI 安装，营销区块通过 21st.dev 获取，主题系统和业务区块（Landing/Auth/Chat/Mail）由 `@innate/ui` 维护。配合 Next.js 16 + Tailwind CSS v4 + OKLCH 主题系统。

> **桌面应用**：如需构建 Tauri 桌面应用，请使用 `desktop-app` Skill。本 Skill 聚焦 Web 前端。

## 技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| Next.js | 16+ | React 框架（App Router） |
| React | 19 | UI 库 |
| TypeScript | 6 | 类型安全 |
| Tailwind CSS | 4 | 样式系统（OKLCH 色彩空间） |
| @innate/ui | workspace | UI 组件库（基于 Radix UI + shadcn/ui） |
| pnpm | workspace | 包管理 + monorepo |
| Lucide React | latest | 图标库 |
| React Hook Form + Zod | latest | 表单验证 |
| Recharts | 3.x | 图表 |
| Framer Motion | latest | 动画库 |

## 快速复用（跨项目）

> 后端开发者懂前端——核心诉求是**不要重复造轮子**。

### 复用策略一览

| 方式 | 适用场景 | 优点 | 缺点 |
|------|---------|------|------|
| **Monorepo 引用** | 多个相关项目 | 零安装，一处更新全局生效 | 项目必须都在同一 repo |
| **复制组件代码** | 独立项目 | 完全独立，可自由定制 | 更新需手动同步 |
| **实时安装** | 临时/探索 | 获取最新版本 | 网络依赖，配置重复 |

### 方式一：Monorepo 内引用（推荐）

所有 Web 应用放在 `apps/` 下，共享 `packages/ui/` 组件库：

```bash
cd innate-next-mono
mkdir apps/my-new-project
cd apps/my-new-project

# 直接引用，无需安装
import { Button, Card } from "@innate/ui"
import "@innate/ui/globals.css"
```

在 `package.json` 中添加 workspace 依赖：
```json
{
  "dependencies": {
    "@innate/ui": "workspace:*"
  }
}
```

### 方式二：复制组件代码到独立项目

```bash
# 1. 创建新项目
npx shadcn@latest init --yes --template next --base-color zinc

# 2. 从 innate-next-mono 复制组件
cp -r innate-next-mono/packages/ui/src/components/ui/* my-project/components/ui/
cp innate-next-mono/packages/ui/src/globals.css my-project/app/globals.css
cp innate-next-mono/packages/ui/src/lib/utils.ts my-project/lib/utils.ts

# 3. 复制业务区块（可选）
cp -r innate-next-mono/packages/ui/src/block/* my-project/components/block/
```

### 方式三：实时安装（按需）

```bash
# 基础组件
npx shadcn@latest add button card dialog

# 21st.dev 营销区块
npx shadcn@latest add "https://21st.dev/r/..."
```

## 设计哲学

创建有辨识度、生产级的界面。拒绝千篇一律的"AI 味"设计。

- **禁止**使用 Inter、Roboto、Poppins、Montserrat、Open Sans 等过度使用的字体
- **禁止**在白底上使用紫色渐变等陈词滥调
- **禁止**套用 cookie-cutter 布局
- **必须**在写代码前先确定一个大胆的美学方向
- 始终配对使用 display font + body font

## 组件来源：21st.dev

在从头编写任何 UI 组件之前，先检查 https://21st.dev 是否已有生产就绪的版本。

**安装组件：**
```bash
npx shadcn@latest add "[component-url-from-21st.dev]"
```

**关键分类：**
- **Marketing Blocks**: Heroes、Features、CTA、Backgrounds、Testimonials、Pricing、Footers
- **UI Components**: Buttons、Inputs、Cards、Selects、Dialogs、Tables、AI Chats、Sidebars
- **完整目录**: https://21st.dev/community/components

**重要规则**：安装了 21st.dev 组件后，**必须使用它**。不要安装后又手写一个自定义版本替代。如果安装了 navbar 组件，就删除手写的 navbar 并使用安装的版本。安装后不使用的组件称为"孤儿组件（orphaned installs）"，必须避免。

## 触发条件

当用户说"创建 Web 应用"、"新建前端项目"、"创建页面"、"innate-frontend"、"使用 innate-ui 组件"等时触发。

当需要构建任何 Web 前端页面或组件时，应遵循本 Skill 的规范。

## 组件库总览

### 基础组件（57+ 个）

**表单控件**：Button, ButtonGroup, Input, InputGroup, InputOTP, Textarea, Select, Checkbox, RadioGroup, Switch, Slider, Field, Label, Form

**布局组件**：Card, Separator, ScrollArea, Resizable, AspectRatio, Collapsible, Sidebar, Container

**导航组件**：Tabs, Accordion, Breadcrumb, NavigationMenu, Menubar, Pagination

**数据展示**：Table, Badge, Avatar, Progress, Skeleton, Chart, Spinner, Kbd, Item

**反馈组件**：Alert, AlertDialog, Toast, Sonner, Tooltip, HoverCard

**覆盖层**：Dialog, Sheet, Drawer, Popover, DropdownMenu, ContextMenu, Command

**其他**：Calendar, Carousel, Toggle, ToggleGroup, Empty, useMobile, useToast

### 业务区块组件

**Landing 区块**（7 个）：
- `HeroSection` — 英雄区域，支持 badge、高亮标题、双 CTA
- `FeaturesSection` — 特性展示网格
- `PricingSection` — 价格方案
- `TestimonialsSection` — 用户评价
- `FaqSection` — 常见问题（手风琴式）
- `StatsSection` — 数据统计
- `CTASection` — 行动召唤

**Auth 区块**：LoginForm

**Mail 区块**：Inbox, MailList, MailDisplay

**Chat 区块**：ChatInterface, MessageList

## 使用指南

### Step 1: 导入组件

```tsx
// 基础组件 — 从 @innate/ui 直接导入
import { Button, Card, CardHeader, CardContent, Dialog, DialogTrigger, DialogContent } from "@innate/ui"

// 业务区块 — 同样从 @innate/ui 导入
import { HeroSection, FeaturesSection, PricingSection } from "@innate/ui"

// 工具函数
import { cn } from "@innate/ui"

// 样式（在 layout.tsx 中引入）
import "@innate/ui/globals.css"
```

### Step 2: 使用组件

```tsx
// 基础组件使用
<Card>
  <CardHeader>标题</CardHeader>
  <CardContent>内容</CardContent>
</Card>

// Button 变体
<Button variant="default">主要按钮</Button>
<Button variant="outline">轮廓按钮</Button>
<Button variant="ghost">幽灵按钮</Button>
<Button variant="destructive" size="sm">危险按钮</Button>
```

### Step 3: 使用 Landing 区块

```tsx
import { HeroSection, FeaturesSection, CTASection } from "@innate/ui"

export default function LandingPage() {
  return (
    <main>
      <HeroSection
        badge={{ text: "新版本发布" }}
        title="构建更好的产品"
        titleHighlight="更好"
        subtitle="使用我们的工具快速搭建现代化应用"
        primaryCta={{ text: "开始使用", href: "/start" }}
        secondaryCta={{ text: "了解更多", href: "/docs" }}
      />
      <FeaturesSection
        title="核心特性"
        features={[
          { title: "快速", description: "闪电般的性能", icon: <ZapIcon /> },
          { title: "安全", description: "企业级安全", icon: <ShieldIcon /> },
        ]}
      />
      <CTASection
        title="准备好了吗？"
        description="立即开始你的旅程"
        cta={{ text: "免费注册", href: "/signup" }}
      />
    </main>
  )
}
```

### Step 4: 暗色模式

```tsx
// 在 layout.tsx 中使用 next-themes
import { ThemeProvider } from "next-themes"

export default function RootLayout({ children }) {
  return (
    <ThemeProvider attribute="class" defaultTheme="system">
      {children}
    </ThemeProvider>
  )
}
```

## 组件编写规范

当需要创建新组件时，遵循以下模式：

### 基础组件模式

```tsx
"use client"

import * as React from "react"
import { cn } from "../../lib/utils"

interface MyComponentProps {
  className?: string
  children?: React.ReactNode
}

function MyComponent({ className, children }: MyComponentProps) {
  return (
    <div
      data-slot="my-component"
      className={cn("base-styles-here", className)}
    >
      {children}
    </div>
  )
}

export { MyComponent, type MyComponentProps }
```

### CVA 变体模式

```tsx
import { cva, type VariantProps } from "class-variance-authority"

const myVariants = cva("base-styles", {
  variants: {
    variant: {
      default: "bg-primary text-primary-foreground",
      outline: "border border-input bg-background",
      ghost: "hover:bg-accent",
    },
    size: {
      sm: "h-8 px-3 text-xs",
      default: "h-10 px-4 text-sm",
      lg: "h-12 px-6 text-base",
    },
  },
  defaultVariants: {
    variant: "default",
    size: "default",
  },
})
```

## 主题系统

使用 OKLCH 色彩空间，通过 CSS 变量定义。详细变量清单见 [references/theme-system.md](references/theme-system.md)。

核心语义变量：

| 变量 | 用途 |
|------|------|
| `--background` / `--foreground` | 页面背景和文字 |
| `--primary` / `--primary-foreground` | 主色调 |
| `--secondary` / `--secondary-foreground` | 次色调 |
| `--muted` / `--muted-foreground` | 弱化色调 |
| `--accent` / `--accent-foreground` | 强调色调 |
| `--destructive` / `--destructive-foreground` | 危险/错误色 |
| `--border` / `--input` / `--ring` | 边框、输入框、焦点环 |
| `--chart-1` ~ `--chart-5` | 图表配色 |
| `--radius` | 基础圆角（sm/md/lg/xl 自动派生） |
| `--sidebar-*` | 侧边栏专用色 |

所有颜色在 `:root`（亮色）和 `.dark`（暗色）下都有定义。

## Monorepo 项目结构

```
project/
├── apps/
│   └── web/                        # Next.js Web 应用
│       ├── src/
│       │   ├── app/                # App Router 页面
│       │   │   ├── layout.tsx
│       │   │   ├── page.tsx
│       │   │   └── ...
│       │   └── components/         # 业务组件
│       ├── package.json
│       └── next.config.js
├── packages/
│   ├── ui/                         # @innate/ui 组件库
│   │   └── src/
│   │       ├── components/ui/      # 基础组件
│   │       ├── block/              # 业务区块
│   │       │   ├── landing/        # Landing 页区块
│   │       │   ├── auth/           # 认证区块
│   │       │   ├── mail/           # 邮件区块
│   │       │   └── chat/           # 聊天区块
│   │       ├── lib/utils.ts        # cn() 工具
│   │       ├── globals.css         # Design tokens
│   │       └── index.ts            # 统一导出
│   ├── utils/                      # 工具函数
│   └── tsconfig/                   # TS 配置
├── pnpm-workspace.yaml
└── package.json
```

## Typography 字体规范

使用 `next/font/google` 加载字体（自动优化、自托管）。

**禁用字体**: Inter, Roboto, Poppins, Montserrat, Open Sans, Playfair Display

**推荐 Display 字体**: Sora, Elms Sans, Vend Sans, Zalando Sans
**推荐 Body 字体**: Manrope, Figtree, Source Sans 3, Stack Sans Text
**推荐 Serif**: Bacasime Antique, Gentium Plus, Libertinus Serif
**推荐 Mono**: SUSE Mono, JetBrains Mono

始终配对使用 display font + body font。优先使用可变字体（Variable Fonts）。

## 页面开发模式

### Landing Page 模式

```tsx
// app/page.tsx
import { HeroSection, FeaturesSection, PricingSection, FaqSection, CTASection } from "@innate/ui"

export default function LandingPage() {
  return (
    <main className="flex flex-col">
      <HeroSection {...} />
      <FeaturesSection {...} />
      <PricingSection {...} />
      <FaqSection {...} />
      <CTASection {...} />
    </main>
  )
}
```

### Dashboard 模式

```tsx
import { Sidebar, SidebarProvider, SidebarInset } from "@innate/ui"

export default function DashboardLayout({ children }) {
  return (
    <SidebarProvider>
      <AppSidebar />
      <SidebarInset>
        <main className="p-6">{children}</main>
      </SidebarInset>
    </SidebarProvider>
  )
}
```

### 表单模式

```tsx
import { Form, Field, Input, Button } from "@innate/ui"
import { useForm } from "react-hook-form"
import { z } from "zod"
import { zodResolver } from "@hookform/resolvers/zod"

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
})

function LoginForm() {
  const form = useForm({ resolver: zodResolver(schema) })
  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)}>
        <Field name="email" render={({ field }) => <Input {...field} />} />
        <Field name="password" render={({ field }) => <Input type="password" {...field} />} />
        <Button type="submit">登录</Button>
      </form>
    </Form>
  )
}
```

---

## 项目验证规则

> 来源：frontend-validate Skill 合并。适用于新建项目、样式调试、Code Review 场景。

### V1. CSS / Tailwind 配置检查

**CSS 文件导入**：
- [ ] `main.tsx` 或 `main.js` 是否导入了 CSS 文件（如 `import "./index.css"`）
- [ ] CSS 文件路径是否正确

**Tailwind CSS 配置**（v3）：
- [ ] `tailwind.config.js` 的 `content` 是否包含所有模板文件路径
- [ ] `postcss.config.js` 是否存在
- [ ] CSS 文件是否包含 `@tailwind base/components/utilities` 指令

**Tailwind v4 注意**：
- v4 不使用 `tailwind.config.js`，改为 CSS-based 配置
- 检查 `globals.css` 是否有 `@import "tailwindcss"`
- 无需 `postcss.config.js`

### V2. 构建工具配置检查

**Vite 项目**：
- [ ] `vite.config.ts` 是否存在
- [ ] `index.html` 入口文件是否正确配置

**路径别名**：
- [ ] `tsconfig.json` 中是否配置 `paths`（如 `@/* → ./src/*`）
- [ ] `vite.config.ts` 中是否配置 `resolve.alias` 匹配

### V3. React 项目检查

**入口文件**：
- [ ] `main.tsx` 是否存在且使用 React 18/19 的 `createRoot` API
- [ ] `App.tsx` 是否存在

**TypeScript 配置**：
- [ ] `tsconfig.json` 是否存在
- [ ] `vite-env.d.ts` 是否存在（Vite 项目）

### 常见问题快速修复

| 症状 | 排查方向 |
|------|----------|
| 样式不生效 | 检查 `main.tsx` 是否导入 CSS → 检查 Tailwind 配置版本 → 检查 `@tailwind` / `@import` 指令 |
| 构建失败 | 检查 `tsconfig.json` + `vite.config.ts` 路径别名一致性 |
| 组件找不到 | 检查 `@innate/ui` 是否在 `package.json` 中用 `workspace:*` 引用 |

---

## shadcn/ui 升级策略

> @innate/ui 基于 shadcn/ui（Radix UI 基础），组件代码直接存在于 `packages/ui/src/components/ui/` 中。

### 核心理念：代码拷贝 = 合理复用

shadcn/ui 的设计理念是**"复制而非依赖"**——组件源码直接放在项目中，用户可自由修改。因此：

1. **组件源码在项目中**：`packages/ui/src/components/ui/` 下的组件是完整的源码，不是 npm 依赖
2. **预置而非实时安装**：所有常用组件已预置在 `packages/ui/` 中，新项目无需逐个安装
3. **自动同步**：通过 GitHub Actions 每周自动检查并更新组件

### 自动更新流水线

```
每周一凌晨
    ↓
GitHub Action 运行 npx shadcn@latest diff
    ↓
如果有更新 → 自动批量更新 → 创建 PR
    ↓
人工 Review（5 分钟）→ Merge → 所有项目自动获得最新组件
```

**已配置**：`.github/workflows/update-shadcn-components.yml`
- 每周一凌晨 2 点自动检查更新
- 自动创建 PR，附带更新清单
- 支持手动触发（workflow_dispatch）

### 手动更新

```bash
# 1. 查看当前组件与官方的差异
cd packages/ui
npx shadcn@latest diff

# 2. 升级单个组件（会覆盖该组件文件）
npx shadcn@latest add button --overwrite

# 3. 批量升级所有组件
for f in src/components/ui/*.tsx; do
  name=$(basename "$f" .tsx)
  npx shadcn@latest add "$name" --overwrite --yes || true
done

# 4. 如果有自定义修改，使用 diff 对比
git diff packages/ui/src/components/ui/button.tsx
```

### 同步回 packages/ui/

如果通过 `apps/web/` 更新了组件，需要同步回 `packages/ui/`：

```bash
# 从 apps/web 同步到 packages/ui
rsync -av apps/web/components/ui/ packages/ui/src/components/ui/
rsync -av apps/web/lib/utils.ts packages/ui/src/lib/
rsync -av apps/web/app/globals.css packages/ui/src/
```

### 保持一致性的原则

- **不直接修改 shadcn/ui 基础组件源码**：自定义通过 `className` 覆盖或创建包装组件
- **业务区块组件（block/）自定义**：这些是项目特有的，不受 shadcn/ui 升级影响
- **Design tokens 通过 CSS 变量**：主题定制通过 `globals.css` 的 CSS 变量，不修改组件内部样式
- **Review 清单**：更新后检查 theme 兼容性、import 路径、breaking changes

---

## Next.js 16 新特性

### Turbopack（默认构建工具）
Turbopack 现在是 Next.js 16 的默认构建工具，无需配置：
- 2-5× 更快的生产构建
- 最高 10× 更快的 Fast Refresh

如需回退到 webpack：
```bash
next build --webpack
```

### Cache Components（显式缓存模型）
Next.js 16 引入 `"use cache"` 指令实现显式缓存：

```tsx
'use cache'

export async function ProductList() {
  const products = await fetchProducts()
  return <div>{/* ... */}</div>
}
```

启用配置：
```ts
// next.config.ts
export default {
  experimental: {
    cacheComponents: true
  }
}
```

**与 Next.js 15 的关键区别**：
- 所有动态代码默认在请求时执行（无隐式缓存）
- 缓存完全通过 `"use cache"` 选择加入

### Async APIs（破坏性变更）
所有动态 API 现在都是异步的：

```tsx
// Next.js 16 - 必须使用 async
export default async function Page({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>
}) {
  const { id } = await params
  const { q } = await searchParams
  // ...
}
```

```tsx
// Async cookies, headers, draftMode
import { cookies, headers, draftMode } from 'next/headers'

async function getData() {
  const cookieStore = await cookies()
  const headersList = await headers()
  const { isEnabled } = await draftMode()
}
```

### React Compiler（稳定版）
自动记忆化，无需手动使用 `useMemo`/`useCallback`：

```ts
// next.config.ts
export default {
  reactCompiler: true
}
```

```bash
npm install babel-plugin-react-compiler
```

### proxy.ts（替代 middleware.ts）
将 `middleware.ts` 重命名为 `proxy.ts`，命名更清晰：

```ts
// proxy.ts
import type { ProxyConfig } from 'next'

export const proxy: ProxyConfig = async (request) => {
  // 在 Node.js 运行时执行
}
```

> `middleware.ts` 仍然可用，但在 Edge runtime 场景下已弃用。

### React 19.2 特性
- **View Transitions**: 导航期间动画过渡元素
- **useEffectEvent**: 从 Effects 中提取非响应式逻辑
- **Activity**: 使用状态保留渲染后台活动

## Accessibility 与 Motion

### Accessibility（WCAG 2.1 AA）
- 使用语义化 HTML（button、nav、main、article，而非全部用 div）
- 所有交互元素添加 ARIA label
- 文字对比度达到 4.5:1
- 支持键盘导航
- 提供 skip-to-content 链接

### Motion & Animation
- 使用 Framer Motion 实现滚动揭示和过渡动画
- 视口进入时子元素交错动画（stagger）
- 卡片和按钮的悬停微交互
- 动画必须有目的性——增强体验，而非分散注意力
- 利用 React 19.2 View Transitions 实现导航动画

## 构建 UI 的 7 步流程

当用户要求构建 UI 时，按以下顺序执行：

1. **确定美学方向**（或询问用户偏好）
2. **浏览 21st.dev** 寻找匹配的组件
3. **通过 `npx shadcn@latest add "[url]"` 安装组件**
4. **使用 Tailwind 自定义样式**
5. **应用 Next.js 16 模式**（async APIs、显式缓存）
6. **使用 Framer Motion 和 View Transitions 添加动画**
7. **验证无障碍访问（Accessibility）**

## 注意事项

1. **统一使用 @innate/ui**：所有前端项目使用统一的组件库，不要重复造轮子
2. **优先使用 21st.dev**：写组件前先查 21st.dev，避免手写已有成熟方案
3. **OKLCH 色彩空间**：自定义颜色时使用 `oklch()` 格式，与主题系统一致
4. **data-slot 属性**：组件根元素添加 `data-slot="component-name"` 用于样式定位
5. **cn() 合并类名**：始终使用 `cn()` 而非模板字符串合并 className
6. **"use client"**：所有交互组件必须添加客户端指令
7. **类型导出**：组件 Props 类型使用 `export type { XxxProps }` 导出
8. **Server Components 优先**：Next.js App Router 默认使用 Server Components，只有实际需要（交互、事件监听、浏览器 API）时才加 `'use client'`

## 示范项目

以下开源项目展示了本 Skill 规范的实际应用。实现具体功能时，按「任务 → 项目 → 文件路径」定位参考代码。

| 你要做的 | 参考项目 | 关键文件路径 |
|---------|---------|-------------|
| **初始化 Web 项目** | [innate-next-mono](https://github.com/variableway/innate-next-mono) | `apps/web/` — Next.js 16 Starter 模板 |
| **查看主题/CSS 变量** | [innate-next-mono](https://github.com/variableway/innate-next-mono) | `packages/ui/src/globals.css` — OKLCH 主题系统 |
| **使用业务区块**（Landing/Auth/Chat/Mail） | [innate-next-mono](https://github.com/variableway/innate-next-mono) | `packages/ui/src/block/**/*.tsx` |
| **搭建 Landing Page** | [innate-next-mono](https://github.com/variableway/innate-next-mono) | `apps/web/app/page.tsx` |
| **搭建 Dashboard 布局** | [innate-next-mono](https://github.com/variableway/innate-next-mono) | `apps/web/app/dashboard/page.tsx` |
| **安装基础组件**（Button/Card/Dialog） | shadcn/ui 官方 | `npx shadcn@latest add button card dialog` |
| **安装营销区块**（Hero/Features/CTA） | [21st.dev](https://21st.dev) | `npx shadcn@latest add "https://21st.dev/r/..."` |
| **一键初始化完整环境** | [innate-next-mono](https://github.com/variableway/innate-next-mono) | `./scripts/init-starter.sh` |

> 完整映射表和引用原则见 [references/demo-projects.md](references/demo-projects.md)

## 参考资源

- [组件清单](references/component-catalog.md) — 57+ 组件完整列表
- [主题系统](references/theme-system.md) — OKLCH 色彩变量详解
- [示范项目索引](references/demo-projects.md) — 参考项目关键代码模式提取
- [desktop-app Skill](../desktop-app/SKILL.md) — 桌面应用开发 Skill
