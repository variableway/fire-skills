---
name: "import-figma"
description: "从本地 .fig 文件导入设计参考或生成设计系统"
---
# 从 Figma 导入

用 `agents/import-figma.mjs` 离线解码本地 `.fig` 文件。无需 Figma 账号或 MCP。

## 两种用途

- **设计参考**：挂载为项目内可浏览的树，挑选组件代码，渲染 frame 作视觉对照
- **设计系统**：导出每个组件 + 变量到新的 `designs/<slug>/` 文件夹

> **注意**：Figma URL 不在此处理。给链接时让用户导出本地副本（File → Save local copy…）

## 第一步：outline（必须）

```bash
node <skill>/agents/import-figma.mjs outline <file.fig>           # 人类可读摘要
node <skill>/agents/import-figma.mjs outline <file.fig> --json    # 结构化列表
```

## Flow A：设计参考

```bash
# 挂载到项目
node <skill>/agents/import-figma.mjs mount <file.fig> <projectDir>

# Materialize 真实组件代码
node <skill>/agents/import-figma.mjs materialize <file.fig> --out <dir> --components Button,Input

# 渲染 frame 查看
node <skill>/agents/import-figma.mjs render <file.fig> --frame <guid>
```

- `_fig/<slug>/` 是只读参考树，不是交付物
- SVGs/PNGs 是真实提取的资源，可 `cp` 出来
- mount 是可丢弃脚手架，用完删掉

## Flow B：设计系统

```bash
node <skill>/agents/import-figma.mjs design-system <file.fig> <designs/dir>
```

然后按 `design-system.md` 流程编译、校验、预览。
