# Dev Skills

开发工作流相关的 AI Agent Skill 集合。

## 技能列表

| Skill | 说明 |
|-------|------|
| **git-workflow** | 基于 GitHub CLI 的任务工作流（创建 Issue → 执行 → 关闭） |
| **local-workflow** | 本地任务工作流（无需 GitHub，本地追踪记录） |
| **github-cli-skill** | 简化版 GitHub CLI 工具（仓库创建、Issue 管理） |
| **gh-create-release** | GitHub Release 创建工具 |
| **scanning-for-secrets** | 代码安全扫描（9 种 Token 模式 + Pre-commit Hook） |
| **understand-anything** | 交互式代码知识图谱（将代码库转为可探索的知识图谱） |

## 安装

```bash
# 按 tag 批量安装所有 dev-workflow 相关 skill
./install-by-tag.sh dev-workflow --system

# 安装到特定 Agent
./install-by-tag.sh dev-workflow --system --agent claude-code

# 手动符号链接
ln -s $(pwd)/dev/git-workflow ~/.claude/skills/git-workflow
```


