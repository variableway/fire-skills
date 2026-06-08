---
name: github-cli
description: GitHub CLI operations helper. Use when the user needs gh commands for repository creation, issue listing/viewing/commenting/closing, or small GitHub CLI snippets without running the full git-workflow Issue lifecycle.
compatibility: Requires authenticated GitHub CLI gh.
metadata:
  type: skill
  supported_agents:
    - claude-code
    - kimi
    - codex
    - opencode
    - trae
    - trae-solo
    - workbuddy
    - openclaw
    - hermes agent
  tags:
    - github
    - cli
    - dev-workflow
---

# GitHub CLI Skill

使用 `gh` 命令行工具管理 GitHub 仓库和 Issue。

## 使用边界

- 只需要 GitHub CLI 命令、Issue 查看/评论/关闭、仓库创建时使用本 Skill。
- 需要“创建 Issue -> 执行任务 -> 关闭 Issue”的完整任务生命周期时，使用 `git-workflow`。
- 需要本地离线任务追踪时，使用 `local-workflow`。

## 前置要求

需要安装 GitHub CLI 并登录：

```bash
# macOS
brew install gh

# 登录
gh auth login
```

## 常用命令

### 仓库管理

```bash
# 创建新仓库（当前目录）
gh repo create --public --source=. --push

# 创建新仓库（指定名称）
gh repo create my-repo --public --clone

# 查看当前仓库
gh repo view --web
```

### Issue 管理

```bash
# 创建 Issue
gh issue create --title "标题" --body "内容" --label "bug"

# 从文件创建 Issue（文件内容为 body）
gh issue create --title "标题" --body-file ./issue-body.md --label "bug"

# 列出 Issues
gh issue list

# 查看 Issue
gh issue view 123

# 在浏览器打开 Issue
gh issue view 123 --web

# 添加评论
gh issue comment 123 --body "评论内容"

# 关闭 Issue
gh issue close 123

# 重新打开 Issue
gh issue reopen 123
```

## Python 脚本集成

### 独立脚本：create_issue.py

```bash
# 创建 Issue（inline body）
python3 .agents/skills/github-cli/scripts/create_issue.py --title "标题" --body "内容" --labels "bug,enhancement"

# 从文件创建 Issue
python3 .agents/skills/github-cli/scripts/create_issue.py --title "标题" --body-file ./issue-body.md --labels "task"

# 指定仓库
python3 .agents/skills/github-cli/scripts/create_issue.py --title "标题" --body "内容" --repo owner/repo
```

| 参数 | 说明 |
|------|------|
| `--title` | Issue 标题（必填） |
| `--body` | Issue 内容（与 --body-file 二选一） |
| `--body-file` | 文件路径作为 Issue 内容（与 --body 二选一） |
| `--labels` | 逗号分隔的标签 |
| `--repo` | 仓库 owner/repo，不填则自动检测 |
| `--remote` | git remote 名称，默认 origin |

### 代码片段

```python
import subprocess

def create_issue(title: str, body: str, labels: list = None):
    """创建 GitHub Issue"""
    cmd = ["gh", "issue", "create", "--title", title, "--body", body]
    if labels:
        for label in labels:
            cmd.extend(["--label", label])
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return result.stdout.strip()

def create_issue_from_file(title: str, body_file: str, labels: list = None):
    """从文件创建 GitHub Issue（文件内容为 body）"""
    cmd = ["gh", "issue", "create", "--title", title, "--body-file", body_file]
    if labels:
        for label in labels:
            cmd.extend(["--label", label])
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return result.stdout.strip()

def close_issue(issue_number: int):
    """关闭 Issue"""
    subprocess.run(
        ["gh", "issue", "close", str(issue_number)],
        check=True
    )

def comment_issue(issue_number: int, body: str):
    """添加评论"""
    subprocess.run(
        ["gh", "issue", "comment", str(issue_number), "--body", body],
        check=True
    )
```

## 快速参考

| 操作 | 命令 |
|------|------|
| 创建 Issue | `gh issue create --title "xxx" --body "yyy"` |
| 从文件创建 Issue | `gh issue create --title "xxx" --body-file ./file.md` |
| 关闭 Issue | `gh issue close <number>` |
| 添加评论 | `gh issue comment <number> --body "xxx"` |
| 创建仓库 | `gh repo create --public --source=. --push` |

## 安装

Prefer installing with `skill-spark`:

```bash
./dist/skill-spark add skills/devops --skill github-cli --agent codex claude-code opencode trae kimi --yes
```

The bundled install scripts are legacy fallbacks for environments that do not use `skill-spark`:

```bash
./scripts/install.sh --system
.\scripts\install.ps1 -System
```
