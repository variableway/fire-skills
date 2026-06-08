# Skill Spark 当前 Skills 与 CLI 状态

本文记录当前仓库中已经实现并验证的 Skill Spark 能力，以及 `skills/base`、`skills/meta` 的使用方式。

## 当前核心 Skills

| Skill | 路径 | 作用 |
| --- | --- | --- |
| AnySearch | `skills/base/anysearch` | 实时搜索、垂直搜索、批量搜索、网页 Markdown 抽取，适合作为发现和调研入口。 |
| skill-spark | `skills/base/skill-spark` | 管理 Skill 的安装、同步、lock、agent 目录、update/remove/doctor。 |
| skill-creator | `skills/meta/skill-creator` | 创建、改进、评估 Skill；已结合 SkillOpt 方法作为优化参考。 |

`skills/base` 放基础可复用能力，`skills/meta` 放用于创建、管理、优化 Skill 的 meta skill。

## CLI 入口

优先使用已构建的可执行文件：

```bash
./dist/skill-spark --help
```

如果 `dist/skill-spark` 不存在，先构建：

```bash
bun run build:all
```

fallback：

```bash
node dist/index.js --help
bun src/index.ts --help
```

## 当前命令实现状态

| 命令 | 当前状态 | 说明 |
| --- | --- | --- |
| `search` | 已实现 | 使用 registry/directory 搜索；AnySearch provider 尚未接入 CLI。 |
| `add` | 已实现 | 支持 local source、Git source、well-known source；支持 `--list`、`--agent`、`--skill`、`--global`、`--no-symlink`。 |
| `sync` | 已实现 | 默认 source 为 `skills/base`；支持 local/remote source；对共享 `.agents/skills` 的 agent 会去重。 |
| `list` | 已实现 | 从 `skills.lock` 和全局 lock 读取安装记录，并显示有效安装位置。 |
| `outdated` | 已实现 | 本地 source 记录为 `local`；远程 Git source 用 `git ls-remote` 检查 commit。 |
| `update` | 已实现最小可用 | 对远程 Git outdated 项重新下载、重装到当前已有安装位置，并更新 lock commit；本地 source 仍建议用 `sync` 或 `add` 刷新。 |
| `remove` | 已实现 | 按名称删除项目/全局安装记录和匹配安装目录。 |
| `agent` | 已实现 | 支持 `list`、`list --json`、`schema`、`add`、`remove`。 |
| `doctor` | 已实现基础诊断 | 显示 root、常见目录、lock、检测到的 agent。 |
| `map` | legacy 可用 | 用于旧式目录映射；`--universal` 当前读取 `.agents/skills`。 |

## 当前目录规则

项目级安装路径：

| Agent | Skills directory | Commands directory |
| --- | --- | --- |
| Codex | `.agents/skills` | - |
| OpenCode | `.agents/skills` | `.opencode/commands` |
| Kimi | `.agents/skills` | - |
| Claude Code | `.claude/skills` | `.claude/commands` |
| Trae | `.trae/skills` | - |

Codex、OpenCode、Kimi 共享 `.agents/skills`。`sync` 会把这类共享目录去重，所以请求五个 agent 时，实际项目级 skill 安装目标通常是三类：`.agents/skills`、`.claude/skills`、`.trae/skills`。

## 安装和同步当前核心 Skills

查看 base skills：

```bash
./dist/skill-spark add skills/base --list --silent
```

查看 meta skills：

```bash
./dist/skill-spark add skills/meta --list --silent
```

同步全部 base skills 到常用 agent：

```bash
./dist/skill-spark sync \
  --source skills/base \
  --agent codex claude-code opencode trae kimi \
  --yes
```

同步 `skill-creator`：

```bash
./dist/skill-spark sync \
  --source skills/meta \
  --skill skill-creator \
  --agent codex claude-code opencode trae kimi \
  --yes
```

只安装单个 Skill：

```bash
./dist/skill-spark add skills/base --skill anysearch --agent codex claude-code --yes
./dist/skill-spark add skills/base --skill skill-spark --agent codex --yes
./dist/skill-spark add skills/meta --skill skill-creator --agent codex --yes
```

## lock 与生命周期

```bash
./dist/skill-spark list
./dist/skill-spark outdated --verbose
./dist/skill-spark update --yes
./dist/skill-spark remove anysearch --yes
./dist/skill-spark doctor
```

`skills.lock` 记录 `type:name`、scope、source URL、branch、commit。本地 source 会记录为：

```json
{
  "url": "local:/absolute/path/to/skills/base",
  "branch": "local",
  "commit": "local"
}
```

本地 source 没有远程 commit，内容刷新建议直接重新执行 `sync` 或 `add`。远程 Git source 才适合使用 `outdated/update` 做 commit 级更新。

## 已修复的确定性问题

- `discoverInstallables` 已支持 `description: >-` 和 `description: |` 这类多行 YAML frontmatter。
- `sync` 已对共享 `.agents/skills` 的 agent 进行目标目录去重。
- `map --universal` 已从旧的 `.agent/skills` 修正为 `.agents/skills`。
- `update` 已从占位实现补成远程 Git source 的最小重装流程。

## 仍需注意

- `search --provider anysearch` 尚未实现；当前 AnySearch 作为 Skill 和脚本使用，不是 CLI search provider。
- `doctor` 是基础诊断，不是完整健康检查。
- 本地 source 的更新不走 `update`，请用 `sync` 或 `add`。
- `remove` 当前按 Skill 名称清理所有匹配项目/全局安装，不支持只移除某一个 agent 目标。
