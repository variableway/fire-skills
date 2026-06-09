# Skill Use Cases

skill-spark 和相关 skills 的使用案例和结果。

## URL 内容提取

使用 anysearch skill 提取网页内容为 Markdown。

| 文件 | 说明 |
|------|------|
| [url-extraction.md](extract/url-extraction.md) | URL 提取使用指南 |
| [url-extract-github-docs.md](extract/url-extract-github-docs.md) | GitHub Issues 文档提取 |
| [url-extract-gh-cli.md](extract/url-extract-gh-cli.md) | GitHub CLI 文档提取 |

## GitHub Issues 批量管理

使用 gh CLI 批量关闭 Issues。

| 文件 | 说明 |
|------|------|
| [gh-close-issues.md](gh-close-issues.md) | 批量关闭 Issues 使用指南 |

## 搜索结果

### Agent Github Automation

搜索 "Agent Github Automation" 相关 skills。

| 格式 | 文件 |
|------|------|
| JSON | [agent-github-automation.json](search/agent-github-automation.json) |
| Markdown | [agent-github-automation.md](search/agent-github-automation.md) |

### GitHub PR/Issue Workflow

搜索 "github PR Issue workflow" 相关 skills。

| 格式 | 文件 |
|------|------|
| JSON | [github-pr-issue-workflow.json](search/github-pr-issue-workflow.json) |
| Markdown | [github-pr-issue-workflow.md](search/github-pr-issue-workflow.md) |

### GitHub Skills

搜索 "github" 相关 skills。

| 格式 | 文件 |
|------|------|
| JSON | [github-skills.json](search/github-skills.json) |
| Markdown | [github-skills.md](search/github-skills.md) |

### Workflow Automation

搜索 "workflow automation" 相关 skills。

| 格式 | 文件 |
|------|------|
| JSON | [workflow-automation.json](search/workflow-automation.json) |
| Markdown | [workflow-automation.md](search/workflow-automation.md) |

## 搜索命令

```bash
# JSON 格式
dist/skill-spark search "关键词" --output results.json

# Markdown 格式
dist/skill-spark search "关键词" --output results.md --format markdown

# 自动检测格式 (.md 扩展名自动用 markdown)
dist/skill-spark search "关键词" --output results.md
```
