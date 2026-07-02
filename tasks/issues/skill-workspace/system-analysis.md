# Skill Workspace 系统分析

日期：2026-06-25  
输入：`tasks/issues/skill-workspace/ideas.md`

## 1. 结论

这个方向可行，而且不需要从零开始。当前仓库已经具备第一阶段的核心底座：`skill-spark` CLI 可以搜索 registry/directory、从 Git/本地/well-known 下载 source、发现 `SKILL.md`、安装到 `.agents/skills` 或不同 agent 目录、维护 lock、update/remove/list/map/sync。

更准确的定位应该是：

```text
Skill Workspace = SkillOps CLI + 本地 Skill Library + 可视化客户端 + Agent/Workflow Runtime Adapter
```

推荐路线：

1. 第一阶段继续改当前仓库，优先把 `skill-spark` 做成稳定的 headless core 和 CLI。
2. 第二阶段在当前仓库新增 `apps/desktop` 或 `apps/web`，不要另起一个完全独立仓库。
3. Workflow 编排先做 adapter，不要直接 fork Dify/n8n。Dify/n8n 适合作为外部 workflow provider 或设计参考，不适合作为 skill workspace 的核心底座。
4. 外部仓库里，最值得参考的是 `vercel-labs/skills`、`agentskills/agentskills`、`cloudflare/agent-skills-discovery-rfc`、`Kilo-Org/kilo-marketplace`。如果一定要直接改一个外部仓库，`powroom/flins` 最容易；但对当前项目来说，直接改本仓库最省力。

## 2. 目标拆解

原始想法分两阶段。

第一阶段：

- 收集 Skill、marketplace search、下载。
- 安装、验证 Skill。
- 可组合地安装到本地运行，或安装到不同项目中。

第二阶段：

- 客户端扫描 Skill 目录，并在页面展示使用。
- 客户端中运行 Skill。
- Skill Lib 可供不同 AI Agent 使用，同时也有自己的 AI Agent。
- 结合 Dify、n8n 等 workflow 工具做编排和测试。

建议把它重新定义为四层架构：

```text
Sources / Marketplace
  GitHub repo, registry API, skills.sh, flins directory, well-known endpoint, local dirs

Skill Library Core
  discover, parse, validate, inspect, score, install, lock, update, remove

Agent Runtime Adapters
  Codex, Claude Code, OpenCode, Cursor, Gemini, Kilo, custom agent dirs

Client / Workflow Layer
  UI, run sessions, logs, approvals, Dify/n8n/Flowise adapters
```

## 3. 当前仓库现状

当前仓库已经不是空白 workspace，而是一个正在向 Skill Workspace 演进的 monorepo 雏形。

已有能力：

- CLI 入口：`packages/skill-cli/src/index.ts`，包含 `search/find/add/update/outdated/remove/list/validate/inspect/use/profile/map/sync/agent/doctor`；`src/index.ts` 保留为兼容 shim。
- source 下载：`packages/skill-core/src/sources.ts` 支持 Git、local、well-known discovery，并做 archive 安全检查。
- source provider 边界：`packages/skill-core/src/source-providers.ts` 已抽象 local、well-known、flins directory、Git。
- skill 发现：`packages/skill-core/src/discovery.ts` 递归查找 `SKILL.md` 和 `commands/*.md`。
- 安装映射：`packages/skill-core/src/installations.ts` 通过 `.agents/skills` 做 canonical copy，再 symlink/copy 到目标 agent。
- 多 agent 目录：`packages/skill-core/src/agents.ts` 已覆盖 Codex、Claude Code、OpenCode、Cursor、Gemini、Kilo、Trae、Qwen、Goose 等大量目录。
- registry：`packages/skill-core/src/registry.ts` 使用 `https://skillsdirectory.com/api/registry`。
- lock/update：`skills.lock` 与 `packages/skill-core/src/state.ts`、`packages/skill-core/src/tracked.ts`。
- 共享 schema：`packages/skill-schemas/src/index.ts` 提供 frontmatter、validation、inspection、profile、run session 等 Zod schemas。
- 本地 skill 库：`skills/` 下已有 16 个 `SKILL.md`。
- 已有研究文档：`docs/reasearch/skill-mgr/*` 已经定义过 Skill Runtime、Agent Provider、solve/discover 的方向。

本地检查：

- 当前工作区已有文档更新、`find-skills.mjs`、`skills/skill-shared/` 等未提交内容，后续实现时不要回退这些已有改动。
- `typecheck` 已修复为 `tsc --noEmit`，`pnpm run check`、`pnpm run typecheck`、`pnpm run build`、CLI smoke tests 当前验证通过。

## 4. 可行性判断

### 4.1 第一阶段可行性：高

原因：

- 当前 CLI 已经覆盖 60%-70% 功能。
- Agent Skills 规范已经成熟，核心格式就是 `SKILL.md` + frontmatter + optional resources。
- well-known discovery 的 v0.2.0 模型已经被当前代码部分实现。
- 多 agent 目录适配已经存在，且本仓库比 `flins` 支持更多自定义 agent 配置能力。

当前第一阶段应收束为 Phase 0-1：先让 CLI 底座可信可改，再补齐 search/find、validate、profile/use 这些会直接影响日常使用的能力。`inspect` 不应作为 Phase 0 的硬门槛。

Phase 0 硬交付：

- 修复 `typecheck` 工具链。
- 确认 CLI build/bin 方式，避免正式发布时直接依赖 `src/index.ts`。
- 为 `SKILL.md` parsing 改用稳定 YAML parser。
- 增加 `validate <path-or-source>`，做确定性格式校验。
- 梳理 local/Git/well-known/registry 的统一 `SourceProvider` 接口，先以 adapter 方式包住现有 `sources.ts`。
- 建立第一版 monorepo 包边界：`packages/skill-cli`、`packages/skill-core`、`packages/skill-schemas`。
- 补齐 interactive CLI 主路径：无 query 时进入交互式 search/browse，安装时清楚展示 source、skill、target agent、symlink/copy。

Phase 0 暂缓项：

- `src/core/*` 和 `src/commands/*` 的系统性最小测试不再补到旧 `src/`；现在 package 边界已经形成，下一步直接补 `packages/skill-core`、`packages/skill-schemas`、`packages/skill-cli` 的最小测试。
- full `inspect` 暂缓。先实现 `validate`，再做 `inspect-lite`。

Phase 1 主要缺口：

- `validate`：按 Agent Skills spec 校验 `name`、`description`、目录名、frontmatter、引用文件、脚本风险。
- `inspect-lite`：只做 deterministic 静态检查，例如脚本、网络、环境变量、二进制、写文件范围、潜在 secret。它可以复用 `apps/skill-feed-manager/scripts/scan-skills.mjs` 里已有的风险信号思路，但要迁入 TS core。
- `inspect --via-skill`：可选增强，用一个 `skill-inspector` skill 生成解释型报告。这个模式只能作为 advisory report，不能代替 deterministic gate。
- `compose`：组合安装或 Skill bundle/profile，例如 `profile github-devops = git-workflow + github-cli + scanning-for-secrets`。
- `marketplace cache`：将搜索结果落地缓存，避免每次依赖外部 API。
- `use`：无需安装，直接把一个 skill 临时 materialize 成 prompt/context 给 Codex/Claude 使用。

`find-skills.mjs` 当前判断：

- 它不是 Phase 0 必需文件。当前运行 `node find-skills.mjs github --json` 会失败，因为缺少 `yaml` 依赖；它还假设存在 `data/sources.yaml` 和 `data/manifest.json`，当前仓库没有这些文件。
- 它有参考价值：统一 local/API/CLI source 的想法可以迁入 `skill-spark find/search`。
- 正式 goal 开始前需要确认是否保留 `.mjs`。默认建议是不保留为正式入口，而是把有用逻辑迁入 TypeScript CLI；`.mjs` 只作为 prototype/archive。

CLI 框架选择判断：

- `oclif` 不算过时，但它更偏传统和重型。它适合需要外部插件生态、复杂 command discovery、长期独立发行的大型 CLI；但当前 Skill Workspace 更像 monorepo 内部多个 package 组合出的 agent/workspace CLI，未必需要 oclif 的完整框架成本。
- Kimi Code 的依赖结构更值得借鉴：它是现代 agent CLI，但仍使用 `commander` 做命令解析、`zod` 做 runtime validation，并配合专用 TUI 包实现交互体验。
- 因此推荐目标架构从 `oclif + Ink + Zod` 调整为 **`commander + zod + TUI layer`**。
- TUI layer 有两个候选：优先评估 `@earendil-works/pi-tui`，因为它面向 agent CLI/TUI；备选 `Ink`，因为 React 心智模型和生态更熟。
- `@clack/prompts` 仍可保留给简单 confirm/select，但复杂的 `find` browse、profile wizard、inspect review、run monitor 应迁到 TUI layer。
- `Zod` 负责所有 runtime validation：CLI flags/options、`SKILL.md` frontmatter、source config、lockfile、profile、run session、provider 输出都用 schema 做 parse/gate。
- 如果未来明确要第三方命令插件生态，再重新评估 oclif。Phase 0-1 不建议先引入 oclif。
- 发布层面要调整：`package.json` 当前 bin 指向 `./src/index.ts`，开发可用，但正式发布应指向构建产物，例如 `dist/index.js` 或编译后的单文件可执行。

Kimi Code 可借鉴点：

- `commander`：继续作为轻量 command parser；monorepo 并不天然要求 oclif。
- `zod`：必须引入，作为 schema gate 的核心。
- `@earendil-works/pi-tui`：值得作为 Ink 的替代方案评估，尤其适合 agent CLI 的状态化终端界面。
- `tsx`：开发期直接运行 TypeScript，比当前 Bun 直跑 TS 更接近 Node/npm 生态发布；是否替换 `bun packages/skill-cli/src/index.ts` 可后续评估。
- `pathe`：跨平台路径工具，可用于 source/agent 目录解析。
- `smol-toml`：如果后续支持 TOML 配置，可以考虑；当前 JSON/YAML 已够用，不急。
- `semver`：用于 skill/source/profile 版本约束。
- `chalk` / `cli-highlight`：可替代 `picocolors` 或用于更好的代码/Markdown preview；不是 Phase 0 必需。
- `yazl`：用于打包 skill/profile archive，可放到 package/export 阶段。
- `postject`：只在做 Node SEA/原生可执行文件时有用，Phase 0 不需要。

`references-projects/zli` 可借鉴点：

- `zli` 的价值是把 CLI option/args 与 Zod schema 绑定，帮助形成“命令入口解析，command/core 边界验证”的习惯。
- 当前不建议从 `commander` 迁移到 `zli`，因为现有命令、别名、子命令、help 已经由 `commander` 稳定承载。
- 可以借鉴 `zli` 的类型安全姿势：每个命令入口都尽快 normalize raw options，再交给 Zod schema 或明确的 command option 类型。

CreateCLI skill 可借鉴点：

- LobeHub 上的 `danielmiessler/personal_ai_infrastructure-createcli` 适合作为 CLI 命令设计和质量标准参考，不适合作为直接驱动本项目开发的 active skill。
- 可借鉴 CLI-first、`--help`、JSON/Markdown 输出、exit code、TypeScript gate、README/quickstart 这些质量要求。
- 不建议迁入 PAI/Claude 私有路径、voice notification 或个人工作流绑定。

`@earendil-works/pi-tui` 详细判断：

- 它是 TUI layer，不是 CLI framework。命令解析仍应由 `commander` 负责，`pi-tui` 只在 TTY interactive 子流程中启动。
- 它的核心抽象是 `TUI + Component`：组件实现 `render(width): string[]` 和可选 `handleInput(data)`，适合把复杂交互拆成可测试的 screen/component。
- 它有现成组件能覆盖 Phase 0-1：`Input` 做搜索框，`SelectList` 做 skill/source 选择，`SettingsList` 做 profile/settings wizard，`Markdown` 做 `SKILL.md` 和 inspect report 预览，`CancellableLoader` 做可取消下载/验证，`Overlay` 做详情面板。
- 它重视中文/东亚宽度、IME、CJK wrapping、ANSI width、终端图片和 OSC 8 链接等终端细节。这对中文用户和 agent CLI 很有价值。
- 它依赖少，npm 包当前只有 `get-east-asian-width` 和 `marked` 两个运行依赖；但要求 Node `>=22.19.0`，这会影响发布策略。
- 它迭代很快，API 可能变化。采用时应 pin 具体版本，先做一两个 prototype screen，不要一次性把所有 interactive 命令绑死。
- 它不是 React/JSX 心智模型，开发体验更接近手写 class/component。团队如果更熟 React，Ink 仍是备选。
- 非交互/CI 场景必须绕开 TUI：所有命令都需要 `--json`、`--yes`、`--no-interactive` 等 headless path。
- 本地参考仓库已放到 `references-projects/pi`，重点看 `packages/tui` 和 `packages/coding-agent` 中 TUI 的实际接入方式。

建议先用 `pi-tui` 做两个验证屏幕：

1. `find` browse：输入 query，选择 source，列表展示 name/description/source/risk，右侧或 overlay 预览 `SKILL.md` metadata。
2. `validate` review：显示 validation report、warnings/errors、引用文件缺失、风险信号，并允许导出 JSON/Markdown。

如果这两个屏幕体验稳定，再扩展到 `profile wizard` 和 `run monitor`。

### 4.2 第二阶段可行性：中高

客户端展示扫描目录是容易的，难点在“客户端中运行 Skill”。Skill 本质是 agent instruction package，不是普通插件函数。运行它有三种模式：

1. Host Agent 模式：客户端生成 task packet，让 Codex/Claude Code 执行。
2. SDK Agent 模式：客户端内置 OpenAI Agents SDK / Mastra / Vercel AI SDK，由系统直接调用模型和工具。
3. Workflow 模式：把 Skill 当成 workflow node 的配置/上下文，交给 n8n/Dify/Flowise。

推荐 MVP 先做 Host Agent + Manual Provider：客户端负责选择 skill、生成 task packet、记录日志、展示结果；真正执行由宿主 agent 完成。这样权限、安全、成本都容易控制。

### 4.3 最大风险

- 安全：Skill 可携带脚本和说明，运行时可能请求 shell、网络、GitHub 写权限。必须有 risk gate 和用户确认。
- 标准不稳定：Agent Skills 和 well-known discovery 都在演进，schema 要做版本兼容。
- 搜索质量：marketplace 搜索不能只看关键词，需要解析 `SKILL.md`，做质量分和风险分。
- 运行语义：不同 agent 对 skill 的加载机制不完全一样，不能假设所有 agent 都像 Codex/Claude。
- UI 误导：客户端如果说“运行 Skill”，用户会以为它像插件一样可执行。产品文案应区分“安装/加载/生成任务包/交给 agent 执行”。

## 5. 推荐架构

### 5.1 目录建议

保持当前仓库，并从现在开始按 monorepo 演进。第一版 package 边界已经落地：

```text
packages/
  skill-core/              # discover/parse/validate/inspect/install/lock
  skill-schemas/           # Zod schemas for skills, sources, lock, profiles, runs
  skill-cli/               # commander command shell + TUI interactive screens
  skill-runtime/           # task packet, sessions, run logs, providers
  marketplace-client/      # registry, skills.sh, flins, GitHub, well-known adapters

apps/
  web/                     # 扫描/搜索/安装/运行记录 UI
  desktop/                 # 可选，Tauri/Electron 包装 web + local daemon

skills/
  base/
  devops/
  meta/
  sdlc/

.skill-workspace/
  cache/
  sessions/
  profiles/
```

迁移顺序与当前状态：

1. 已完成：保留 `src/index.ts` 兼容入口，实际导入 `packages/skill-cli/src/index.ts`。
2. 已完成：新建 `packages/skill-schemas`，沉淀 frontmatter、source、validation、inspection、profile、run session schemas。
3. 已完成：新建 `packages/skill-core`，迁入 parsing、discovery、source provider、validate、inspect、install/map/lock/update core。
4. 已完成：新建 `packages/skill-cli`，继续使用 commander 做 command shell，并把命令实现拆成独立 modules。
5. 待做：在 `packages/skill-cli/src/ui/` 放 TUI 交互界面，优先评估 `@earendil-works/pi-tui`，备选 Ink；先实现 `find` browse 和 `validate/inspect` review。
6. 待做：给 `skill-core`、`skill-schemas` 和 `skill-cli` 补最小测试。
7. 待做：新增 `apps/web` 或 `apps/desktop` 客户端，复用 package public API。

已决定现在开始 monorepo，因此不再建议继续向旧 `src/` 增加正式模块。旧单包替代方案只保留为历史参考：

```text
src/runtime/
  session-store.ts
  skill-parser.ts
  validator.ts
  inspector.ts
  composer.ts
  packet-builder.ts
  providers/
    manual-provider.ts
    host-agent-provider.ts

src/marketplace/
  registry-source.ts
  github-source.ts
  well-known-source.ts
  local-source.ts
```

### 5.2 核心数据模型

```typescript
interface SkillPackage {
  id: string;
  name: string;
  description: string;
  source: SkillSourceRef;
  version?: string;
  license?: string;
  compatibility?: string;
  metadata?: Record<string, unknown>;
  files: SkillFileRef[];
  validation: ValidationResult;
  risk: RiskSummary;
  quality: QualitySummary;
}

interface SkillProfile {
  name: string;
  description: string;
  skills: Array<{ name: string; source: string; version?: string }>;
  targetAgents: string[];
  policy: RuntimePolicy;
}

interface SkillRunSession {
  sessionId: string;
  objective: string;
  selectedSkills: SkillPackage[];
  provider: "manual" | "host-codex" | "host-claude" | "mastra" | "n8n" | "dify";
  status: "draft" | "ready" | "running" | "needs_approval" | "done" | "failed";
  artifacts: string[];
  logs: string[];
}
```

## 6. 功能路线

### Phase 0：整理现有 CLI

目标：让当前底座可信可改。

- 修复 `typecheck` 工具链。
- 修复/明确 `bin` 指向：开发入口优先用 `bun packages/skill-cli/src/index.ts`，`bun src/index.ts` 仅作为兼容 shim；发布入口使用 `dist/index.js` 或编译后的可执行文件。
- 引入 `zod`，建立第一批 schemas：`SkillFrontmatterSchema`、`SourceRefSchema`、`ValidationReportSchema`。
- 把 local/Git/well-known/registry source 抽象成统一 `SourceProvider` 接口；Phase 0 可以只定义接口和 adapter，不做大规模迁移。
- 为 `SKILL.md` parsing 改用稳定 YAML parser，减少手写 YAML 边界问题。
- 增加 `validate <path>`。
- 确认 CLI 目标栈：`commander + zod + TUI layer`。新增复杂 interactive 命令优先按 TUI screen 边界设计。
- 强化 interactive 主流程：`search/find` 无 query 进入 TUI browse；`add` 可短期保留 clack multiselect；新增命令优先支持 `--json` 和 `--yes`，便于脚本化。
- 暂不补旧 `src/core/*`、`src/commands/*` 系统测试；package 边界已经形成，下一步优先测试 `packages/skill-schemas`、`packages/skill-core` 和 `packages/skill-cli`。

### Phase 1：Skill Workspace CLI MVP

目标：完成 ideas 第一阶段。

- `search/find`：统一 marketplace 搜索，支持 registry、skills.sh、flins directory、local、GitHub code search、well-known。
- `download/cache`：下载但不安装，存入 `.skill-workspace/cache`。
- `validate`：格式和引用验证。
- `inspect-lite`：质量分、风险分、可移植性分；先规则化，后续再加 `--via-skill` 解释报告。
- `profile`：组合 skill，安装到不同项目或 agent。
- `use`：不安装直接生成 prompt/task packet。
- `solve`：从自然语言问题找到候选 skill，生成推荐报告。这个方向已有 `docs/reasearch/skill-mgr/minimal-skill-manager-goal.md` 可直接接上。

### Phase 2：Web/桌面客户端

目标：完成目录扫描和页面展示。

- 本地 daemon：提供 `GET /skills`、`POST /install`、`POST /validate`、`POST /inspect`、`POST /run-packet`。
- UI 页面：Library、Marketplace、Installed、Profiles、Runs、Settings。
- 扫描目录：`.agents/skills`、`.claude/skills`、`~/.codex/skills`、自定义目录。
- 展示：名称、描述、来源、安装位置、目标 agent、risk、quality、last updated。
- 操作：install/remove/update/validate/inspect/profile/use。

### Phase 3：运行与编排

目标：客户端中“运行 Skill”，但必须有清晰权限边界。

- Manual Provider：生成 task packet 和 checklist。
- Host Codex/Claude Provider：打开/发送任务给宿主 agent，记录结果。
- SDK Provider：用 OpenAI Agents SDK 或 Mastra 执行低风险 inspect/summarize/scoring。
- n8n/Dify Adapter：将 skill run session 作为 workflow node 输入/输出。
- Eval：对同一个问题用不同 skill/profile 对比结果。

## 7. GitHub 参考仓库

以下仓库均在 2026-06-25 查询过 GitHub 元数据。

| 仓库 | 作用 | 参考价值 | 是否适合直接改 |
| --- | --- | --- | --- |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) | open agent skills CLI，`npx skills` | CLI 体验、`use` 命令、find/search、测试覆盖、多 agent 支持 | 中。功能成熟但结构与当前项目不同，适合借实现，不建议 fork 后大改 |
| [powroom/flins](https://github.com/powroom/flins) | universal skill/command manager | 与当前仓库最接近，当前 `skill-spark` 明显已吸收其设计 | 高。如果要直接改外部仓库，它最方便；但更建议继续改当前仓库 |
| [agentskills/agentskills](https://github.com/agentskills/agentskills) | Agent Skills 规范和 reference validator | `SKILL.md` spec、progressive disclosure、验证规则 | 低。它是规范仓库，不是产品底座 |
| [cloudflare/agent-skills-discovery-rfc](https://github.com/cloudflare/agent-skills-discovery-rfc) | well-known discovery 草案 | marketplace/discovery endpoint、digest、archive 安全 | 低。只参考协议，不适合直接改 |
| [Kilo-Org/kilo-marketplace](https://github.com/Kilo-Org/kilo-marketplace) | Skills/MCP/Agents marketplace | marketplace.yaml、release tar.gz、分类、suggest_for、生成脚本 | 中低。适合做内容市场参考，不适合作为 CLI/runtime 底座 |
| [anthropics/skills](https://github.com/anthropics/skills) | 官方/公共 example skills | 高质量 skill 内容和结构样例 | 低。适合导入/索引/学习，不适合改成 workspace |
| [cli/cli](https://github.com/cli/cli) | GitHub CLI，包含 `gh skill` 生态入口 | GitHub skill 搜索/安装生态可参考 | 低。Go 大仓，改造成本高 |
| [langgenius/dify](https://github.com/langgenius/dify) | agentic workflow 平台 | 插件、工作流、运行记录、UI 设计参考 | 低。不建议 fork 成 skill workspace |
| [n8n-io/n8n](https://github.com/n8n-io/n8n) | workflow automation | node 编排、credentials、执行历史、社区节点 | 低。不建议直接改；适合做 adapter |
| [FlowiseAI/Flowise](https://github.com/FlowiseAI/Flowise) | visual AI agent builder | 可视化 agent/workflow 构建体验 | 低。适合参考 UI/流程，不适合直接改 |

## 8. 哪个仓库直接修改更方便

排序如下：

1. 当前仓库 `fire-skills`：最方便。原因是已有 `skill-spark`、本地 skills、研究文档、任务目录、个人需求上下文；当前虽有未提交改动，但都是围绕本方向的上下文或草案。
2. `powroom/flins`：外部仓库中最方便。代码规模小，TypeScript/Bun，功能与当前第一阶段高度重合。
3. `vercel-labs/skills`：产品成熟度最高，但不如 `flins` 轻。适合借 `use`、`find`、provider registry、测试用例；直接 fork 改会遇到上游节奏和差异化定位问题。
4. `Kilo-Org/kilo-marketplace`：适合改成内容市场，不适合作为本地 workspace/runtime。
5. Dify/n8n/Flowise：不建议直接改。它们的抽象是 workflow/app builder，不是 skill package manager。直接 fork 会让 scope 过大。

因此建议：

```text
直接修改当前仓库。
借鉴 vercel-labs/skills 的 CLI/use/find/test。
保留 flins 兼容性或迁移经验。
采用 agentskills spec 和 Cloudflare well-known RFC。
借 Kilo marketplace 的内容索引格式。
对 Dify/n8n 做 adapter，而不是 fork。
```

## 9. 近期实现优先级

### P0：已完成底座可验证

- `pnpm run typecheck` 已修复为 `tsc --noEmit`。
- `bin.skill-spark` 已从 `src/index.ts` 改为构建产物 `dist/index.js`。
- 已落地第一版 monorepo：`packages/skill-cli`、`packages/skill-core`、`packages/skill-schemas`，根 `src/index.ts` 仅保留为兼容 shim。
- 已引入 `zod` 和 `yaml`。
- `SKILL.md` frontmatter 解析已迁到稳定 YAML parser。
- 已新增第一批 schemas：`SkillFrontmatterSchema`、`SourceRefSchema`、`ValidationReportSchema`、`InspectionReportSchema`、`SkillProfileSchema`、`SkillRunSessionSchema`。
- 已新增 `SourceProvider` adapter 边界：local、well-known、flins directory、Git。
- 已新增 `validate <path-or-source>`，覆盖 `SKILL.md`、frontmatter、name/description、目录名、引用文件和 portability warning。
- archive path traversal、symlink、archive size 等安全检查继续由 source 下载/解包层阻断。
- CLI 目标栈已确认并落地为 `commander + zod`；复杂 TUI 仍保留为 `pi-tui` 后续试点。

### P1：已完成第一版 CLI MVP

- `skill-spark find/search` 已支持 local、registry、directory/flins source 和 JSON/Markdown 输出。
- `skill-spark inspect <source-or-path> --mode rules` 已输出 risk/quality/portability report。
- `skill-spark profile add/list/show/install` 已支持最小组合 skill profile。
- `skill-spark use <source> --skill <name>` 已生成 task packet/prompt，不安装也能使用。
- `inspect --via-skill` 尚未实现，保留为未来 advisory report 入口。
- `find-skills.mjs` 仍不是正式入口；其 source 聚合思路已经部分迁入 TypeScript `find/search`。

### P1 后续增强

- `find` 接入 `skills.sh`、GitHub code search、well-known 批量发现和本地 cache。
- `profile install` 增加 `--project`，避免依赖 cwd 切换。
- `validate` 增加更完整的 Agent Skills spec 兼容规则和 JSON schema 导出。
- `inspect` 增加可配置 risk policy、更多 secret/网络/写文件规则，并支持 `--via-skill` advisory report。
- `use` 增加 host-agent adapter 输出，例如 Codex/Claude 可直接消费的 task packet。
- 以 `pi-tui` 试点 `find` browse 和 `validate/inspect` review screen。
- 为 `packages/skill-core`、`packages/skill-schemas`、`packages/skill-cli` 补最小测试。

### P2：客户端 MVP

- 本地 API daemon 封装 CLI/core。
- Web UI 扫描本地目录和 cache。
- Installed/Marketplace/Profile/Run 四个主页面。
- Run 先只支持 manual/host agent task packet。

### P3：workflow adapter

- `export --format n8n`：生成 n8n node/workflow JSON。
- `export --format dify`：生成 Dify tool/workflow 配置草案。
- `run --provider n8n|dify` 先只做外部调用和结果记录。

## 10. 建议 MVP 验收

第一阶段验收：

```bash
pnpm run typecheck
pnpm run check
pnpm run build
bun packages/skill-cli/src/index.ts find "github workflow" --sources local --format json --output /tmp/skill-spark-find-local.json
bun packages/skill-cli/src/index.ts validate skills/devops/git-workflow --format json
bun packages/skill-cli/src/index.ts inspect skills/devops/git-workflow --mode rules --format markdown
bun packages/skill-cli/src/index.ts profile add github-devops --source skills --skill git-workflow github-cli --agent codex --force
bun packages/skill-cli/src/index.ts profile list
bun packages/skill-cli/src/index.ts use skills/devops --skill git-workflow --objective "close stale GitHub issues"
./dist/index.js --help
```

第二阶段验收：

```text
打开客户端 -> 扫描本地 skills -> 搜索 marketplace -> 安装一个 profile -> 生成 run task packet -> 记录执行结果。
```

## 11. 最终建议

这个项目值得做，且当前仓库就是最好的起点。不要一开始就做完整客户端和 workflow engine；先把 `skill-spark` 从“安装工具”升级为“Skill Workspace Core”。等 validate/inspect/profile/use/solve 稳定后，再做 UI，会自然很多。

最小下一步：

1. 接入 `pi-tui` 试点 `find` browse 和 `validate/inspect` review。
2. 为 `find` 增加更多 source：skills.sh、GitHub code search、well-known 批量发现和 cache。
3. 明确 `find-skills.mjs` 去留，默认迁入 TS CLI 后归档。
4. 为 `packages/skill-core`、`packages/skill-schemas`、`packages/skill-cli` 补最小测试。
5. 继续扩展 `inspect` risk policy、`profile --project`、`use` host-agent adapter。
6. 再新增 `packages/marketplace-client`、`packages/skill-runtime` 和 `apps/web|desktop`。
