# DevOps Skills 安装与使用指南

将 `skills/devops/` 下的 skills 安装到指定目录（支持 system 级和 project 级）。

## skills/devops 技能列表

| Skill | 用途 | 需要 GitHub |
|-------|------|-------------|
| **git-workflow** | 基于 GitHub Issue 的任务生命周期管理 | 是 |
| **local-workflow** | 本地任务追踪（无需 GitHub） | 否 |
| **github-cli-skill** | GitHub CLI 快捷操作（仓库、Issue 管理） | 是 |
| **gh-create-release** | GitHub Release 创建 | 是 |
| **scanning-for-secrets** | 代码安全扫描（9 种 Token 模式 + Pre-commit Hook） | 否 |

---

## 安装方式

### 方式一：使用统一安装脚本

推荐使用 `skills/devops/dev-workflow-install.sh` 一键安装所有 4 个 workflow skills：

```bash
# === System 级安装（安装到 ~/.config/agents/skills/ 及对应 agent 目录） ===

# 默认（安装到所有支持的 agent 目录）
bash skills/devops/dev-workflow-install.sh --system

# 指定 agent（claude-code | kimi | codex | opencode | trae | trae-solo）
bash skills/devops/dev-workflow-install.sh --system --agent trae

# === Project 级安装（安装到当前项目 ./.agents/skills/） ===
bash skills/devops/dev-workflow-install.sh --project

# === 安装时附带 git hooks ===
bash skills/devops/dev-workflow-install.sh --system --hooks
```

### 方式二：手动安装到指定目录

#### 2.1 复制 skill 到目标目录

```bash
# 设定目标目录
TARGET_DIR="$HOME/.trae/skills"          # Trae
# TARGET_DIR="$HOME/.claude/skills"      # Claude Code
# TARGET_DIR="$HOME/.codex/skills"       # Codex
# TARGET_DIR="./.agents/skills"          # Project 级

# 复制单个 skill
cp -R skills/devops/git-workflow "$TARGET_DIR/"
cp -R skills/devops/local-workflow "$TARGET_DIR/"
cp -R skills/devops/github-cli-skill "$TARGET_DIR/"
cp -R skills/devops/gh-create-release "$TARGET_DIR/"

# 复制所有 devops skills
for skill in git-workflow local-workflow github-cli-skill gh-create-release; do
  cp -R "skills/devops/$skill" "$TARGET_DIR/"
done
```

#### 2.2 使用符号链接（推荐）

**一键脚本**（推荐）：

```bash
# System 级安装到全部 agent
bash skills/devops/dev-workflow-symlink-install.sh --system

# 指定 agent
bash skills/devops/dev-workflow-symlink-install.sh --system --agent trae

# Project 级安装
bash skills/devops/dev-workflow-symlink-install.sh --project
```

脚本会自动检测已有链接，若指向同一源则跳过，指向不同源则更新。

**手动创建符号链接**：

```bash
TARGET_DIR="$HOME/.trae/skills"
SKILLS_ROOT="$(pwd)/skills/devops"

ln -s "$SKILLS_ROOT/git-workflow" "$TARGET_DIR/git-workflow"
ln -s "$SKILLS_ROOT/local-workflow" "$TARGET_DIR/local-workflow"
ln -s "$SKILLS_ROOT/github-cli-skill" "$TARGET_DIR/github-cli-skill"
ln -s "$SKILLS_ROOT/gh-create-release" "$TARGET_DIR/gh-create-release"
ln -s "$SKILLS_ROOT/scanning-for-secrets" "$TARGET_DIR/scanning-for-secrets"
```

---

## 各 Agent 的默认 Skill 目录

| Agent | System 级目录 | Project 级目录 |
|-------|--------------|---------------|
| Claude Code | `~/.claude/skills/` | `./.claude/skills/` |
| Kimi | `~/.kimi/skills/` | `./.kimi/skills/` |
| Codex | `~/.codex/skills/` | `./.agents/skills/` |
| OpenCode | `~/.opencode/skills/` | `./.agents/skills/` |
| **Trae** | `~/.trae/skills/` | `./.trae/skills/` |
| 通用 | `~/.config/agents/skills/` | `./.agents/skills/` |

---

## 验证安装

```bash
# 检查 skill 目录是否存在
ls -la ~/.trae/skills/git-workflow/SKILL.md
ls -la ~/.trae/skills/github-cli-skill/SKILL.md

# 对于符号链接，确认链接有效
readlink ~/.trae/skills/git-workflow
```

---

## 使用示例

### git-workflow

```bash
# 初始化：创建 GitHub Issue
python3 ~/.trae/skills/git-workflow/scripts/orchestrate.py init \
  --title "Task title" \
  --description "Task description"

# 完成任务：更新并关闭 Issue
python3 ~/.trae/skills/git-workflow/scripts/orchestrate.py finish \
  --message "Completion summary"

# 查看状态
python3 ~/.trae/skills/git-workflow/scripts/orchestrate.py status
```

### local-workflow（无需 GitHub）

```bash
# 初始化本地任务追踪
python3 ~/.trae/skills/local-workflow/scripts/orchestrate.py init tasks/issues/my-task.md

# 完成任务
python3 ~/.trae/skills/local-workflow/scripts/orchestrate.py finish
```

### scanning-for-secrets

```bash
# 手动复制到目标目录
cp -R skills/devops/scanning-for-secrets ~/.trae/skills/

# 提交前扫描
gitleaks detect --source . --staged --redact
```

---

## 自然语言触发

安装完成后，在对话中使用自然语言即可触发对应 skill：

- "执行 Task 9" → 触发 git-workflow
- "本地追踪这个任务" → 触发 local-workflow
- "用 gh 创建一个 Issue" → 触发 github-cli-skill
- "给 v1.0.0 创建 release" → 触发 gh-create-release
- "提交前检查有没有密钥泄露" → 触发 scanning-for-secrets

## 前置条件

- `git` 已安装
- `gh` CLI 已安装并认证（git-workflow、github-cli-skill、gh-create-release 需要）
  ```bash
  brew install gh       # macOS
  gh auth login
  ```
