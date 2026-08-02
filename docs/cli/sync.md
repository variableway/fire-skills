# sync — Sync Skills to Agent Folders

从源目录同步技能到目标 AI Agent 的技能文件夹。

## 语法

```
skill-spark sync [options]
```

## 选项

| 选项 | 说明 |
|------|------|
| `-s, --source <path>` | 源目录（默认：skills/base） |
| `-a, --agent <agents...>` | 目标 Agent（默认：codex, claude-code, opencode, trae, kimi-cli） |
| `--skill <names...>` | 仅同步匹配名称的技能 |
| `--global` | 同步到全局 Agent 文件夹 |
| `-y, --yes` | 脚本兼容，sync 为非交互式 |
| `-f, --force` | 覆盖已有目标文件夹 |

## 示例

```bash
# 同步默认源到默认 Agent
skill-spark sync

# 指定源和目标 Agent
skill-spark sync -s qdriven/devops-skill -a claude-code trae

# 全局同步特定技能
skill-spark sync --skill git-workflow --global

# 强制覆盖
skill-spark sync -f
```
