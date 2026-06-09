# Dev Skills

开发工作流相关的 AI Agent Skill 集合。

## 技能列表

| Skill | 说明 |
|-------|------|
| **git-workflow** | 基于 GitHub CLI 的任务工作流（创建 Issue body 主记录 → 计划/执行/检查 → 更新并关闭 Issue） |
| **local-workflow** | 本地任务工作流（无需 GitHub，本地追踪记录） |
| **github-cli** | 简化版 GitHub CLI 工具（仓库创建、Issue 管理） |
| **gh-create-release** | GitHub Release 创建工具 |
| **scanning-for-secrets** | 代码安全扫描（9 种 Token 模式 + Pre-commit Hook） |

## 安装

推荐使用仓库根目录的统一脚本管理 Git/Local workflow：

```bash
# macOS / Linux / WSL2 / Git Bash
scripts/dev-workflow.sh install --agent codex
scripts/dev-workflow.sh verify --agent codex
scripts/dev-workflow.sh update --agent codex
scripts/dev-workflow.sh remove --agent codex

# system/global level for Codex
scripts/dev-workflow.sh install --scope system --agent codex
scripts/dev-workflow.sh verify --scope system --agent codex
scripts/dev-workflow.sh remove --scope system --agent codex
```

Windows PowerShell / PowerShell 7：

```powershell
pwsh -File scripts/dev-workflow.ps1 install -Agent codex
pwsh -File scripts/dev-workflow.ps1 verify -Agent codex
pwsh -File scripts/dev-workflow.ps1 update -Agent codex
pwsh -File scripts/dev-workflow.ps1 remove -Agent codex

# system/global level for Codex
pwsh -File scripts/dev-workflow.ps1 install -Scope system -Agent codex
pwsh -File scripts/dev-workflow.ps1 verify -Scope system -Agent codex
pwsh -File scripts/dev-workflow.ps1 remove -Scope system -Agent codex
```

Codex project level 会安装到 `.agents/skills`；Codex system/global level 会安装到 `$CODEX_HOME/skills`，未设置 `CODEX_HOME` 时为 `~/.codex/skills`。

## No-Hook 使用方式

不需要安装 hook 也可以完整使用 Git/Local workflow。推荐把 hook 当成可选提醒，而不是主控制机制。

Codex 下的 GitHub Issue 工作流：

```bash
python3 .agents/skills/git-workflow/scripts/orchestrate.py init \
  --title "任务标题" \
  --description "任务描述"

# Agent 执行计划、修改和测试

python3 .agents/skills/git-workflow/scripts/orchestrate.py finish \
  --agent-expansion "范围澄清、关键假设、验收标准" \
  --plan "执行计划" \
  --execution "变更内容、测试和检查" \
  --message "完成总结"
```

Codex 下的本地工作流：

```bash
python3 .agents/skills/local-workflow/scripts/orchestrate.py init tasks/my-task.md
# Agent 执行任务
python3 .agents/skills/local-workflow/scripts/orchestrate.py finish
```

只有在确实需要自动提醒或 commit 事件日志时，再安装 hook：

```bash
scripts/dev-workflow.sh hooks --agent claude-code
```

注意：Codex 不执行 Claude Code 的 `.claude/settings.json` hook。Codex 的控制入口是 `AGENTS.md`、已安装的 `.agents/skills/*/SKILL.md`，以及上面的显式 CLI。

底层仍然使用 `skill-spark`：

```bash
# 查看可安装的 DevOps Skills
./dist/skill-spark add skills/devops --list --silent

# 同步全部 DevOps Skills 到常用 agent
./dist/skill-spark sync --source skills/devops --agent codex claude-code opencode trae kimi --yes

# 安装单个 Skill
./dist/skill-spark add skills/devops --skill git-workflow --agent codex claude-code --yes
```

Codex、OpenCode、Kimi 在项目级安装时共享 `.agents/skills`。Claude Code 使用 `.claude/skills`，Trae 使用 `.trae/skills`。

## 选择建议

| 场景 | 推荐 Skill |
| --- | --- |
| 任务需要 GitHub Issue 生命周期 | `git-workflow` |
| 本地/离线/无需 GitHub 的任务追踪 | `local-workflow` |
| 只需要 GitHub CLI 命令速查 | `github-cli` |
| 创建 GitHub Release | `gh-create-release` |
| commit/push 前查 secret | `scanning-for-secrets` |
