# GitHub Issues 批量关闭 Use Case

使用 gh CLI 批量关闭 GitHub Issues。

## 使用场景

- 清理过期的 Issues
- 批量关闭已完成的任务
- 项目维护和整理

## 示例

### 1. 列出所有开放的 Issues

```bash
gh issue list --state open --limit 100
```

### 2. 获取 Issue 编号列表

```bash
gh issue list --state open --limit 100 --json number --jq '.[].number'
```

### 3. 批量关闭 Issues

```bash
for issue in $(gh issue list --state open --limit 100 --json number --jq '.[].number'); do
  gh issue close $issue --comment "Closed by automation"
done
```

### 4. 关闭单个 Issue

```bash
gh issue close 64 --comment "Task completed"
```

## 本次操作结果

已关闭以下 Issues:

| Issue | 标题 |
|-------|------|
| #64 | Task 2 & 3: URL内容获取 + GH关闭Issues |
| #51 | Task 1: Github Workflow/Local Workflow 测试验证 |
| #41 | Task 2: Q&A 转课程 + AI 学习平台 Top 20 仓库调研 |
| #38 | 评估新的frontend skill想法 |
| #37 | 现实的是使用skill 问题 |
| #36 | 按照 |
| #35 | frontend skill 优化 |
| #34 | 需要示范代码 |
| #33 | 创建install fe-skill脚本 |
| #32 | 合并FE Skill |
| #31 | Analalysis FE Skills |

共关闭 11 个 Issues。
