# add — Install Skills

安装技能到检测到的 AI Agent 目录。

## 别名

`a`, `install`, `i`

## 语法

```
skill-spark add <source> [-g] [-f]
```

## 选项

| 选项 | 说明 |
|------|------|
| `-g, --global` | 安装到系统级全局目录（默认安装到项目本地） |
| `-f, --force` | 跳过确认提示，直接安装 |

## Source 类型

| 类型 | 格式 | 示例 |
|------|------|------|
| 本地目录 | 相对/绝对路径 | `skills/base`, `/path/to/skills` |
| 目录名 | 自动查找注册目录 | `devops` |
| GitHub 仓库 | URL 或简写 | `github:org/repo`, `org/repo` |
| GitLab 仓库 | 完整 URL | `https://gitlab.com/org/repo` |

## Scope

- **默认（Local）**：安装到项目目录的 `.agents/skills/` 及检测到的各 Agent 子目录
- **`-g`（Global）**：安装到用户级 Agent 目录（`~/.claude/skills/`, `~/.trae/skills/` 等）

安装时自动检测已安装的 Agent，技能会复制到所有检测到的 Agent 目录中。

## 工作流程

1. 解析 source，下载技能文件
2. 自动发现所有可安装的技能和命令
3. 自动检测目标 Agent 目录
4. 显示安装摘要，确认（`-f` 跳过）后执行
5. 将文件复制到每个 Agent 目录，写入 `skills.lock`

## 示例

```bash
# 安装本地目录中的所有技能
skill-spark add skills/base

# 安装到全局
skill-spark add skills/base -g

# 跳过确认，直接安装
skill-spark add skills/devops -f

# 从 GitHub 安装
skill-spark add org/skills-repo
```

## 安装结果

每个技能会显示安装到的 Agent 和完整路径：

```
✔ Installed 4 items.
  ✓ skill:git-workflow → Claude Code
    ~/.claude/skills/git-workflow
  ✓ skill:github-cli → Claude Code
    ~/.claude/skills/github-cli
```
