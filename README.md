# fire-skills / skill-spark

Personal Skill Workspace + universal Skill manager for AI coding agents.

- 仓库主页：<https://github.com/variableway/fire-skills>
- 通用技能管理 CLI：`skill-spark`（本仓库构建产物）

**Use this repo to:**

1. Keep curated personal / team skills（按分类组织）
2. Test and iterate on skills
3. Install and sync skills across agents via **skill-spark** CLI

## Quick start

```bash
pnpm install
bun run build          # 或: bun run build:install
./dist/index.js --help
```

安装 DevOps 技能到 WorkBuddy（从 devops-skill 仓库）：

```bash
./dist/index.js add qdriven/devops-skill --agent workbuddy -g -f
```

## Skills

每个 skill 的来源 URL 见下表。`in-tree` 表示该 skill 就在本仓库内维护；
其余 skill 通过 git subtree 来自 `variableway/<repo>` 独立仓库。

### Core（`skills/base`）

| Skill | 路径 | 来源 |
|-------|------|------|
| anysearch | `skills/base/anysearch` | [variableway/skill-anysearch](https://github.com/variableway/skill-anysearch) |
| skill-spark | `skills/base/skill-spark` | in-tree（[本仓库](https://github.com/variableway/fire-skills)） |

### Meta（`skills/meta`）

| Skill | 路径 | 来源 |
|-------|------|------|
| skill-creator | `skills/meta/skill-creator` | [variableway/skill-creator](https://github.com/variableway/skill-creator) |

### Content & Figures & Knowledge

| Skill | 路径 | 来源 |
|-------|------|------|
| design | `skills/content/design` | [variableway/skill-design](https://github.com/variableway/skill-design) |
| thought-distiller | `skills/figures/thought-distiller` | [variableway/skill-thought-distiller](https://github.com/variableway/skill-thought-distiller) |
| thought-distiller | `skills/knowledge/thought-distiller` | [variableway/skill-thought-distiller](https://github.com/variableway/skill-thought-distiller) |

### SDLC · Frontend（`skills/sdlc-first-party`）

均为 in-tree 维护（[本仓库](https://github.com/variableway/fire-skills)）。

| Skill | 路径 |
|-------|------|
| frontend-dev | `skills/sdlc-first-party/frontend/fe-foundation` |
| frontend-code-structure | `skills/sdlc-first-party/frontend/fe-code-structure` |
| frontend-build | `skills/sdlc-first-party/frontend-build` |
| frontend-redesign | `skills/sdlc-first-party/frontend-redesign` |
| frontend-shared | `skills/sdlc-first-party/frontend-shared` |
| frontend-studio | `skills/sdlc-first-party/frontend-studio` |

### DevOps（外部仓库）

DevOps skills 不在本仓库内，统一来自独立仓库：

- 来源：<https://github.com/qdriven/devops-skill>

| Skill | 说明 |
|-------|------|
| github-cli | GitHub CLI 操作助手 |
| gh-create-release | 创建 GitHub Release |
| git-workflow | 基于 GitHub Issue 的工作流 |
| git-worktree | git worktree 隔离开发 |
| git-pr | Pull Request 工作流 |
| local-workflow | 本地离线任务工作流 |
| docmd | Diátaxis 文档站点脚手架 |
| scanning-for-secrets | 提交前密钥扫描 |

安装 DevOps 技能：

```bash
# 安装到 WorkBuddy
./dist/index.js add qdriven/devops-skill --agent workbuddy -g -f
# 安装到 codex（全局）
./dist/index.js add qdriven/devops-skill --agent codex -g -f
```

## 支持的 Agent 目标

skill-spark 可安装到下列 agent 的技能目录（部分）：

| Agent | 全局目录 | 项目目录 |
|-------|---------|---------|
| WorkBuddy | `~/.workbuddy/skills` | `.workbuddy/skills` |
| Claude Code | `~/.claude/skills` | `.claude/skills` |
| Codex | `~/.codex/skills` | `.agents/skills` |
| Cursor | `~/.cursor/skills` | `.agents/skills` |
| Trae | `~/.trae/skills` | `.trae/skills` |

运行 `./dist/index.js agent list` 查看全部内置 agent。

## Docs

| Doc | What |
|-----|------|
| [docs/README.md](docs/README.md) | 文档索引 |
| [docs/skill-spark/overview.md](docs/skill-spark/overview.md) | 架构与模块 |
| [docs/skill-spark/install-and-run.md](docs/skill-spark/install-and-run.md) | 构建、安装、运行 CLI |
| [docs/usage/install-devops-skills.md](docs/usage/install-devops-skills.md) | DevOps skills 安装指南 |
| [docs/install-skills.md](docs/install-skills.md) | 通用 add / remove / update |
| [docs/projects/architecture-and-mvp.md](docs/projects/architecture-and-mvp.md) | 文档布局、状态、MVP 计划 |

## 相关仓库

| 仓库 | 说明 |
|------|------|
| [variableway/fire-skills](https://github.com/variableway/fire-skills) | 本仓库：skill-spark CLI + 个人 skill 工作区 |
| [qdriven/devops-skill](https://github.com/qdriven/devops-skill) | DevOps skill 合集（git-workflow / local-workflow / github-cli 等 8 个） |
| [variableway/skill-anysearch](https://github.com/variableway/skill-anysearch) | anysearch 实时搜索 skill |
| [variableway/skill-creator](https://github.com/variableway/skill-creator) | skill-creator 元技能 |
| [variableway/skill-thought-distiller](https://github.com/variableway/skill-thought-distiller) | thought-distiller 名人思想蒸馏器 |
| [variableway/skill-design](https://github.com/variableway/skill-design) | design skill |

技能注册表快照见 `skills/categories.json` 与 `skills/index.json`。
