---
name: skill-spark
description: 使用 skill-spark 管理 AI coding agent skills。用于安装 Skill、同步到 Codex/Claude Code/OpenCode/Trae/Kimi 或自定义 agent、解释 agent 目录差异、维护 skills.lock、执行 list/outdated/update/remove/doctor，以及添加自定义 agent 目录配置。
metadata:
  triggers:
    - pattern: "install.*skill|安装.*skill|添加.*skill|部署.*skill"
    - pattern: "sync.*skill|同步.*skill|映射.*skill|map.*skill"
    - pattern: "update.*skill|更新.*skill|升级.*skill"
    - pattern: "remove.*skill|删除.*skill|卸载.*skill|清理.*skill"
    - pattern: "skill-spark|管理.*skill|skill.*lock|skill.*目录"
    - pattern: "list.*skill|outdated|doctor|skill.*状态"
---

# Skill Spark

Skill Spark 是 SkillOps CLI：它不负责实时搜索网页；发现资料优先交给 AnySearch。Skill Spark 负责把找到的 Skill 安装、同步、追踪、更新和移除。

## 何时使用

- 用户要安装某个 Skill 到一个或多个 AI coding agent。
- 用户要同步 `skills/base` 到 Codex、Claude Code、OpenCode、Trae、Kimi。
- 用户不清楚不同 agent 的 skills/commands 目录在哪里。
- 用户要查看或维护 `skills.lock`，执行 `list`、`outdated`、`update`、`remove`。
- 用户要添加一个内置列表之外的新 agent 目录配置。

## 运行入口

在仓库根目录优先使用已构建的可执行文件：

```bash
./dist/skill-spark <command> [options]
```

如果 `dist/skill-spark` 不存在，先构建：

```bash
bun run build:all
```

fallback 顺序：

```bash
node dist/index.js <command> [options]
bun src/index.ts <command> [options]
```

下面用 `<spark>` 代表可用入口，例如 `./dist/skill-spark`。

## 常用命令

在仓库根目录运行：

```bash
<spark> add skills/base --list --silent
<spark> add skills/meta --list --silent
<spark> add skills/base --skill anysearch --agent codex claude-code opencode trae kimi --yes
<spark> sync --source skills/base --agent codex claude-code opencode trae kimi --yes
<spark> sync --source skills/meta --skill skill-creator --agent codex claude-code opencode trae kimi --yes
<spark> list
<spark> outdated --verbose
<spark> update --yes
<spark> remove anysearch --yes
<spark> doctor
```

`kimi` 会解析为 `kimi-cli`；`claude` 会解析为 `claude-code`。

## 默认目录规则

项目级安装路径：

| Agent | Skills directory |
| --- | --- |
| Codex | `.agents/skills` |
| OpenCode | `.agents/skills` |
| Kimi | `.agents/skills` |
| Claude Code | `.claude/skills` |
| Trae | `.trae/skills` |

Codex、OpenCode、Kimi 共享 `.agents/skills`。默认 symlink 模式会先把 Skill 放进 `.agents/skills`，再把非共享 agent 目录链接过去；使用 `--no-symlink` 可改为直接复制。

`sync` 会对共享 `.agents/skills` 的 agent 去重。请求 `codex opencode kimi` 时，只会写入一份 `.agents/skills` 内容。

## 添加自定义 Agent

命令行添加：

```bash
<spark> agent add my-agent \
  --label "My Agent" \
  --skills-dir ".my-agent/skills" \
  --global-skills-dir "~/.my-agent/skills" \
  --commands-dir ".my-agent/commands" \
  --global-commands-dir "~/.my-agent/commands" \
  --alias myagent
```

然后安装到它：

```bash
<spark> add skills/base --skill anysearch --agent my-agent --yes
```

查看配置：

```bash
<spark> agent list
<spark> agent schema
```

## 本地查询、下载和安装

查询本地 source 中有哪些 Skill：

```bash
<spark> add skills/base --list --silent
<spark> add skills/meta --list --silent
<spark> add .agents/skills --list --silent
```

从 GitHub 或远程 source 下载并安装：

```bash
<spark> add owner/repo --list
<spark> add owner/repo --skill skill-name --agent codex claude-code --yes
<spark> add https://github.com/owner/repo --agent codex --yes
```

只想预览远程 source 时使用 `--list`；真正下载并安装时去掉 `--list`。当前没有单独的 download-only 命令，`add` 会完成下载、发现、安装和写入 `skills.lock`。

## 标准配置文件

项目级配置文件是 `skill-spark.agents.json`，全局配置文件是 `~/.skill-spark/agents.json`。格式：

```json
{
  "version": "1",
  "agents": {
    "my-agent": {
      "label": "My Agent",
      "skillsDir": ".my-agent/skills",
      "globalSkillsDir": "~/.my-agent/skills",
      "commandsDir": ".my-agent/commands",
      "globalCommandsDir": "~/.my-agent/commands",
      "aliases": ["myagent"]
    }
  }
}
```

`label`、`skillsDir`、`globalSkillsDir` 必填；commands 目录可选。项目级配置优先于全局配置。

## 工作流

1. 用 AnySearch 或用户给定来源发现候选 Skill。
2. 用 `add <source> --list` 查看可安装项。
3. 用 `add` 或 `sync` 安装到目标 agent。
4. 用 `list` 和 `outdated --verbose` 检查 `skills.lock` 与实际目录。
5. 对远程 Git source 用 `update --yes` 更新；对本地 source 重新执行 `sync` 或 `add` 刷新。
6. 用 `remove <skill> --yes` 删除不用的 Skill。
7. 用 `doctor` 排查目录、lock 和 agent 检测问题。
