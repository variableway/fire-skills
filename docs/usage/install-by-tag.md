# 按 Tag 批量安装 Skills

`install-by-tag.sh` / `install-by-tag.ps1` 根据 SKILL.md frontmatter 中的 `tags` 字段批量安装 skill。**默认扫描所有分类目录**（`dev/`、`analysis/`、`fe-skills/`、`backend-skills/`、`product/`），匹配到的 skill 会被符号链接到目标 Agent 的 skills 目录。

## 默认扫描目录

```
./dev/                  # 开发工作流
./analysis/             # 代码分析（含 repo-analyzer + CodeGraph）
./fe-skills/            # 前端
./backend-skills/       # 后端
./product/              # 产品设计
```

任一目录不存在会被跳过，不报错。

## 用法

### Linux / macOS

```bash
# 安装所有带 analysis 标签的 skill（含 repo-analyzer）
./install-by-tag.sh analysis --system

# 安装到指定 Agent
./install-by-tag.sh dev-workflow --system --agent claude-code
./install-by-tag.sh workflow --system --agent kimi

# 项目级别安装
./install-by-tag.sh github --project

# 仅扫描指定目录（可重复传 --dir）
./install-by-tag.sh repo --system --dir ./analysis
./install-by-tag.sh research --system --dir ./dev --dir ./analysis
```

### Windows (PowerShell)

```powershell
.\install-by-tag.ps1 -Tag analysis -System
.\install-by-tag.ps1 -Tag dev-workflow -System -Agent claude-code

# 多目录（数组）
.\install-by-tag.ps1 -Tag repo -System -Dir ".\analysis", ".\dev"
```

## 参数

| Bash | PowerShell | 说明 | 默认 |
|------|-----------|------|------|
| `<tag>` | `-Tag <name>` | 要匹配的 frontmatter tag | 必填 |
| `--system` | `-System` | 安装到系统目录（`~/.claude/skills/` 等） | — |
| `--project` | `-Project` | 安装到当前项目（`./.claude/skills/` 等） | — |
| `--agent <name>` | `-Agent <name>` | 仅安装到指定 Agent（claude-code/kimi/codex/opencode/trae/trae-solo/workbuddy） | 全部 |
| `--dir <path>` | `-Dir <paths>` | 自定义扫描目录（可重复） | 五个默认分类目录 |

## 常用 Tag

| Tag | 含义 | 命中 Skill 示例 |
|-----|------|-----------------|
| `dev-workflow` | 开发工作流 | git-workflow, local-workflow, github-cli-skill, ... |
| `github` | GitHub 相关 | github-cli-skill, gh-create-release |
| `workflow` | 任务自动化 | git-workflow, local-workflow |
| `analysis` | 代码 / 项目分析 | repo-analyzer |
| `codegraph` | CodeGraph 集成 | repo-analyzer |
| `repo` | 仓库级分析 | repo-analyzer |
| `research` | 调研类 | tech-research |
| `security` | 安全 | scanning-for-secrets |
| `ai` | AI 配置 | ai-config |

## 与 `install.sh` 的区别

| 维度 | `install.sh` | `install-by-tag.sh` |
|------|-------------|---------------------|
| 选择方式 | 按 **目录** (`--folder dev`) 或显式 skill 名 | 按 **tag**（跨目录） |
| 默认扫描 | 单目录 | 所有 5 个分类目录 |
| 适用场景 | 知道 skill 名或所属分类 | 跨分类按主题批量安装 |

## 安装后验证

```bash
ls ~/.claude/skills/         # macOS / Linux
dir $env:USERPROFILE\.claude\skills   # Windows
```

若已安装则会显示 `[SKIP]`；可先用 `clean-skills.sh` 清理后重装。
