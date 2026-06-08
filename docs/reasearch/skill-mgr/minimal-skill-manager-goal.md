# Skill Manager 最小目标文档

日期：2026-06-08

## 1. 最小目标

构建一个最小可用的 AI Coding Agent Skill Manager，让用户从一个自然语言问题开始，得到一份可信的 Skill 推荐包。

最小目标一句话：

```text
输入一个开发问题，自动发现候选 Skill，检查质量和风险，输出推荐 Skill、安装建议和给 Agent 使用的 Task Packet。
```

示例：

```bash
skill-spark solve "如何自动化本地开发的 GitHub 流程" --provider manual
```

最小产物：

```text
.skill-mgr/sessions/<session-id>/
  problem.json
  search-plan.json
  candidates.json
  inspection.json
  recommendation.md
  task-packet.md
```

这个目标暂时不做自动执行、不接 Mastra、不自动修改 Skill、不自动 push/PR/close issue。第一版只解决一个核心问题：用户不知道该用哪个 Skill，也不知道这个 Skill 是否可信。

## 2. 为什么这个目标最小但有效

当前项目已有 `search/add/map/list/update/remove/doctor`，已经能做包管理。缺口在包管理之前和之后：

```text
之前：从一个问题找到高质量 Skill。
之后：把 Skill 变成可执行任务上下文，并留下评估入口。
```

因此 MVP-0 不需要先做完整 runtime，只需要补齐：

1. 问题到搜索计划。
2. 多来源候选收集。
3. `SKILL.md` 预览、解析和风险检查。
4. 推荐报告。
5. 面向 Agent 的最小 Task Packet。

只要这五步成立，就能验证产品方向，并为后续 `eval run`、Mastra provider、OpenAI Agents SDK provider 做接口准备。

## 3. 范围

### 3.1 本阶段包含

- 新增 `skill-spark solve <problem>`。
- 规则式 query planner。
- 聚合本地 skills、现有 registry、`gh skill search`。
- 候选去重和标准化。
- `SKILL.md` 预览和基础解析。
- 风险和质量评分。
- 推荐报告。
- Task Packet 生成。
- Manual Provider：只生成 checklist，不调用模型。

### 3.2 本阶段不包含

- 不自动驱动 Codex/Claude Code 完成开发任务。
- 不接 Mastra/OpenAI Agents SDK。
- 不做完整 A/B eval。
- 不自动安装推荐 Skill，最多输出安装命令。
- 不自动执行 GitHub 写操作。
- 不实现 Web UI。

## 4. 架构

```text
CLI
  skill-spark solve <problem>

Skill Runtime Core
  Session Store
  Query Planner
  Candidate Collector
  Skill Preview / Parser
  Inspector / Scorer
  Recommendation Builder
  Task Packet Builder
  Manual Provider

Existing skill-spark Core
  registry search
  local discovery
  add/map/lock
  agent directory config

External Sources
  local skill dirs
  skill-spark registry
  gh skill search
```

数据流：

```text
problem
  -> create session
  -> build search-plan.json
  -> collect candidates.json
  -> preview and inspect SKILL.md
  -> write inspection.json
  -> write recommendation.md
  -> write task-packet.md
```

## 5. 模块与任务

### 5.1 CLI Orchestrator

目标：提供一个用户入口，把所有步骤串起来。

文件建议：

```text
src/commands/solve.ts
```

需要内容：

- 解析 `problem`、`--sources`、`--target-agent`、`--provider`、`--out`。
- 创建 session。
- 调用 query planner、collector、inspector、reporter、packet builder。
- 在终端输出简洁结果。

实现任务：

1. 在 `src/index.ts` 注册 `solve <problem>` 命令。
2. 默认 `--provider manual`。
3. 默认 `--sources local,registry,gh`。
4. 成功后输出 session 路径和 Top 3 推荐。
5. 失败时给出缺失依赖提示，例如 `gh` 不可用时跳过 GitHub source。

验收：

```bash
bun src/index.ts solve "github local development workflow" --provider manual
```

能生成完整 session 文件。

### 5.2 Session Store

目标：保存一次问题驱动 Skill 搜索和审查过程。

文件建议：

```text
src/runtime/session-store.ts
```

需要内容：

- session id 生成。
- `.skill-mgr/sessions/<session-id>` 目录创建。
- JSON/Markdown 写入工具。
- session index 可选。

实现任务：

1. 生成 `YYYYMMDD-slug` 风格 session id。
2. 写入 `problem.json`。
3. 提供 `writeJson(name, data)` 和 `writeMarkdown(name, text)`。
4. 避免覆盖已有 session，冲突时追加序号。

验收：

```text
.skill-mgr/sessions/20260608-github-local-development-workflow/problem.json
```

存在且内容可读。

### 5.3 Query Planner

目标：把自然语言问题变成多个搜索查询。

文件建议：

```text
src/runtime/query-planner.ts
```

需要内容：

- 规则式关键词提取。
- 平台词：github、git、local、workflow、pr、issue、actions。
- 任务词：automation、development、review、release、test。
- Agent/Skill 词：skill、agent skill、codex、claude code。

实现任务：

1. 输入 problem，输出 query list。
2. 中英文问题都能生成英文查询。
3. 去重、限制数量，默认 6-10 个。
4. 写入 `search-plan.json`。

验收：

输入：

```text
如何自动化本地开发的 GitHub 流程
```

输出至少包含：

```text
github workflow
github local development workflow
github issue pull request automation
gh cli issue pr actions
agent skill github workflow
```

### 5.4 Candidate Collector

目标：从多个来源收集候选 Skill。

文件建议：

```text
src/runtime/candidate-collector.ts
src/runtime/sources/local-source.ts
src/runtime/sources/registry-source.ts
src/runtime/sources/gh-skill-source.ts
```

需要内容：

- 本地 `.agents/skills`、`.claude/skills`、Codex global skills 扫描。
- 复用现有 `searchRegistry`。
- 调用 `gh skill search --json skillName,description,repo,path,stars`。
- 统一候选格式。

实现任务：

1. 定义 `SkillCandidate` 类型。
2. 实现 local source。
3. 实现 registry source，复用 `src/core/registry.ts`。
4. 实现 gh source，`gh` 不存在时降级 warning。
5. 按 `source + repo + path + name` 去重。
6. 写入 `candidates.json`。

验收：

```bash
bun src/index.ts solve "github workflow" --sources gh
```

能从 `gh skill search` 得到候选，且候选中包含 repo/path/name。

### 5.5 Skill Preview / Parser

目标：拿到候选 Skill 的核心内容，供 inspect 使用。

文件建议：

```text
src/runtime/skill-preview.ts
src/runtime/skill-parser.ts
```

需要内容：

- local candidate：读取本地 `SKILL.md`。
- gh candidate：优先使用 `gh skill preview` 或 GitHub raw URL。
- registry candidate：如果只有 repo 信息，先记录 metadata；能下载时再预览。
- frontmatter 解析。
- scripts/references/assets 粗略识别。

实现任务：

1. 定义 `SkillPreview` 类型。
2. 解析 frontmatter 中的 `name`、`description`。
3. 提取 body 前 4000 字符作为 inspect 输入。
4. 提取 Markdown 中提到的 `scripts/`、`references/` 路径。
5. 预览失败不终止全流程，只在候选上标记 `preview_error`。

验收：

候选 inspect 中能看到：

```json
{
  "frontmatter": { "name": "github-workflow" },
  "scripts": [],
  "references": [],
  "preview_error": null
}
```

### 5.6 Inspector / Scorer

目标：对候选 Skill 做最小质量和风险评分。

文件建议：

```text
src/runtime/inspector.ts
src/runtime/risk-rules.ts
src/runtime/scorer.ts
```

需要内容：

- 相关性评分。
- 格式评分。
- 触发条件评分。
- 安全风险扫描。
- 可移植性评分。
- 推荐/谨慎/阻止三档决策。

最小评分：

```text
relevance 30
clarity 20
safety 25
portability 10
evaluability 15
```

实现任务：

1. 定义 risky patterns：`push --force`、`git reset --hard`、`gh issue close`、`gh pr merge`、`.github/workflows`。
2. 定义 trigger quality：是否有明确 use/skip 条件。
3. 定义 format quality：是否有 frontmatter name/description。
4. 输出 `inspection.json`。
5. 分数 >= 80 推荐；60-79 谨慎；< 60 不推荐；高危命中则 blocked。

验收：

`inspection.json` 至少包含：

```json
{
  "candidate_id": "...",
  "score": 84,
  "decision": "recommended",
  "risks": [],
  "install_command": "skill-spark add ..."
}
```

### 5.7 Recommendation Builder

目标：把机器评分变成人类能读懂的建议。

文件建议：

```text
src/runtime/recommendation-builder.ts
```

需要内容：

- Top 3 推荐 Skill。
- 每个推荐的理由。
- 风险和 gate 提醒。
- 安装命令。
- 不推荐候选及原因。

实现任务：

1. 按 score 排序。
2. 生成 `recommendation.md`。
3. 明确 “建议先安装哪个 Skill”。
4. 明确 “哪些动作需要人工确认”。

验收：

`recommendation.md` 能直接回答：

```text
应该装哪个 Skill？为什么？怎么装？有什么风险？下一步怎么让 Agent 用？
```

### 5.8 Task Packet Builder

目标：把推荐 Skill 和用户问题转成 Agent 可执行上下文。

文件建议：

```text
src/runtime/task-packet-builder.ts
```

需要内容：

- 任务目标。
- 推荐 Skill 列表。
- 允许读取路径。
- 建议写入边界。
- 需要人工审批的动作。
- 验证命令建议。
- 输出合同。

实现任务：

1. 生成 Markdown 版 `task-packet.md`。
2. 生成可选 JSON 版 `task-packet.json`。
3. 默认 provider 是 manual，不要求 Agent 自动执行。
4. 对 GitHub workflow 任务自动加入 gate：push、create PR、close issue、modify workflows。

验收：

`task-packet.md` 可以直接复制给 Codex/Claude Code 作为任务上下文。

### 5.9 Manual Provider

目标：提供最小 provider，不调用模型，不执行危险动作。

文件建议：

```text
src/providers/manual-provider.ts
src/providers/types.ts
```

需要内容：

- `AgentProvider` 类型。
- manual provider capabilities。
- 输出 checklist。

实现任务：

1. 定义 `AgentProvider`、`TaskPacket`、`AgentRunResult` 基础类型。
2. manual provider 返回 `needs_manual_execution`。
3. 生成执行 checklist，而不是运行 shell。

验收：

`--provider manual` 不调用模型、不改文件，只生成建议和 packet。

### 5.10 Config / Policy

目标：让默认行为可配置，但不过度设计。

文件建议：

```text
skill-mgr.config.json
src/runtime/config.ts
```

最小配置：

```json
{
  "defaultProvider": "manual",
  "sources": ["local", "registry", "gh"],
  "targetAgents": ["codex"],
  "policy": {
    "recommendMinScore": 80,
    "blockBelowScore": 60,
    "requireApproval": ["push", "create_pr", "close_issue", "modify_github_workflow"]
  }
}
```

实现任务：

1. 没有配置文件时使用默认值。
2. 支持读取项目根 `skill-mgr.config.json`。
3. CLI 参数覆盖配置。

验收：

不创建配置文件也能正常运行。

## 6. 可行性评估

整体可行性：高。

原因：

1. 当前 `skill-spark` 已有 registry search、agent directory config、add/map/lock 基础。
2. `gh skill search` 已能提供 public repo 中的 `SKILL.md` 候选。
3. MVP-0 不执行模型、不执行高风险命令，安全边界清晰。
4. 输出文件都是 JSON/Markdown，实现成本低，便于测试。
5. 结果能直接给当前 Codex/Claude Code 宿主使用。

主要风险和处理：

| 风险 | 处理 |
| --- | --- |
| 搜索结果噪音大 | 用 inspect score 排序，不直接安装 |
| `gh` 不存在或未登录 | 跳过 gh source，提示用户安装/登录 |
| registry 慢或失败 | source 级容错，不阻断 local/gh |
| 预览远程 Skill 失败 | 记录 `preview_error`，候选降权 |
| 安全规则误判 | 第一版宁可保守，输出人工确认建议 |
| 目标过大 | 本阶段不做自动执行和 A/B eval |

## 7. 实现任务清单

### Week 1：MVP-0

1. 新增目录结构：

```text
src/runtime/
src/runtime/sources/
src/providers/
```

2. 新增核心类型：

```text
src/runtime/types.ts
src/providers/types.ts
```

3. 实现 session store。
4. 实现 query planner。
5. 实现 local/registry/gh candidate collector。
6. 实现 skill preview/parser。
7. 实现 inspector/scorer。
8. 实现 recommendation builder。
9. 实现 task packet builder。
10. 实现 manual provider。
11. 注册 `solve` 命令。
12. 加 2-3 个单元测试或 fixture 测试。

### Week 2：可用性增强

1. 增加 `--json` 输出。
2. 增加 `--limit`、`--top`、`--sources`。
3. 增加 `skill-mgr.config.json`。
4. 改进 GitHub workflow 专项风险规则。
5. 增加 `recommendation.md` 模板。
6. 增加 README quickstart。

### Week 3：评估入口

1. 新增 `eval plan`，基于 task packet 生成 eval plan。
2. 新增 `eval record` 或 `eval run --manual`，记录手工执行事件。
3. 新增 `eval score`，规则评分。
4. 新增 `eval compare`，比较 baseline 和 skill run。

## 8. 验收标准

### 功能验收

运行：

```bash
bun src/index.ts solve "如何自动化本地开发的 GitHub 流程" --provider manual
```

应生成：

```text
problem.json
search-plan.json
candidates.json
inspection.json
recommendation.md
task-packet.md
```

### 内容验收

`recommendation.md` 必须说明：

1. 推荐的 Top Skill。
2. 推荐理由。
3. 安装命令。
4. 风险提醒。
5. 下一步如何让 Agent 使用。

`task-packet.md` 必须说明：

1. 任务目标。
2. 应加载的 Skill。
3. 读写边界。
4. 需要人工确认的动作。
5. 验证命令建议。
6. 期望输出。

### 质量验收

1. 没有 `gh` 时不崩溃。
2. registry 失败时不崩溃。
3. 没有任何自动 push、PR、issue close 行为。
4. 所有输出可复现到 session 目录。
5. TypeScript 类型检查通过。

## 9. 后续扩展路径

MVP-0 之后再逐步扩展：

```text
MVP-0: trusted skill recommendation package
MVP-1: manual eval record and compare
MVP-2: host provider for Codex/Claude Code task handoff
MVP-3: Mastra provider for query planning and scoring
MVP-4: OpenAI Agents SDK provider for guarded tool execution
MVP-5: team policy and CI eval
```

每一步都应保持 Runtime Core 的确定性边界，避免把安全策略交给 LLM provider。

## 10. 最终目标文档总结

本阶段的完整目标不是“做一个自动 Agent 平台”，而是先完成一个最小、可信、可验证的 Skill Manager 核心：

```text
从问题开始，生成可信 Skill 推荐包。
```

这个目标包括：

1. 搜索计划。
2. 候选收集。
3. Skill 解析。
4. 风险审查。
5. 推荐报告。
6. Task Packet。

完成它之后，项目就具备一个清晰产品入口，也具备后续接入 eval、provider、Mastra、OpenAI Agents SDK 的稳定基础。
