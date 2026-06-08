# Skill Spark 作为 SkillOps CLI

AnySearch 适合做实时搜索、网页 Markdown 抽取和资料发现；Skill Spark 负责把发现到的 Skill 变成可安装、可同步、可追踪、可更新、可删除的本地资产。

当前实现状态详见：`docs/use-cases/skill-spark-current-skills-cli.zh-CN.md`。

## 定位

| 任务 | 工具 |
| --- | --- |
| 实时搜索、网页抽取、GitHub/文章发现 | AnySearch |
| 安装 Skill | Skill Spark |
| 同步到 Codex/Claude Code/OpenCode/Trae/Kimi | Skill Spark |
| 管理不同 agent 的目录差异 | Skill Spark |
| lock/list/outdated/update/remove/doctor | Skill Spark |
| 添加自定义 agent 目录配置 | Skill Spark |

当前仓库核心 Skills：

| Skill | 目录 | 作用 |
| --- | --- | --- |
| AnySearch | `skills/base/anysearch` | 搜索、网页抽取、资料发现。 |
| skill-spark | `skills/base/skill-spark` | 安装、同步、lock、agent 目录和生命周期管理。 |
| skill-creator | `skills/meta/skill-creator` | 创建、优化、评估 Skill 的 meta skill。 |

## 安装和同步

先构建可运行文件：

```bash
bun run build:all
```

后续命令优先使用：

```bash
./dist/skill-spark --help
```

查看本地 base skills：

```bash
./dist/skill-spark add skills/base --list --silent
```

安装指定 Skill：

```bash
./dist/skill-spark add skills/base \
  --skill anysearch \
  --agent codex claude-code opencode trae kimi \
  --yes
```

同步整个 base skills：

```bash
./dist/skill-spark sync \
  --source skills/base \
  --agent codex claude-code opencode trae kimi \
  --yes
```

同步 meta skill：

```bash
./dist/skill-spark sync \
  --source skills/meta \
  --skill skill-creator \
  --agent codex claude-code opencode trae kimi \
  --yes
```

## 管理 lock/update/remove

```bash
./dist/skill-spark list
./dist/skill-spark outdated --verbose
./dist/skill-spark update --yes
./dist/skill-spark remove anysearch --yes
./dist/skill-spark doctor
```

`skills.lock` 记录 Skill 来源、scope、branch、commit。本地 source 会记录为 `local:<path>`，远程 Git source 会记录 commit，便于后续检查更新。

注意：本地 source 的内容刷新建议重新执行 `sync` 或 `add`；`update` 当前主要用于远程 Git source 的 commit 级更新。

## 添加自定义 Agent

通过 CLI 添加：

```bash
./dist/skill-spark agent add my-agent \
  --label "My Agent" \
  --skills-dir ".my-agent/skills" \
  --global-skills-dir "~/.my-agent/skills" \
  --commands-dir ".my-agent/commands" \
  --global-commands-dir "~/.my-agent/commands" \
  --alias myagent
```

然后可以直接安装：

```bash
./dist/skill-spark add skills/base --skill anysearch --agent my-agent --yes
```

## 标准配置格式

项目级配置文件：`skill-spark.agents.json`

全局配置文件：`~/.skill-spark/agents.json`

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

查看当前支持的 agent 和标准格式：

```bash
./dist/skill-spark agent list
./dist/skill-spark agent list --json
./dist/skill-spark agent schema
```

## 推荐闭环

1. 用 AnySearch 从问题出发搜索候选 Skill 或资料。
2. 用 Skill Spark `add --list` 检查 source 中有哪些可安装项。
3. 用 `add` 或 `sync` 安装到目标 agent。
4. 用 `list/outdated/doctor` 检查安装状态和目录差异。
5. 用 `remove` 做清理；远程 Git source 用 `outdated/update` 做更新，本地 source 用 `sync/add` 刷新。
