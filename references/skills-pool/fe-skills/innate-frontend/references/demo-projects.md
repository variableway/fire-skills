# Innate Frontend 示范项目索引

> 本文件索引与 `innate-frontend` Skill 相关的参考项目。
> 实现具体功能时，按下方「任务-项目映射表」定位到对应仓库的代码文件。

---

## 任务-项目映射表

| 你要做的 | 参考项目 | 关键文件路径 |
|---------|---------|-------------|
| **实现新组件**（Button/Dialog/Card 等） | [innate-next-mono](https://github.com/variableway/innate-next-mono) | `packages/ui/src/components/ui/*.tsx` |
| **实现 Landing 区块**（Hero/Features/Pricing） | [innate-next-mono](https://github.com/variableway/innate-next-mono) | `packages/ui/src/block/landing/*.tsx` |
| **搭建完整 Landing Page** | [innate-websites](https://github.com/variableway/innate-websites) | `apps/web/app/page.tsx` |
| **搭建 Dashboard 布局**（Sidebar + Main） | [innate-websites](https://github.com/variableway/innate-websites) | `apps/web/app/making/layout.tsx` |
| **数据列表页**（Table + Filter） | [innate-websites](https://github.com/variableway/innate-websites) | `apps/web/app/making/issues/page.tsx` |
| **查看主题系统实现** | [innate-next-mono](https://github.com/variableway/innate-next-mono) | `packages/ui/src/globals.css` |
| **查看 Monorepo 结构** | [innate-next-mono](https://github.com/variableway/innate-next-mono) | 根目录 `pnpm-workspace.yaml` + `package.json` |
| **找现成组件替代手写** | [21st.dev](https://21st.dev) | https://21st.dev/community/components |
| **学习组件设计规范** | [21st.dev](https://github.com/serafimcloud/21st) | `apps/web/app/publish/page.tsx` + 组件目录结构 |

---

## 项目简介

### innate-next-mono
@innate/ui 组件库的源项目。生产级 monorepo，包含 50+ 组件和 Landing 区块的完整实现。

### innate-websites
基于 @innate/ui 构建的完整网站。展示"如何用已有组件拼出页面"。

### 21st.dev
社区组件注册表。当需要新组件时，先在此搜索是否有现成方案，用 `npx shadcn@latest add "[url]"` 安装。

---

## 引用原则

1. **不复制整个仓库代码到 Skill** — Skill 只存路径映射和关键模式说明
2. **Agent 在线时** — 直接读取 GitHub 仓库对应文件作为上下文
3. **Agent 离线时** — 依赖 SKILL.md 中已有的代码片段 + 本索引的路径指引
4. **版本标注** — 引用具体文件时标注仓库的 commit hash 或 tag，避免升级后路径失效
