# 同步 Base Skills 到多个 AI Agent

本用例演示如何把项目内置的 `skills/base` 同步到 Codex、Claude Code、OpenCode、Trae、Kimi。AnySearch 已作为 base skill 放在 `skills/base/anysearch`，可用于实时搜索、网页抽取、垂直领域搜索，以及从问题出发发现相关 Skill。

如果要同步 meta skill，例如 `skill-creator`，请使用 `skills/meta` 作为 source。

## 当前能力

`skill-spark add` 已经支持按 agent 安装技能。项目级安装路径由 `src/core/agents.ts` 管理：

| Agent | Project skills directory |
| --- | --- |
| Codex | `.agents/skills` |
| Claude Code | `.claude/skills` |
| OpenCode | `.agents/skills` |
| Trae | `.trae/skills` |
| Kimi | `.agents/skills` |

Codex、OpenCode、Kimi 在项目级安装时共享 `.agents/skills`，因此只需要一份通用 Skill 内容即可被多个 agent 读取。

`sync` 当前会对共享目录去重。请求 `codex claude-code opencode trae kimi` 时，实际写入目标通常是：

- `.agents/skills`：Codex、OpenCode、Kimi 共享。
- `.claude/skills`：Claude Code。
- `.trae/skills`：Trae。

## 查看 Base Skills

```bash
./dist/skill-spark add skills/base --list --silent
```

期望能看到：

```text
skill:anysearch
skill:skill-spark
```

查看 meta skills：

```bash
./dist/skill-spark add skills/meta --list --silent
```

期望能看到：

```text
skill:skill-creator
```

## 用 `skill-spark add` 安装 AnySearch

这是 `skill-spark add` 的本地目录安装示例：

```bash
./dist/skill-spark add skills/base \
  --skill anysearch \
  --agent codex claude-code opencode trae kimi \
  --yes
```

说明：

- `skills/base` 是本地 source 目录。
- `--skill anysearch` 只安装 AnySearch。
- `--agent kimi` 会被解析为 `kimi-cli`。
- 项目级安装默认会使用 `.agents/skills` 作为通用目录，并为 Claude Code、Trae 写入各自目录。

## 一键同步全部 Base Skills

新增的 `sync` 命令是 `add` 的便捷批量版本，默认 source 为 `skills/base`，默认目标为 Codex、Claude Code、OpenCode、Trae、Kimi：

```bash
./dist/skill-spark sync --yes
```

显式写法：

```bash
./dist/skill-spark sync \
  --source skills/base \
  --agent codex claude-code opencode trae kimi \
  --yes
```

只同步 AnySearch：

```bash
./dist/skill-spark sync --source skills/base --skill anysearch --yes
```

同步 `skill-creator`：

```bash
./dist/skill-spark sync \
  --source skills/meta \
  --skill skill-creator \
  --agent codex claude-code opencode trae kimi \
  --yes
```

如果不希望使用从 `.agents/skills` 到其它 agent 目录的 symlink，可以改为直接复制：

```bash
./dist/skill-spark sync --source skills/base --skill anysearch --no-symlink --yes
```

## AnySearch 运行验证

查看 AnySearch CLI 文档：

```bash
bash skills/base/anysearch/scripts/anysearch_cli.sh doc
```

执行一次搜索：

```bash
bash skills/base/anysearch/scripts/anysearch_cli.sh search "agent skills SKILL.md github workflow" --max_results 3
```

抽取网页正文为 Markdown：

```bash
bash skills/base/anysearch/scripts/anysearch_cli.sh extract "https://example.com/article"
```

自然语言提示示例：

```text
请用 AnySearch 抽取这个页面的 Markdown，并总结核心观点：https://example.com/article
```

AnySearch 会请求 `https://api.anysearch.com/mcp`。不要用它搜索密钥、token、私有源码或个人隐私信息；如果需要更高限额，可通过环境变量配置 `ANYSEARCH_API_KEY`。

## 适合的产品流程

1. 用户从一个问题出发，例如“如何自动化本地开发的 GitHub 流程”。
2. Agent 使用 AnySearch 做实时搜索和 GitHub/文档调研。
3. Agent 总结候选 Skill、开源项目、文章和可复用脚本。
4. 使用 `skill-spark add` 安装单个 Skill，或使用 `skill-spark sync` 同步整个 `skills/base`。
5. 在 Codex、Claude Code、OpenCode、Trae、Kimi 中复用同一套 Skill，并通过实际任务评估效果。
