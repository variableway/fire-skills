# DevOps Skills 安装指南

本指南说明如何使用 `skill-spark` 安装和管理 DevOps 相关的 skills。DevOps skills 提供任务执行工作流、GitHub CLI 辅助、发布管理和安全扫描等功能。

---

## 目录

- [前置条件](#前置条件)
- [快速安装](#快速安装)
- [逐个安装 DevOps Skills](#逐个安装-devops-skills)
- [安装模式说明](#安装模式说明)
- [验证安装](#验证安装)
- [更新与卸载](#更新与卸载)
- [常见问题排查](#常见问题排查)

---

## 前置条件

1. **构建 CLI 工具**

   首次使用前需要构建 `skill-spark`：

   ```bash
   bun run build
   ```

   如需编译为独立二进制文件：

   ```bash
   bun run build:exe
   ```

2. **GitHub CLI 认证（部分技能需要）**

   以下 skills 需要已认证的 `gh` CLI：
   - `git-workflow`
   - `github-cli-skill`
   - `gh-create-release`

   认证方式：

   ```bash
   gh auth login
   ```

---

## 快速安装

### 安装全部 DevOps Skills

```bash
# 全局安装（推荐，所有项目可用）
./scripts/install.sh skills/devops --system

# 仅安装到当前项目
./scripts/install.sh skills/devops --project

# 为指定 Agent 安装（如 codex）
./scripts/install.sh skills/devops --project --agent codex
```

### 安装单个 Skill

```bash
# 仅安装 git-workflow
./scripts/install.sh skills/devops --skill git-workflow --system

# 仅安装 local-workflow
./scripts/install.sh skills/devops --skill local-workflow --project

# 仅安装 secret 扫描工具
./scripts/install.sh skills/devops --skill scanning-for-secrets --system
```

---

## 逐个安装 DevOps Skills

### 1. git-workflow（GitHub Issue 工作流）

基于 GitHub Issue 的完整任务生命周期管理，适用于需要 Issue 作为任务记录的场景。

```bash
# 安装
./scripts/install.sh skills/devops --skill git-workflow --system

# 验证
ls ~/.skill-spark/.agents/skills/git-workflow/
```

**功能特性：**
- 创建 GitHub Issue 初始化任务
- 任务执行完成后自动更新并关闭 Issue
- 提供 `init` / `finish` / `status` / `abort` 完整生命周期
- 支持 Git 钩子自动关联提交与 Issue

**前置条件：**
- Git 仓库需配置 GitHub 远程地址
- 已认证 `gh` CLI

---

### 2. local-workflow（本地离线工作流）

完全本地化的任务追踪，无需 GitHub，适用于私有项目或离线环境。

```bash
# 安装
./scripts/install.sh skills/devops --skill local-workflow --system

# 验证
ls ~/.skill-spark/.agents/skills/local-workflow/
```

**功能特性：**
- 通过 `tasks/tracing/` 目录本地追踪任务状态
- 支持 `init` → `execute` → `finish` 完整生命周期
- 可选的 `git commit` / `git push` 集成
- 支持直接查看任务追踪记录

**前置条件：**
- Python 3
- Git（仅在使用 `--commit` / `--push` 选项时需要）

---

### 3. github-cli-skill（GitHub CLI 速查）

快速执行常用 `gh` 命令，无需记忆完整参数。

```bash
# 安装
./scripts/install.sh skills/devops --skill github-cli-skill --system

# 验证
ls ~/.skill-spark/.agents/skills/github-cli-skill/
```

**功能特性：**
- 常用 `gh` 命令速查（repo / issue / pr / release）
- 通过脚本快速创建 Issue
- 支持指定目标仓库

**前置条件：**
- 已认证 `gh` CLI

---

### 4. gh-create-release（GitHub 发布管理）

创建 GitHub Release，支持标签、发布说明和附件上传。

```bash
# 安装
./scripts/install.sh skills/devops --skill gh-create-release --system

# 验证
ls ~/.skill-spark/.agents/skills/gh-create-release/
```

**功能特性：**
- 自动生成或自定义发布说明
- 支持草稿（draft）和预发布（prerelease）
- 支持附件上传
- 从 CHANGELOG.md 提取发布说明

**前置条件：**
- Git 仓库需包含有效标签
- 已认证 `gh` CLI

---

### 5. scanning-for-secrets（敏感信息扫描）

在提交前扫描暂存区文件中的密钥、令牌和 API 密钥，防止敏感信息泄露。

```bash
# 安装
./scripts/install.sh skills/devops --skill scanning-for-secrets --system

# 验证
ls ~/.skill-spark/.agents/skills/scanning-for-secrets/
```

**功能特性：**
- 检测 GitHub Token、AWS 密钥、Google API Key、Slack Token 等
- 支持 `gitleaks` 和 `grep` 两种扫描方式
- 提供预提交 Git 钩子
- 发现密钥时的应急处理指南

**前置条件：**
- Git
- 可选：`gitleaks` 或 `detect-secrets`（提供更彻底的扫描）

---

## 安装模式说明

### 符号链接模式（默认）

Skills 存放在规范目录中，通过符号链接映射到各 Agent 目录：

```text
~/.skill-spark/.agents/skills/<name>/  ← 规范存储位置
        ↓
.claude/skills/<name>  → 符号链接
.cursor/skills/<name>  → 符号链接
```

**优点：**
- 更新一处，全局生效
- 节省磁盘空间
- 便于统一管理

### 复制模式（`--no-symlink`）

Skills 直接复制到目标 Agent 目录：

```text
.claude/skills/<name>/  ← 直接复制
.cursor/skills/<name>/  ← 直接复制
```

**适用场景：**
- 需要独立修改某个 Agent 的 skill 配置
- 符号链接在目标环境中不受支持

```bash
# 使用复制模式安装
./scripts/install.sh skills/devops --system --no-symlink
```

---

## 验证安装

### 列出已安装的 Skills

```bash
skill-spark list
```

### 检查特定 Skill 是否安装

```bash
# 查看全局安装目录
ls ~/.skill-spark/.agents/skills/

# 查看项目本地安装目录
ls .claude/skills/
ls .cursor/skills/
```

### 诊断环境

```bash
skill-spark doctor
```

### 检查可更新项

```bash
skill-spark outdated
```

---

## 更新与卸载

### 更新 DevOps Skills

```bash
# 更新所有已安装的 skills
./scripts/update.sh

# 更新指定的 skills
./scripts/update.sh git-workflow local-workflow
```

### 卸载 DevOps Skills

```bash
# 卸载单个 skill
./scripts/remove.sh git-workflow

# 卸载多个 skills
./scripts/remove.sh git-workflow local-workflow

# 自动确认卸载（无需交互）
./scripts/remove.sh git-workflow --yes
```

---

## 常见问题排查

### `skill-spark` 命令未找到

**原因：** CLI 未构建或二进制未安装。

**解决：**

```bash
bun run build
# 或
bun run build:exe
```

然后重试命令。

### `gh` CLI 未认证

**现象：** 使用 `git-workflow`、`github-cli-skill` 或 `gh-create-release` 时提示认证失败。

**解决：**

```bash
gh auth login
```

### 安装后 Agent 无法识别 Skill

**原因：** 安装路径与 Agent 期望路径不一致。

**解决：**

1. 确认安装模式（符号链接 vs 复制）
2. 检查 Agent 的 skills 目录配置
3. 使用 `skill-spark doctor` 诊断环境

### 符号链接失效

**原因：** 源文件被移动或删除。

**解决：**

```bash
# 重新安装该 skill
./scripts/install.sh skills/devops --skill <name> --system --force
```

---

## Skills 对比速查

| Skill | 用途 | 需要 GitHub | 离线可用 | 典型场景 |
|-------|------|:-----------:|:--------:|----------|
| `git-workflow` | Issue 驱动的任务工作流 | ✅ | ❌ | 需要 GitHub Issue 作为任务记录 |
| `local-workflow` | 本地离线任务追踪 | ❌ | ✅ | 私有项目、离线环境 |
| `github-cli-skill` | 常用 `gh` 命令速查 | ✅ | ❌ | 快速执行 GitHub 操作 |
| `gh-create-release` | GitHub Release 创建 | ✅ | ❌ | 版本发布、附件上传 |
| `scanning-for-secrets` | 提交前敏感信息扫描 | ❌ | ✅ | 代码安全、密钥保护 |

### 选择建议

- **需要完整 GitHub 任务管理** → 使用 `git-workflow`
- **无 GitHub 或离线环境** → 使用 `local-workflow`
- **快速执行 `gh` 命令** → 使用 `github-cli-skill`
- **发布版本** → 使用 `gh-create-release`
- **提交前安全检查** → 使用 `scanning-for-secrets`

---

## 相关文档

- [通用安装指南](./install-skills.md) — 更完整的安装、卸载、更新说明
- [DevOps Skills 使用指南](../devops-skills-usage.md) — 各 skill 的详细使用说明
