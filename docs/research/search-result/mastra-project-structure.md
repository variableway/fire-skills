# Mastra Project Structure

> **Source**: https://mastra.ai/docs/getting-started/project-structure
> **Extracted by**: AnySearch
> **Date**: 2026-06-08

---

## 原始内容（Markdown 抽取）

Your new Mastra project, created with the `create mastra` command, comes with a predefined set of files and folders to help you get started.

Mastra is a framework, but it's **unopinionated** about how you organize or colocate your files. The CLI provides a sensible default structure that works well for most projects, but you're free to adapt it to your workflow or team conventions. You could even build your entire project in a single file if you wanted! Whatever structure you choose, keep it consistent to ensure your code stays maintainable and straightforward to navigate.

## Default project structure

A project created with the `create mastra` command looks like this:

```
src/
├── mastra/
│   ├── agents/
│   │   └── weather-agent.ts
│   ├── tools/
│   │   └── weather-tool.ts
│   ├── workflows/
│   │   └── weather-workflow.ts
│   ├── scorers/
│   │   └── weather-scorer.ts
│   └── index.ts
├── .env.example
├── package.json
└── tsconfig.json
```

> **Tip**: Use the predefined files as templates. Duplicate and adapt them to quickly create your own agents, tools, workflows, etc.

### Folders

Folders organize your agent's resources, like agents, tools, and workflows.

| Folder | Description |
|---|---|
| `src/mastra` | Entry point for all Mastra-related code and configuration. |
| `src/mastra/agents` | Define and configure your agents - their behavior, goals, and tools. |
| `src/mastra/workflows` | Define multi-step workflows that orchestrate agents and tools together. |
| `src/mastra/tools` | Create reusable tools that your agents can call |
| `src/mastra/mcp` | (Optional) Implement custom MCP servers to share your tools with external agents |
| `src/mastra/scorers` | (Optional) Define scorers for evaluating agent performance over time |
| `src/mastra/public` | (Optional) Contents are copied into the `.build/output` directory during the build process, making them available for serving at runtime |

### Top-level files

Top-level files define how your Mastra project is configured, built, and connected to its environment.

| File | Description |
|---|---|
| `src/mastra/index.ts` | Central entry point where you configure and initialize Mastra. |
| `.env.example` | Template for environment variables - copy and rename to `.env` to add your secret model provider keys. |
| `package.json` | Defines project metadata, dependencies, and available npm scripts. |
| `tsconfig.json` | Configures TypeScript options such as path aliases, compiler settings, and build output. |

## Next steps

- Read more about [Mastra's features](https://mastra.ai/docs#what-you-can-build).
- Integrate Mastra with your frontend framework: [Next.js](https://mastra.ai/guides/getting-started/next-js), [React](https://mastra.ai/guides/getting-started/vite-react), or [Astro](https://mastra.ai/guides/getting-started/astro).
- Build an agent from scratch following one of the [guides](https://mastra.ai/guides).
- Watch conceptual guides on the [YouTube channel](https://www.youtube.com/@mastra-ai).

---

## 核心观点总结

### 1. 框架无强制意见（Unopinionated）
Mastra 本身**不强制**任何文件组织方式。CLI 生成的默认结构只是"合理的默认值"，你可以根据团队习惯自由调整，甚至把整个项目写进一个文件。关键是**保持一致性**，确保代码可维护、易导航。

### 2. 默认目录结构（`create mastra` 生成）

| 目录/文件 | 用途 |
|---|---|
| `src/mastra/` | Mastra 代码与配置的入口点 |
| `src/mastra/agents/` | 定义 Agent（行为、目标、工具配置） |
| `src/mastra/workflows/` | 定义多步骤工作流，编排 Agent 与工具 |
| `src/mastra/tools/` | 创建可复用工具，供 Agent 调用 |
| `src/mastra/mcp/` | （可选）自定义 MCP 服务器，向外部 Agent 暴露工具 |
| `src/mastra/scorers/` | （可选）评估 Agent 长期表现的评分器 |
| `src/mastra/public/` | （可选）构建时复制到输出目录，供运行时静态文件服务 |
| `src/mastra/index.ts` | 中央入口，负责 Mastra 的配置与初始化 |
| `.env.example` | 环境变量模板（API Key 等） |
| `package.json` / `tsconfig.json` | 标准 Node.js / TypeScript 配置 |

### 3. 快速上手的建议
预置文件可直接当作**模板**使用：复制并修改它们，就能快速创建自己的 Agent、Tool、Workflow 等。

### 4. 后续方向
文档推荐阅读 Mastra 功能概览、与前端框架（Next.js / React / Astro）集成，或跟随官方指南从零构建 Agent。
