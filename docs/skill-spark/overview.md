# skill-spark 概述与架构

> 本文档描述 skill-spark 的核心功能、整体架构、模块组成及各模块职责。

---

## 1. 项目概述

**skill-spark** 是一个通用的 Skill 管理工具，专为 AI 编码 Agent 设计。它支持在多种 AI 编程助手（如 Claude Code、Codex、Cursor、Kimi CLI 等）之间统一安装、同步和管理 Skill 文件。

项目采用 Monorepo 架构，基于 pnpm workspace 管理，核心使用 TypeScript 和 Bun 运行时构建。

---

## 2. 主要功能

skill-spark 提供以下核心能力：

### 2.1 Skill 搜索与发现
- 从 Registry 或本地目录搜索可用 Skill
- 支持交互式 TUI 浏览模式
- 按类别、排序规则过滤结果
- 多源搜索（registry、directory、local）

### 2.2 Skill 安装与管理
- 从多种来源安装 Skill：Git 仓库、本地目录、Well-Known 源、Registry
- 支持项目级（project）和全局（global）两种安装作用域
- 支持符号链接（symlink）和直接复制两种安装模式
- 自动将 Skill 映射到目标 AI Agent 的技能目录
- 支持 Profile 批量安装（预定义 Skill 组合一键安装）

### 2.3 Skill 验证与检查
- **验证（validate）**：检查 SKILL.md 结构、元数据、文件引用和基本安全性
- **检查（inspect）**：基于规则的风险与质量评估，识别潜在危险操作（如 `rm -rf`、`curl | bash` 等）
- 输出质量评分和可移植性评分

### 2.4 Skill 更新与维护
- 检查已安装 Skill 的更新状态（outdated）
- 更新 Skill 到最新版本
- 移除不再需要的 Skill
- 通过 `skills.lock` 文件追踪安装状态

### 2.5 多 Agent 支持
- 内置支持 40+ 种 AI 编码 Agent
- 自动检测已安装的 Agent
- 支持自定义 Agent 配置
- 统一管理不同 Agent 的 Skill 目录映射

### 2.6 环境诊断
- `doctor` 命令诊断 skill-spark 运行环境
- 检查 Agent 安装状态、目录权限和配置完整性

---

## 3. 系统架构

skill-spark 采用**分层架构**，从下到上分为：

```
┌─────────────────────────────────────────────────────────┐
│                    CLI 层 (skill-cli)                     │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────┐  │
│  │ search  │ │  add    │ │validate │ │   doctor    │  │
│  │  find   │ │ update  │ │inspect │ │   agent     │  │
│  │  list   │ │remove   │ │  use    │ │   profile   │  │
│  │ outdated│ │  map    │ │  sync   │ │             │  │
│  └─────────┘ └─────────┘ └─────────┘ └─────────────┘  │
├─────────────────────────────────────────────────────────┤
│                    核心层 (skill-core)                    │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────┐  │
│  │ agents  │ │discovery│ │ sources │ │ installations│  │
│  │ registry│ │ mapping │ │  state  │ │   output    │  │
│  │validation│ │inspect  │ │  fs     │ │ skill-parser│  │
│  │ schemas │ │  types  │ │tracked  │ │skill-targets│  │
│  └─────────┘ └─────────┘ └─────────┘ └─────────────┘  │
├─────────────────────────────────────────────────────────┤
│                   模式层 (skill-schemas)                  │
│           Zod 数据验证模式与类型定义                       │
└─────────────────────────────────────────────────────────┘
```

### 3.1 架构分层说明

| 层级 | 职责 | 包名 |
|------|------|------|
| **CLI 层** | 提供用户交互命令和终端输出 | `skill-cli` |
| **核心层** | 实现 Skill 发现、安装、验证、映射等核心逻辑 | `skill-core` |
| **模式层** | 定义 Zod 验证模式、类型接口和共享数据结构 | `skill-schemas` |

---

## 4. 模块组成与功能

### 4.1 `skill-cli`（命令行接口层）

`packages/skill-cli` 是用户直接交互的入口，基于 [Commander.js](https://github.com/tj/commander.js) 构建 CLI，使用 [@clack/prompts](https://github.com/natemoo-re/clack) 提供交互式 TUI 体验。

#### 4.1.1 命令模块

| 命令 | 文件 | 功能说明 |
|------|------|----------|
| `search` / `find` | `commands/search.ts` | 从 Registry 或本地源搜索 Skill，支持交互式浏览 |
| `add` / `install` | `commands/add.ts` | 从源安装 Skill，支持选择目标 Agent、作用域和安装模式 |
| `update` | `commands/update.ts` | 更新已安装 Skill 到最新版本 |
| `outdated` / `status` | `commands/update.ts` | 检查 Skill 更新状态和缺失文件 |
| `remove` / `uninstall` | `commands/remove.ts` | 移除已安装的 Skill |
| `list` | `commands/list.ts` | 列出已安装的 Skill 和 Command |
| `validate` | `commands/validate.ts` | 验证 Skill 目录结构和元数据 |
| `inspect` | `commands/inspect.ts` | 基于规则的风险检查与质量评估 |
| `use` | `commands/use.ts` | 生成任务数据包而不实际安装 Skill |
| `profile` | `commands/profile.ts` | 管理 Skill Profile（预定义组合） |
| `map` | `commands/map.ts` | 将已安装 Skill 映射到目标 Agent 目录 |
| `sync` | `commands/map.ts` | 同步源目录到目标 Agent Skill 文件夹 |
| `agent` | `commands/agent.ts` | 管理 Agent 目录配置（列出、添加、移除） |
| `doctor` | `commands/doctor.ts` | 诊断环境健康和配置状态 |

#### 4.1.2 工具模块

| 模块 | 文件 | 功能说明 |
|------|------|----------|
| `json` | `utils/json.ts` | JSON 文件读写工具 |
| `root` | `utils/root.ts` | 项目根目录检测工具 |

---

### 4.2 `skill-core`（核心逻辑层）

`packages/skill-core` 包含所有核心业务能力，是 skill-spark 的引擎层。

| 模块 | 文件 | 功能说明 |
|------|------|----------|
| **agents** | `src/agents.ts` | 管理 40+ 内置 AI Agent 的配置（目录路径、别名、检测逻辑），支持自定义 Agent 配置 |
| **discovery** | `src/discovery.ts` | 遍历目录发现可安装项（Skill / Command），解析 `SKILL.md` 元数据 |
| **sources** | `src/sources.ts` | 处理多源下载：Git 克隆、Well-Known 索引、本地目录、目录服务（flins directory） |
| **installations** | `src/installations.ts` | 执行 Skill / Command 的安装逻辑，支持 symlink 和 copy 两种模式，管理存储根目录 |
| **mapping** | `src/mapping.ts` | 将已安装的 Skill 符号链接或复制到目标 Agent 的技能目录（如 `.codex/skills`） |
| **registry** | `src/registry.ts` | 与 Registry 服务通信，搜索和获取 Skill 元数据 |
| **validation** | `src/validation.ts` | 验证 Skill 目录结构：检查 `SKILL.md` 存在性、前置数据、引用完整性、文件安全 |
| **inspection** | `src/inspection.ts` | 基于正则规则扫描 Skill 中的风险信号（如 `rm -rf`、`curl \| bash` 等），输出质量评分和可移植性评分 |
| **state** | `src/state.ts` | 管理 `skills.lock` 锁文件，追踪已安装 Skill 的来源、版本、作用域 |
| **output** | `src/output.ts` | 终端输出工具：横幅、进度提示、复数格式化、错误处理 |
| **fs** | `src/fs.ts` | 文件系统工具：目录确保、路径安全检查 |
| **skill-parser** | `src/skill-parser.ts` | 解析 `SKILL.md` 文件，提取 YAML 前置数据和 Markdown 正文 |
| **skill-targets** | `src/skill-targets.ts` | 解析 Skill 中的目标环境声明 |
| **tracked** | `src/tracked.ts` | 追踪安装历史记录（已合并到 state 模块） |
| **types** | `src/types.ts` | 核心类型定义：Skill 列表项、注册表响应、映射记录、锁文件结构等 |

---

### 4.3 `skill-schemas`（数据模式层）

`packages/skill-schemas` 提供全项目共享的 Zod 验证模式和 TypeScript 类型，确保数据一致性。

| 模式 | 功能说明 |
|------|----------|
| `SkillNameSchema` | Skill 名称格式验证（kebab-case，1-64 字符） |
| `SkillFrontmatterSchema` | SKILL.md 前置数据验证 |
| `SourceRefSchema` | 来源引用格式验证（local / git / well-known / directory / registry） |
| `ValidationIssueSchema` | 验证问题（error / warning / info）结构 |
| `ValidationReportSchema` | 验证报告整体结构 |
| `RiskSignalSchema` | 风险信号（low / medium / high / critical）结构 |
| `InspectionReportSchema` | 检查报告结构（含质量评分、可移植性评分、风险信号） |
| `SkillProfileSchema` | Skill Profile（批量安装配置）验证 |
| `SkillRunSessionSchema` | Skill 运行会话状态验证 |

---

## 5. 关键数据流

### 5.1 Skill 安装流程

```
用户输入 source
    ↓
[sources] 解析并下载源（Git / Well-Known / Local）
    ↓
[discovery] 扫描源目录，发现可安装项（Skill + Command）
    ↓
[CLI] 用户交互选择要安装的项和目标 Agent
    ↓
[installations] 复制或符号链接文件到存储目录
    ↓
[mapping] 将 Skill 映射到目标 Agent 目录
    ↓
[state] 写入 skills.lock 记录安装状态
```

### 5.2 Skill 验证流程

```
输入 Skill 目录路径
    ↓
[skill-parser] 解析 SKILL.md 提取前置数据和正文
    ↓
[validation] 检查前置数据完整性、引用有效性、文件安全
    ↓
[inspection] 扫描风险信号、计算质量评分和可移植性评分
    ↓
输出验证报告 + 检查报告
```

---

## 6. 支持的 AI Agent

skill-spark 内置支持以下 Agent（部分列表）：

| Agent | 项目级目录 | 全局目录 | 支持 Commands |
|-------|-----------|---------|--------------|
| Claude Code | `.claude/skills` | `~/.claude/skills` | ✅ |
| Codex | `.agents/skills` | `~/.codex/skills` | ❌ |
| Cursor | `.agents/skills` | `~/.cursor/skills` | ❌ |
| Gemini CLI | `.agents/skills` | `~/.gemini/skills` | ❌ |
| Kimi CLI | `.agents/skills` | `~/.config/agents/skills` | ❌ |
| OpenCode | `.agents/skills` | `~/.config/opencode/skills` | ✅ |
| Trae | `.trae/skills` | `~/.trae/skills` | ❌ |
| Windsurf | `.agents/skills` | `~/.codeium/windsurf/skills` | ❌ |
| Cline | `.agents/skills` | `~/.agents/skills` | ❌ |
| Continue | `.continue/skills` | `~/.continue/skills` | ❌ |
| Goose | `.agents/skills` | `~/.config/goose/skills` | ❌ |
| 更多... | - | - | - |

完整列表可通过 `skill-spark agent list` 查看。

---

## 7. 项目目录结构

```
skill-spark/
├── packages/
│   ├── skill-cli/          # CLI 命令层
│   ├── skill-core/         # 核心逻辑层
│   └── skill-schemas/      # 数据模式层
├── skills/                 # 示例 Skill 仓库
│   ├── base/               # 基础 Skill
│   ├── devops/             # DevOps 相关 Skill
│   ├── meta/               # 元 Skill
│   ├── sdlc/               # 软件开发生命周期 Skill
│   └── skill-shared/       # 共享 Skill
├── src/
│   └── index.ts            # 入口文件（指向 skill-cli）
├── docs/                   # 文档目录
├── package.json            # 根包配置（pnpm workspace）
├── pnpm-workspace.yaml     # pnpm 工作区配置
└── tsconfig.json           # TypeScript 配置
```

---

## 8. 技术栈

| 技术 | 用途 |
|------|------|
| TypeScript | 主要开发语言 |
| Bun | 运行时与构建工具 |
| pnpm | 包管理器（Monorepo workspace） |
| Commander.js | CLI 命令框架 |
| Zod | 运行时数据验证 |
| @clack/prompts | 交互式终端 UI |
| picocolors | 终端颜色输出 |
| tar-stream / yauzl | 压缩包解压（tar.gz / zip） |
| Biome | 代码格式化与检查 |

---

> 本文档与 [安装与运行指南](./install-and-run.md) 配合使用，可全面了解 skill-spark 的使用方法。
