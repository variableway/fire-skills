# Fire Skills

个人习惯的 AI Agent Skill 仓库，统一收集、管理和分发适配多种 AI 编程助手的 Skills。

## 支持的 AI Agent

本仓库中的 Skill 力求兼容以下 Agent 工具：

| Agent | 配置文件位置 | 说明 |
|-------|-------------|------|
| **Claude Code** | `~/.claude/skills/` | 通过 `SKILL.md` 自动识别 |
| **Kimi CLI** | `~/.kimi/skills/` 或 Kimi 内置 skills | 通过 `SKILL.md` 自动识别 |
| **Codex** | `~/.codex/skills/` (或项目目录) | 通过 `SKILL.md` 自动识别 |
| **OpenCode** | `~/.opencode/skills/` (或项目目录) | 通过 `SKILL.md` 自动识别 |

> 所有 Skill 均以标准 `SKILL.md` 作为入口，并辅以 Python 脚本和参考文档。

## 快速安装

### Linux/macOS 安装 (install.sh)

统一支持**系统级别**和**项目级别**安装，支持按文件夹选择安装：

```bash
# 查看可用 skills
./install.sh --list

# 查看可用 skill 文件夹
./install.sh --list-folders

# ========== 系统级别安装 ==========
# 安装所有 skills 到系统目录（所有 Agent）
./install.sh --system --all

# 安装所有 skills 到特定 Agent（如 Kimi）
./install.sh --system --agent kimi --all

# 从特定文件夹安装（如 dev）
./install.sh --system --folder dev --all

# 安装指定 skills 到系统
./install.sh --system github-task-workflow local-workflow

# ========== 项目级别安装 ==========
# 安装所有 skills 到当前项目
./install.sh --project --all

# 从特定文件夹安装到当前项目
./install.sh --project --folder dev --all

# 安装指定 skills 到当前项目
./install.sh --project github-task-workflow
```

**系统级别安装位置**：
- `~/.config/agents/skills/` (通用)
- `~/.claude/skills/` (Claude Code)
- `~/.kimi/skills/` (Kimi CLI)
- `~/.codex/skills/` (Codex)
- `~/.opencode/skills/` (OpenCode)

**项目级别安装位置**：
- `./.agents/skills/` (通用)
- `./.kimi/skills/` (Kimi CLI)
- `./.claude/skills/` (Claude Code)
- 自动创建 `.kimi/KIMI.md` 项目配置
- 自动创建 `tasks/` 目录

### 清理已安装的 Skills

```bash
# 列出所有已安装的 skills
./clean-skills.sh --list

# 模拟清理（不实际删除）
./clean-skills.sh --dry-run

# 清理指定 Agent 的 skills
./clean-skills.sh --agent kimi

# 清理所有 Agent 的 skills
./clean-skills.sh --all
```

### 手动链接

```bash
ln -s $(pwd)/dev/git-workflow ~/.claude/skills/git-workflow
```

## 已包含 Skills

### `dev/` — 开发工作流 Skills

| Skill | 说明 | 核心能力 |
|-------|------|---------|
| **git-workflow** | 通过 GitHub Issues 管理任务全生命周期 | 创建/更新 Issue、跨 Agent 编排器、自动仓库检测、多级配置、Git Hooks、本地 tracing |
| **local-workflow** | 纯本地任务追踪，无需 GitHub | 本地 tracing、AI Agent Protocol 输出捕获、编排器 |
| **github-cli-skill** | GitHub CLI (`gh`) 快速参考 | 仓库管理、Issue CRUD、Python 集成示例 |
| **gh-create-release** | GitHub Release 创建工具 | 一键创建 Release + 上传 Assets |
| **ai-config** | 一键配置 AI Provider 到编程工具 | GLM/OpenRouter/OpenAI/Anthropic 模板，支持 Claude Code/Codex/OpenCode/Cline/OpenClaw |
| **spark-task-init-skill** | 初始化 spark-cli 任务目录结构 | 创建 tasks/features/ 等标准目录 |
| **scanning-for-secrets** | 提交前扫描敏感信息 | 9 种 Token 模式检测 + Pre-commit Hook |
| **tech-research** | 技术问题解决方案搜索与分析 | Web 搜索、结构化分析报告、技术成熟度评估 |
| **awesome-analyzer** | 代码/项目分析工具 | 项目结构分析 |

安装：`./install.sh --system --folder dev --all`

### `fe-skills/` — 前端开发 Skills

| Skill | 说明 | 核心能力 |
|-------|------|---------|
| **innate-frontend** | Web 前端开发，基于 `@innate/ui` 组件库 | 57+ UI 组件、7 个 Landing 区块、Auth/Mail/Chat 业务区块、OKLCH 主题系统 |
| **desktop-app** | Tauri 2 + Next.js 跨平台桌面/Web 应用 | 完整 monorepo 模板、侧边栏布局、Tauri IPC 通信、可选 PTY 终端 |

安装：`./install.sh --system --folder fe-skills --all`

### `backend-skills/` — 后端开发 Skills

| Skill | 说明 |
|-------|------|
| **golang-cli-app** | Go CLI 应用开发指南 |

安装：`./install.sh --system --folder backend-skills --all`

### `product/` — 产品设计 Skills

| Skill | 说明 |
|-------|------|
| **prd-writer-skill** | PRD 撰写 |
| **project-analysis-skill** | 项目分析设计 |

安装：`./install.sh --system --folder product --all`

## 仓库结构

```
fire-skills/
├── README.md                          # 本文件
├── install.sh                         # 统一安装脚本（支持 --folder/--system/--project）
├── clean-skills.sh                    # 清理已安装 Skills 的脚本
├── docs/                              # 详细文档
│   ├── README.md                      # 文档索引
│   ├── Agents.md                      # 支持的 AI Agent 工具介绍
│   ├── ai-coding-tools-guide.md       # AI 编程工具配置指南
│   ├── spec/                          # 协议和规范定义
│   └── usage/                         # 使用指南
├── dev/                               # 开发工作流 Skills (10 个)
│   ├── git-workflow/                  #   GitHub Issue 任务工作流
│   ├── local-workflow/                #   本地任务工作流
│   ├── github-cli-skill/              #   GitHub CLI 工具
│   ├── gh-create-release/             #   GitHub Release 创建
│   ├── ai-config/                     #   AI Provider 一键配置
│   ├── spark-task-init-skill/         #   任务目录初始化
│   ├── scanning-for-secrets/          #   安全扫描
│   ├── tech-research/                 #   技术调研
│   └── awesome-analyzer/              #   项目分析
├── fe-skills/                         # 前端开发 Skills (2 个)
│   ├── innate-frontend/               #   Web 前端开发（@innate/ui）
│   └── desktop-app/                   #   桌面应用开发（Tauri + Next.js）
├── backend-skills/                    # 后端开发 Skills (1 个)
│   └── golang-cli-app/                #   Go CLI 应用开发
├── product/                           # 产品设计 Skills (2 个)
│   ├── prd-writer-skill/              #   PRD 撰写
│   └── project-analysis-skill/        #   项目分析设计
├── references/                        # 参考资料
│   ├── composio/                      #   Composio SDK 参考实现
│   ├── mattprocock-skills/            #   社区 Skills 参考
│   └── skills-pool/                   #   Superpowers 等 Skills 池
└── tasks/                             # 任务管理目录
    ├── issues/                        #   任务定义文件
    ├── features/                      #   功能特性任务
    └── analysis/                      #   分析任务
```

## 添加新 Skill

1. 在对应分类目录下（`dev/`、`fe-skills/`、`backend-skills/`、`product/`）创建新文件夹
2. 编写 `SKILL.md`，包含标准的 YAML frontmatter：

```yaml
---
name: your-skill-name
description: 一句话描述该 skill 的用途和触发场景
supported_agents:
  - claude-code
  - kimi
  - codex
  - opencode
---
```

3. 在 `SKILL.md` 同级目录下按需创建 `scripts/`、`references/` 等子目录
4. 更新本 README 的 Skill 列表
5. 运行 `./install.sh --system --folder <folder> --all` 安装

## 设计原则

- **单一入口**：每个 skill 只有一个 `SKILL.md`，降低维护成本
- **分类组织**：Skills 按功能分目录（dev/fe-skills/backend-skills/product），支持 `--folder` 选择安装
- **无外部强依赖**：优先使用标准库或系统自带工具
- **脚本自解释**：所有 Python 脚本均内置 `--help`
- **配置分层**：支持 CLI > 环境变量 > 项目配置 > 全局配置的优先级链
