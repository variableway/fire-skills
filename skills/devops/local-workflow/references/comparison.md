# Workflow Skills 对比

本目录包含两个工作流 Skill：

- **git-workflow**: 完整的 GitHub 集成工作流
- **local-workflow**: 纯本地工作流，无需 GitHub

## 对比表

| 特性 | Local Workflow | GitHub Workflow |
|------|---------------|-----------------|
| 需要 GitHub 账号 | ❌ 否 | ✅ 是 |
| 创建 GitHub Issue | ❌ 否 | ✅ 是 |
| 需要 GitHub Token | ❌ 否 | ✅ 是（或使用 gh CLI） |
| 需要网络连接 | ❌ 否 | ✅ 是 |
| 追踪位置 | `tasks/tracing/*.md` | GitHub Issue + `tracing/*.md` |
| 适用场景 | 本地开发、无网络、私有项目、快速原型 | 团队协作、需要 GitHub 集成 |
| 代码提交 | 可选，需明确 `--commit` | 手动或 hooks 辅助 |
| 本地追踪记录 | ✅ 支持 | ✅ 支持 |
| 跨 Agent 兼容 | ✅ 支持 | ✅ 支持 |

## 选择建议

### 使用 Local Workflow 当：

- 你在本地快速开发原型
- 没有 GitHub 账号或不想使用 GitHub
- 处于离线环境
- 项目是私有的，不想同步到 GitHub
- 不需要团队协作

### 使用 GitHub Workflow 当：

- 需要与团队协作
- 希望利用 GitHub Issues 进行任务管理
- 需要完整的 Issue 追踪历史
- 希望使用 GitHub Projects 等功能
- 需要自动化的 CI/CD 集成

## 切换工作流

两个工作流 Skill 的命令非常相似：

```bash
# Local Workflow
python3 .agents/skills/local-workflow/scripts/orchestrate.py init tasks/my-task.md
python3 .agents/skills/local-workflow/scripts/orchestrate.py finish

# GitHub Workflow
python3 .agents/skills/git-workflow/scripts/orchestrate.py init --title "Task title" --description "Task description"
python3 .agents/skills/git-workflow/scripts/orchestrate.py finish --message "Completion summary"
```

你可以在任何时候选择使用任意一种工作流，它们互不干扰。
