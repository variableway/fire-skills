# agent — Manage Agent Configurations

管理目标 AI Agent 的目录配置。

## 别名

`agents`

## 子命令

### agent list

列出内置和自定义 Agent 配置。

```bash
skill-spark agent list
skill-spark agent list --json
```

### agent schema

打印 `skill-spark.agents.json` 标准格式。

```bash
skill-spark agent schema
```

### agent add

添加自定义 Agent 配置。

```bash
skill-spark agent add my-agent \
  --label "My Agent" \
  --skills-dir .my-agent/skills \
  --global-skills-dir ~/.my-agent/skills \
  --alias ma
```

| 选项 | 说明 |
|------|------|
| `--label <label>` | Agent 显示名称 |
| `--skills-dir <path>` | 项目级技能目录 |
| `--global-skills-dir <path>` | 全局技能目录 |
| `--commands-dir <path>` | 项目级命令目录 |
| `--global-commands-dir <path>` | 全局命令目录 |
| `--alias <aliases...>` | 别名 |
| `--global` | 写入 ~/.skill-spark/agents.json |
| `--force` | 覆盖已有配置 |

### agent remove

移除自定义 Agent 配置。

```bash
skill-spark agent remove my-agent
skill-spark agent remove my-agent --global
```

## 内置 Agent

当前支持 40+ 内置 Agent，包括 Claude Code、Cursor、Codex、OpenCode、Trae、Kimi Code CLI、Windsurf、GitHub Copilot 等。

```bash
skill-spark agent list
```
