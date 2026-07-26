# add — Install Skills and Commands

安装技能（Skills）和命令（Commands）到 AI 编码 Agent 的对应目录中。

## 别名

`a`, `install`, `i`

## 语法

```
skill-spark add <source> [options]
```

## Source 类型

`<source>` 支持以下输入形式：

| 类型 | 格式 | 示例 |
|------|------|------|
| 本地目录 | 相对/绝对路径 | `./skills/base`, `/path/to/skills` |
| 目录名 | `skills/` 目录下的子目录名 | `devops` → 自动查找目录中对应的 source |
| GitHub 仓库 | 完整 URL 或简写 | `github:org/repo`, `org/repo` |
| GitHub 子目录 | 带 branch 和子路径 | `github:org/repo/tree/main/skills/my-skill` |
| GitLab 仓库 | 完整 URL | `https://gitlab.com/org/repo` |
| Well-known | 域名（自动发现 agent-skills） | `example.com` |

## 选项

| 选项 | 说明 |
|------|------|
| `-g, --global` | 安装到系统级全局文件夹（默认安装到项目本地） |
| `-a, --agent <agents...>` | 指定目标 Agent，如 `claude-code trae` |
| `-s, --skill <skills...>` | 按名称筛选，只安装指定的 skill 或 command |
| `-l, --list` | 仅列出可安装项，不执行安装 |
| `-f, --force` | 强制安装，跳过所有交互确认和覆盖提示 |

## Scope：Local vs Global

### Local（默认）

安装到项目文件夹内，技能和命令可以被团队成员共享。

```
项目根目录/
├── .agents/skills/          ← universal agents 共用
├── .claude/skills/           ← Claude Code 专用
├── .trae/skills/             ← Trae 专用
├── .claude/commands/         ← Claude Code 命令
└── skills.lock               ← 安装记录
```

本地安装时：
- `.agents/skills/` 始终包含在内（universal agents：Codex、Claude Code、OpenCode、Cursor 等）
- 可额外选择非 universal agent 的专用文件夹
- 技能和命令安装记录写入项目根目录的 `skills.lock`

### Global（`-g`）

安装到用户级目录，跨项目共享。不同 Agent 写入各自在 `~/.skill-spark/` 下的文件夹。

## 交互流程

不带 `-f` / `--force` 时，`add` 会引导你完成以下步骤：

```
1. 解析 source，下载/定位技能文件
2. 展示发现的技能和命令，选择要安装的项（多选）
3. 选择目标 Agent 目录（根据 scope 不同）
4. 展示安装摘要，确认后执行
5. 显示每个项的安装结果和路径
```

使用 `-f` 会跳过步骤 2-4 的交互确认，直接安装所有发现的技能到自动检测的 Agent 目录。安装总是使用文件复制模式。

## 示例

### 1. 安装本地技能目录

```bash
# 安装 skills/base 目录下的所有技能
skill-spark add skills/base

# 安装本地目录，只选特定技能
skill-spark add skills/base --skill git-workflow --skill github-cli
```

### 2. 安装目录中的技能

```bash
# 通过目录名查找并安装 devops 技能
skill-spark add devops
```

### 3. 从 GitHub 安装

```bash
# GitHub 简写（默认 main 分支）
skill-spark add org/skills-repo

# 指定子目录
skill-spark add org/skills-repo/skills/ci-cd

# 完整 URL + 指定分支
skill-spark add github:org/skills-repo/tree/develop/skills/deploy
```

### 4. 指定目标 Agent

```bash
# 只安装到 Claude Code 和 Trae
skill-spark add skills/base --agent claude-code trae

# 全局安装，指定 Agent
skill-spark add skills/base --global --agent claude-code cursor
```

### 5. 自动化 / 跳过交互

```bash
# 跳过所有交互，直接安装到检测到的 Agent 目录
skill-spark add skills/base --force

# 全局强制安装
skill-spark add devops --global -f
```

### 6. 预览可安装内容

```bash
# 列出 source 中的技能和命令（不安装）
skill-spark add skills/base --list

# 列出 well-known host 的技能
skill-spark add example.com --list
```

## 安装结果

成功安装后输出示例：

```
◇  Install Summary
│
│  Source: skills/base
│  Scope: Local
│  Items: skill:git-workflow, skill:github-cli
│  Included local folder: .agents/skills
│  Universal agents: Claude Code, OpenCode, Codex, Cursor, and 23 more
│
◇  Ready to install?
│  Yes
│
◆  Installing...
◇  Install complete
│
✔ Installed 4 items.
  ✓ skill:git-workflow → Claude Code
    /path/to/project/.claude/skills/git-workflow
  ✓ skill:git-workflow → OpenCode
    /path/to/project/.agents/skills/git-workflow
  ✓ skill:github-cli → Claude Code
    /path/to/project/.claude/skills/github-cli
  ✓ skill:github-cli → OpenCode
    /path/to/project/.agents/skills/github-cli
```

## 常见问题

**Q: 为什么有些 Agent 在 local 模式下只用 `.agents/skills/`？**

A: 这是 universal agents（Codex、Claude Code、OpenCode、Cursor 等），它们共用同一个目录。选择任意一个 universal agent 时，都会自动使用 `.agents/skills/`。

**Q: 如何只安装命令（commands）而不安装技能（skills）？**

A: 用 `--skill` 筛选命令名称：
```bash
skill-spark add skills/base --skill my-command -l  # 先用 -l 查看名称
skill-spark add skills/base --skill my-command      # 安装
```

**Q: 安装后 Agent 能立即使用吗？**

A: 能。技能文件写入 Agent 的 skills 目录后，Agent 下次启动时会自动读取。部分 Agent 可能需要重启。

**Q: 如何查看已安装了什么？**

A: 使用 `skill-spark list` 查看所有已安装项，或 `skill-spark outdated` 查看哪些需要更新。
