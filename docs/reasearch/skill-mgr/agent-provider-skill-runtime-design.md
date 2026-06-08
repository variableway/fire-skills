# Agent Provider 与 Skill Runtime 设计起点

调研日期：2026-06-08

## 1. 设计结论

不要从“选 Mastra 还是 OpenAI Agents SDK”开始。应该先设计两个稳定边界：

```text
Skill Runtime
  负责 Skill 的发现、解析、审查、安装、上下文打包、风险门禁、运行记录、评分和对比。

Agent Provider
  负责把 Task Packet 交给某个 AI 执行环境，并返回结构化结果、日志和证据。
```

这样产品不会被任何一个 agent 框架锁死。Mastra、OpenAI Agents SDK、Codex、Claude Code、LangGraph 都只是 `AgentProvider` 的不同实现。

第一版建议：

1. 先做 **Skill Runtime Core**，不依赖任何 LLM 框架。
2. 先实现 **manual/host provider**，让 Codex 或 Claude Code 作为宿主 Agent 执行 Task Packet。
3. 再加 **Mastra provider**，用于 query planning、research summarization、scoring。
4. 后续再加 **OpenAI Agents SDK provider**，用于 typed tools、guardrails 和 tracing。
5. 只有在需要 durable long-running workflow 时，再考虑 LangGraph/Temporal 类 runtime。

## 2. 核心边界

| 模块 | 拥有什么 | 不拥有 |
| --- | --- | --- |
| Skill Runtime | Skill registry、`skills.lock`、risk policy、task packet、run record、gate、score | 模型调用细节、agent memory、provider tracing |
| Agent Provider | 模型、agent 实例、tool calling、streaming、handoff、trace | Skill 安装、版本锁、安全策略最终裁决 |
| Tool Runtime | `git`、`gh`、filesystem、test command 等受控工具执行 | 自主决定是否越权执行 |
| Policy/Gate | 高风险动作审批、write boundary、token 权限建议 | 直接调用模型或写业务代码 |

最重要的原则：**权限和审计不能交给 LLM 自己保证**。Agent Provider 可以建议下一步，但 Skill Runtime 必须负责 gate、scope、record。

## 3. Provider 类型

### 3.1 Host Agent Provider

适合 Codex、Claude Code、Cursor 这类本地 coding agent。

特点：

- Agent 已经运行在用户工作区里。
- Runtime 不直接控制模型，只生成 Task Packet 和记录模板。
- 适合半自动、可审计的 MVP。

模式：

```text
Skill Runtime -> 写入 task-packet.md/json
用户/宿主 Agent -> 执行任务
Skill Runtime -> 记录 command/diff/test/github state
Skill Runtime -> score/compare
```

### 3.2 SDK Agent Provider

适合 Mastra、OpenAI Agents SDK、Vercel AI SDK。

特点：

- Runtime 可以直接创建 agent、注册 tools、拿到结构化输出。
- 适合自动化 research、inspect summary、scoring、低风险任务执行。
- 需要认真处理 tool guardrails、trace、成本和模型配置。

### 3.3 Durable Workflow Provider

适合 LangGraph、Temporal、Inngest 等。

特点：

- 适合长运行、可暂停、可恢复、human-in-the-loop 明确的流程。
- 不建议作为 MVP 起点，因为会显著增加状态和部署复杂度。

### 3.4 Manual Provider

适合第一天就可用。

特点：

- 不调用模型。
- 生成 checklist、命令建议、run log 模板。
- 用户或当前 Codex/Claude 会话手工执行。

## 4. Provider Capability Model

Provider 不应该只用字符串区分，而应该声明能力：

```typescript
export interface AgentProviderCapabilities {
  modelCalls: boolean;
  toolCalling: boolean;
  streaming: boolean;
  structuredOutput: boolean;
  handoffs: boolean;
  guardrails: boolean;
  tracing: boolean;
  humanInLoop: boolean;
  filesystemWrites: boolean;
  shellExecution: boolean;
  githubWrites: boolean;
  durableResume: boolean;
}
```

Runtime 根据能力决定是否允许某些 workflow 自动运行。例如：

- 没有 `guardrails` 的 provider 不允许自动执行 high-risk tool。
- 没有 `structuredOutput` 的 provider 只能进入半自动记录模式。
- 没有 `durableResume` 的 provider 不承担长时间 CI watch。
- 没有 `githubWrites` 的 provider 只能生成 PR/issue 建议，不执行写操作。

## 5. TypeScript 合同

### 5.1 Agent Provider

```typescript
export interface AgentProvider {
  id: string;
  label: string;
  kind: "host" | "sdk" | "durable" | "manual";

  capabilities(): AgentProviderCapabilities;

  prepare?(request: AgentPrepareRequest): Promise<AgentPrepareResult>;

  runTask(packet: TaskPacket, context: AgentRunContext): Promise<AgentRunResult>;

  resume?(runId: string, signal: AgentResumeSignal): Promise<AgentRunResult>;
  cancel?(runId: string, reason: string): Promise<void>;
}
```

### 5.2 Task Packet

Task Packet 是 Runtime 给 Agent 的最小上下文，不是完整历史。

```typescript
export interface TaskPacket {
  packetId: string;
  sessionId: string;
  problem: string;
  objective: string;
  selectedSkills: SelectedSkill[];
  taskFiles: string[];
  allowedRead: string[];
  allowedWrite: string[];
  approvalsRequired: ApprovalRequest[];
  verification: VerificationPlan;
  outputContract: AgentOutputContract;
}
```

### 5.3 Agent Result

```typescript
export interface AgentRunResult {
  runId: string;
  status: "done" | "blocked" | "failed" | "needs_approval";
  summary: string;
  artifacts: ArtifactRef[];
  commands: CommandEvidence[];
  filesChanged: string[];
  githubRefs: GitHubRef[];
  verification: VerificationResult;
  risks: RuntimeRisk[];
  next?: SuggestedNextAction[];
}
```

### 5.4 Skill Runtime

```typescript
export interface SkillRuntime {
  createSession(input: ProblemInput): Promise<SkillSession>;
  discover(sessionId: string, options: DiscoverOptions): Promise<CandidateSet>;
  inspect(sessionId: string, candidates: CandidateSet): Promise<InspectionReport>;
  select(sessionId: string, policy: SelectionPolicy): Promise<SkillSelection>;
  install(selection: SkillSelection, targets: AgentTarget[]): Promise<InstallReport>;
  buildTaskPacket(sessionId: string, options: TaskPacketOptions): Promise<TaskPacket>;
  run(packet: TaskPacket, provider: AgentProvider): Promise<AgentRunResult>;
  score(runId: string, rubric: Rubric): Promise<ScoreReport>;
  compare(leftRunId: string, rightRunId: string): Promise<CompareReport>;
}
```

## 6. Skill Runtime 内部模块

```text
runtime/
  session-store        # .skill-mgr/sessions/*
  source-manager       # local, registry, gh-skill, github-code-search
  skill-parser         # SKILL.md frontmatter/body/references/scripts
  inspector            # static rules + risk scoring
  selector             # ranking + policy
  installer            # 复用 skill-spark add/map/lock
  packet-builder       # Task Packet / allowed read/write / selected skills
  gate-manager         # Approval / write boundary / risky actions
  run-recorder         # JSONL events + command evidence + redaction
  scorer               # rule-based + optional LLM scorer
  reporter             # Markdown/JSON report
```

第一版必须保持 Runtime Core deterministic：不给它塞 LLM 调用。需要 LLM 的地方通过 provider 或 evaluator adapter 注入。

## 7. Provider 选择建议

| 场景 | 默认 Provider | 原因 |
| --- | --- | --- |
| 本地 coding 任务执行 | Host Codex / Host Claude Code | 用户已经在 coding agent 环境内，最少集成成本 |
| 候选 Skill 总结 | Mastra 或 OpenAI Agents SDK | 适合低风险 LLM summarization |
| 评分解释 | Mastra scorer / OpenAI structured output | 可和 rule score 结合 |
| 需要 tool guardrails | OpenAI Agents SDK | 官方 TS SDK 支持 tools、guardrails、tracing |
| Web/Next.js 产品界面 | Vercel AI SDK | provider-agnostic、streaming、UI 集成好 |
| 长时间审批/恢复 | LangGraph/Temporal | durable execution 和 human-in-the-loop 更合适 |

MVP 推荐顺序：

```text
manual-provider
  -> host-agent-provider
  -> mastra-research-provider
  -> openai-agents-provider
  -> durable-provider
```

## 8. Skill Runtime 执行流

### 8.1 Discover + Inspect

```text
problem
  -> query planner
  -> collect candidates
  -> preview SKILL.md
  -> inspect format/triggers/safety/portability
  -> rank
  -> recommendation.md
```

这部分可以完全不调用 Agent Provider。LLM query planner 是优化项，不是必需项。

### 8.2 Install + Packet

```text
selected skills
  -> pin source version
  -> install/map to target agent
  -> compute allowed read/write
  -> build task packet
  -> require approvals for risky actions
```

这里是 Skill Manager 相比普通 agent framework 的核心价值。

### 8.3 Run + Record

```text
task packet
  -> provider.runTask
  -> command evidence
  -> git diff summary
  -> GitHub issue/PR/checks state
  -> run record jsonl
```

Provider 可以执行，也可以只返回“需要宿主执行”的说明。Runtime 不应该假设所有 provider 都能自动完成任务。

### 8.4 Score + Improve

```text
run record
  -> rule score
  -> optional LLM judge
  -> compare with baseline
  -> skill improvement proposal
```

`improve` 第一版只生成 patch proposal，不自动改写和发布 Skill。

## 9. Gate 与 Tool Runtime

需要把工具执行从 Agent Provider 中拆出来。Agent 可以请求工具，但 Runtime/Tool Runtime 决定是否执行。

```typescript
export interface RuntimeTool<I, O> {
  name: string;
  risk: "read" | "write" | "destructive" | "external-write";
  inputSchema: unknown;
  invoke(input: I, context: ToolContext): Promise<O>;
}

export interface ApprovalGate {
  gateId: string;
  action: string;
  risk: "medium" | "high" | "critical";
  reason: string;
  status: "pending" | "approved" | "rejected" | "expired";
  approvedBy?: string;
  approvedAt?: string;
}
```

GitHub 本地开发场景的默认 gate：

| 动作 | Gate |
| --- | --- |
| 创建 issue | 可自动，需记录 |
| 创建分支 | 可自动，需记录 |
| 修改代码 | 受 write boundary 限制 |
| push branch | 需要 approval，除非 policy 允许 |
| 创建 PR | 需要 approval 或明确策略 |
| merge PR | 默认禁止自动 |
| close issue | 默认禁止自动，除非 PR 合并或用户批准 |
| 修改 `.github/workflows/**` | 高风险 gate |

## 10. 配置设计

项目根建议新增：

```json
{
  "schemaVersion": "1",
  "defaultProvider": "host:codex",
  "targetAgents": ["codex"],
  "sources": ["local", "registry", "gh-skill"],
  "policy": {
    "autoInstallMinScore": 85,
    "blockBelowScore": 70,
    "requireApproval": ["push", "create_pr", "close_issue", "modify_github_workflow"],
    "defaultWriteBoundary": ["docs/**", "src/**", "tests/**"],
    "redactSecrets": true
  },
  "providers": {
    "host:codex": { "kind": "host", "agent": "codex" },
    "mastra:research": { "kind": "sdk", "role": "research" },
    "openai:eval": { "kind": "sdk", "role": "scoring" }
  }
}
```

文件名可以是 `skill-mgr.config.json`，不要塞进 `package.json`。

## 11. 代码组织建议

```text
src/
  commands/
    discover.ts
    inspect.ts
    solve.ts
    eval.ts
  runtime/
    index.ts
    session-store.ts
    packet-builder.ts
    gate-manager.ts
    run-recorder.ts
    scorer.ts
    reporter.ts
  providers/
    types.ts
    manual-provider.ts
    host-provider.ts
    mastra-provider.ts
    openai-agents-provider.ts
  tools/
    git-tool.ts
    github-tool.ts
    shell-tool.ts
    filesystem-tool.ts
  policy/
    risk-rules.ts
    write-boundary.ts
    redaction.ts
  schemas/
    session.ts
    candidate.ts
    inspection.ts
    run-event.ts
```

保留现有 `core/` 作为包管理基础；新增 `runtime/` 和 `providers/`，避免把新 workflow 混进现有 install/search 逻辑。

## 12. 第一周应该写什么

不要第一周就接 Mastra。第一周写可测试的纯 TypeScript contracts：

1. `providers/types.ts`：定义 `AgentProvider`、capabilities、result。
2. `runtime/session-store.ts`：写 `.skill-mgr/sessions/<id>`。
3. `runtime/packet-builder.ts`：从 problem + selected skills 生成 Task Packet。
4. `runtime/run-recorder.ts`：写 JSONL 事件。
5. `providers/manual-provider.ts`：生成 checklist，不调用模型。
6. `commands/solve.ts`：把 discover/inspect/packet 串起来，先输出建议，不执行危险动作。

验收标准：

```bash
skill-spark solve "如何自动化本地开发的 GitHub 流程" --provider manual
```

能生成：

```text
.skill-mgr/sessions/<id>/problem.json
.skill-mgr/sessions/<id>/candidates.json
.skill-mgr/sessions/<id>/inspection.json
.skill-mgr/sessions/<id>/task-packet.md
.skill-mgr/sessions/<id>/recommendation.md
```

## 13. 第二阶段再接 Mastra

Mastra adapter 不要参与安装和权限。它只做 AI 增强：

```text
query planner
candidate summarizer
inspection explanation
eval scorer
improvement proposal
```

Provider 形态：

```typescript
export class MastraResearchProvider implements AgentProvider {
  id = "mastra:research";
  label = "Mastra Research Provider";
  kind = "sdk" as const;

  capabilities() {
    return {
      modelCalls: true,
      toolCalling: true,
      streaming: true,
      structuredOutput: true,
      handoffs: false,
      guardrails: false,
      tracing: true,
      humanInLoop: false,
      filesystemWrites: false,
      shellExecution: false,
      githubWrites: false,
      durableResume: false
    };
  }
}
```

这样 Mastra 即使替换掉，也不会影响 Runtime Core。

## 14. 设计风险

| 风险 | 解决方式 |
| --- | --- |
| Provider 抽象过度 | 先只支持 manual/host，再扩展 |
| LLM 绕过安全策略 | 所有 side effect 必须走 Runtime Tool + Gate |
| Skill 脚本任意执行 | inspect 阶段列出 scripts，默认不自动执行 |
| Run log 泄露 secret | 默认 redaction，敏感命令输出截断 |
| Eval 变成主观打分 | rule score 优先，LLM judge 只做解释 |
| Mastra 锁定 | 只作为 provider adapter，不进入 core types |
| Yorun 复杂度回流 | 只借概念，不引入其 CLI 协议 |

## 15. 参考资料

- [Mastra TypeScript AI Agent Framework](https://mastra.ai/)
- [Mastra Workflows](https://mastra.ai/workflows)
- [OpenAI Agents SDK TypeScript](https://openai.github.io/openai-agents-js/)
- [OpenAI Agents SDK Guardrails](https://openai.github.io/openai-agents-js/guides/guardrails/)
- [LangGraph JavaScript](https://docs.langchain.com/oss/javascript/langgraph)
- [Vercel AI SDK](https://vercel.com/ai-sdk)
- [GitHub CLI gh skill search](https://cli.github.com/manual/gh_skill_search)

## 16. 总结

设计起点不是“选择一个 Agent 框架”，而是先固定边界：

```text
Skill Runtime = deterministic governance and evaluation core
Agent Provider = replaceable execution backend
Tool Runtime = controlled side-effect layer
Policy/Gate = safety and approval layer
```

第一版用 manual/host provider 就能产品化；Mastra/OpenAI Agents SDK 是增强层。这样既能快速落地，又不会把 Skill Manager 变成另一个复杂、难上手的 Yorun。
