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
| **Trae** | `~/.trae/skills/` (系统级) 或 `.trae/skills/` (项目级) | 通过 `SKILL.md` 自动识别 |
| **Trae Solo** | `~/.trae/skills/` | Trae Solo 模式，与 Trae 使用相同目录 |
| **WorkBuddy** | `~/.workbuddy/skills/` (系统级) 或 `.workbuddy/skills/` (项目级) | 通过 `SKILL.md` 自动识别 |

> 所有 Skill 均以标准 `SKILL.md` 作为入口，并辅以 Python 脚本和参考文档。

## 快速安装

### 按 Tag 安装（推荐 — install-by-tag）

`install-by-tag.sh` / `install-by-tag.ps1` 根据 SKILL.md frontmatter 中的 `tags` 字段批量安装。默认扫描 `dev/`、`analysis/`、`office-skills/` 以及 `references/skills-pool/` 下的所有分类目录：

```bash
# 安装所有带 analysis 标签的 skill（含 repo-analyzer、tech-research 等）
./install-by-tag.sh analysis --system

# 安装所有 dev-workflow 标签 skill 到 Claude Code
./install-by-tag.sh dev-workflow --system --agent claude-code

# 安装 office 类技能（markdown-converter、python-uv-env）
./install-by-tag.sh office --system

# 仅扫描指定目录（可重复传 --dir）
./install-by-tag.sh repo --system --dir ./analysis
./install-by-tag.sh research --system --dir ./dev --dir ./analysis

# Windows
.\install-by-tag.ps1 -Tag analysis -System
```

常用 tag：`dev-workflow` · `github` · `workflow` · `analysis` · `codegraph` · `repo` · `research` · `security` · `ai` · `office` · `python`

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
| **scanning-for-secrets** | 提交前扫描敏感信息 | 9 种 Token 模式检测 + Pre-commit Hook |
| **understand-anything** | 交互式代码知识图谱 | 将代码库转为可搜索、可探索的交互式知识图谱 |

安装：`./install-by-tag.sh dev-workflow --system`

### `analysis/` — 代码分析 Skills

| Skill | 说明 | 核心能力 |
|-------|------|---------|
| **repo-analyzer** | 代码仓库语义分析（基于 [CodeGraph](https://github.com/colbymchenry/codegraph)） | 克隆/扫描仓库 → 生成结构化分析报告，归档到 `~/innate-revisit/analysis/repo/<repo-name>/` |
| **tech-research** | 技术问题解决方案搜索与分析 | Web 搜索、结构化分析报告、技术成熟度评估 |
| **awesome-analyzer** | Awesome List 解析与项目分析 | Awesome List 项目信息提取与结构分析 |

安装（按 tag）：`./install-by-tag.sh analysis --system`

### `office-skills/` — 办公效率 Skills

| Skill | 说明 | 核心能力 |
|-------|------|---------|
| **markdown-converter** | 文档转 Markdown（基于 markitdown） | 支持 PDF/Word/PPT/Excel/HTML/图片/音频/ZIP/YouTube → Markdown |
| **python-uv-env** | Python 项目脚手架（基于 uv） | 一键创建 CLI/FastAPI/Django/Library 项目，自动配置 ruff/mypy/pytest |

安装（按 tag）：`./install-by-tag.sh office --system`

### `references/skills-pool/` — 更多分类 Skills

| 子目录 | 说明 | 包含 Skill |
|--------|------|-----------|
| **fe-skills/** | 前端开发 | innate-frontend（Web 前端，@innate/ui + Next.js 16） |
| **backend-skills/** | 后端开发 | golang-cli-app（Go CLI 应用开发指南） |
| **product/** | 产品设计 | prd-writer-skill、project-analysis-skill |
| **ai-config/** | AI Provider 配置 | 一键配置 GLM/OpenRouter/OpenAI/Anthropic 到编程工具 |

安装（按 tag）：`./install-by-tag.sh <tag> --system --dir ./references/skills-pool/<subdir>`

## 仓库结构

```
fire-skills/
├── README.md                          # 本文件
├── CLAUDE.md                          # Claude Code 项目指令
├── install-by-tag.sh                  # 按 Tag 批量安装脚本（macOS/Linux）
├── install-by-tag.ps1                 # 按 Tag 批量安装脚本（Windows）
├── clean-skills.sh                    # 清理已安装 Skills 的脚本
├── package.json                       # 文档站点构建（docmd）
├── docmd.config.mjs                   # 文档站点配置
├── docs/                              # 详细文档
│   ├── README.md                      #   文档索引
│   ├── index.md                       #   文档首页
│   ├── Agents.md                      #   支持的 AI Agent 工具介绍
│   ├── ai-coding-tools-guide.md       #   AI 编程工具配置指南
│   ├── spec/                          #   协议和规范定义
│   ├── usage/                         #   使用指南
│   └── validation/                    #   验证文档
├── dev/                               # 开发工作流 Skills (6 个)
│   ├── git-workflow/                  #   GitHub Issue 任务工作流
│   ├── local-workflow/                #   本地任务工作流
│   ├── github-cli-skill/              #   GitHub CLI 工具
│   ├── gh-create-release/             #   GitHub Release 创建
│   ├── scanning-for-secrets/          #   安全扫描
│   └── understand-anything/           #   交互式代码知识图谱
├── analysis/                          # 代码分析 Skills (3 个)
│   ├── repo-analyzer/                 #   代码仓库语义分析（CodeGraph 集成）
│   ├── tech-research/                 #   技术调研
│   └── awesome-analyzer/              #   Awesome List 解析
├── office-skills/                     # 办公效率 Skills (2 个)
│   ├── markdown-converter/            #   文档转 Markdown
│   └── python-uv-env/                 #   Python 项目脚手架（uv）
├── references/                        # 参考资料
│   ├── skills-pool/                   #   更多 Skills 池
│   │   ├── fe-skills/                 #     前端开发（innate-frontend）
│   │   ├── backend-skills/            #     后端开发（golang-cli-app）
│   │   ├── product/                   #     产品设计
│   │   ├── ai-config/                 #     AI Provider 配置
│   │   └── ...                        #     更多分类
│   ├── composio/                      #   Composio SDK 参考实现
│   └── mattprocock-skills/            #   社区 Skills 参考
├── python-skills-runtime/             # Python Skills 运行时环境
└── tasks/                             # 任务管理目录
    ├── issues/                        #   任务定义文件
    ├── tracing/                       #   本地执行追踪
    └── analysis/                      #   分析任务
```

## 文档站点

完整文档发布在 GitHub Pages：**<https://variableway.github.io/fire-skills>**

本地预览 / 构建：

```bash
npm run docs:dev    # 本地开发服务器
npm run docs:build  # 构建到 site/
```

文档由 [docmd](https://github.com/docmd-io/docmd) 生成，源文件位于 `docs/`，CI 通过 `.github/workflows/docs.yml` 自动部署。

> **首次启用 Pages**：在 GitHub 仓库 `Settings → Pages → Build and deployment → Source` 选择 **GitHub Actions**，然后推送 main 分支触发工作流。

## 添加新 Skill

1. 在对应分类目录下（`dev/`、`analysis/`、`office-skills/` 或 `references/skills-pool/<subdir>/`）创建新文件夹
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
  - trae
  - trae-solo
  - workbuddy
tags:
  - your-tag
---
```

3. 在 `SKILL.md` 同级目录下按需创建 `scripts/`、`references/` 等子目录
4. 更新本 README 的 Skill 列表
5. 运行 `./install-by-tag.sh <your-tag> --system` 安装

## 设计原则

- **单一入口**：每个 skill 只有一个 `SKILL.md`，降低维护成本
- **Tag 分类**：Skills 按 frontmatter `tags` 字段分类，支持跨目录按主题批量安装
- **无外部强依赖**：优先使用标准库或系统自带工具
- **脚本自解释**：所有 Python 脚本均内置 `--help`
- **配置分层**：支持 CLI > 环境变量 > 项目配置 > 全局配置的优先级链
