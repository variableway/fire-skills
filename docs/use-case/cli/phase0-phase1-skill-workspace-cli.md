# Skill Workspace CLI Phase 0-1 Use Case

日期：2026-06-26

## 目标

把当前 `skill-spark` 从“能安装 skill 的 CLI”整理成 Phase 0-1 可依赖的 Skill Workspace CLI。

Phase 0 关注：

- 工具链可验证。
- `SKILL.md` 解析稳定。
- `zod` schema gate 明确。
- CLI 交互路径清楚。
- `validate` 可做确定性 gate。
- source provider 边界明确。

Phase 1 关注：

- `find/search` 覆盖更多 marketplace/source。
- `inspect-lite` 输出规则化质量和风险报告。
- `profile` 支持组合安装。
- `use` 支持不安装也能生成 task packet/prompt。

## 当前实现状态

已实现：

- `typecheck` 已从不可用的 `tsgo --noEmit` 改为 `tsc --noEmit`。
- `bin.skill-spark` 已指向构建产物 `dist/index.js`，开发入口优先使用 `bun packages/skill-cli/src/index.ts`。
- 已引入 `zod` 和 `yaml`。
- `SKILL.md` frontmatter 解析已从手写 YAML 迁移到稳定 YAML parser。
- 已新增 Zod schemas：frontmatter、source ref、validation report、inspection report、profile、run session。
- 已新增 `SourceProvider` adapter 边界：local、well-known、flins directory、Git。
- 已新增 `validate <path-or-source>`。
- 已新增 `inspect <path-or-source> --mode rules`，即 inspect-lite。
- 已新增 `find`，当前支持 `local`、`registry`、`directory/flins` source。
- 已新增 `profile add/list/show/install` 的最小组合安装能力。
- 已新增 `use <path-or-source>`，可生成不安装的 task packet。
- 已完成第一版 monorepo 拆分：`packages/skill-cli` 承载 CLI，`packages/skill-core` 承载 discovery/source/validate/inspect，`packages/skill-schemas` 承载共享 Zod schema。
- 根目录 `src/index.ts` 现在是兼容 shim，实际开发入口是 `packages/skill-cli/src/index.ts`。

尚未实现或仍是后续增强：

- `inspect --via-skill` 只保留为明确未实现的未来入口，不能作为 gate。
- `find` 还没有接入 `skills.sh`、GitHub code search、well-known 批量发现。
- `profile install` 当前没有 `--project` 参数，默认在当前工作目录执行安装。
- TUI 层尚未接入 `pi-tui`；当前 interactive 仍以 `@clack/prompts` 为主。
- `src/core/*` 和 `src/commands/*` 已迁入 package 边界；系统性测试是下一步，不再在单包 `src/` 下新增。

## 当前可用命令

开发入口：

```bash
bun packages/skill-cli/src/index.ts --help
bun src/index.ts --help
```

`bun src/index.ts` 是兼容入口；新增开发和测试应优先使用 `packages/skill-cli/src/index.ts`。

构建入口：

```bash
bun run build:all
./dist/index.js --help
# 或使用编译后的可执行文件
./dist/skill-spark --help
```

搜索 registry/directory：

```bash
bun src/index.ts search "github" --output docs/use-case/search/github-skills.json --format json
bun src/index.ts search "workflow automation" --output docs/use-case/search/workflow-automation.md --format markdown
```

无 query 时进入当前 interactive search/browse：

```bash
bun src/index.ts search
```

查看 source 中有哪些可安装项：

```bash
bun src/index.ts add skills/base --list --silent
bun src/index.ts add skills/devops --list --silent
bun src/index.ts add owner/repo --list
```

安装到项目级通用目录和指定 agent：

```bash
bun src/index.ts add skills/devops --skill git-workflow --agent codex claude-code --yes
```

同步本地 skills 到多个 agent：

```bash
bun src/index.ts sync --source skills/base --agent codex claude-code opencode trae kimi --yes
```

查看、更新、移除：

```bash
bun src/index.ts list
bun src/index.ts outdated --verbose
bun src/index.ts update --yes
bun src/index.ts remove git-workflow --yes
```

## Phase 0 已实现命令

修复工具链：

```bash
pnpm run typecheck
pnpm run check
```

`typecheck` 当前使用 `tsc --noEmit`。

建立 schema gate：

```bash
# frontmatter、validation report、inspection report、profile、run session 已有 zod schema
bun packages/skill-cli/src/index.ts validate skills/devops/git-workflow --format json
```

第一批 schema：

- `SkillFrontmatterSchema`
- `SourceRefSchema`
- `ValidationReportSchema`
- `SkillProfileSchema`
- `SkillRunSessionSchema`

验证单个 skill：

```bash
bun src/index.ts validate skills/devops/git-workflow
bun src/index.ts validate .agents/skills/thought-distiller --format json
```

验证 source 中所有 skill：

```bash
bun src/index.ts validate skills/devops --all
bun src/index.ts validate owner/repo --skill git-workflow
```

验证输出应至少包含：

- 是否存在 `SKILL.md`。
- frontmatter 是否可解析。
- `name` 是否符合 Agent Skills 命名规则。
- `description` 是否存在且非空。
- `name` 是否与目录名一致，或者给出 warning。
- 引用文件是否存在。
- markdown 引用是否存在；引用离开 skill 目录时给出 portability warning。
- archive/source path traversal、symlink、archive size 等风险仍在 source 下载/解包层阻断。

## Phase 1 已实现命令

统一 find/search：

```bash
bun src/index.ts find "github workflow" --sources local,registry,directory
bun src/index.ts find "github workflow" --sources local --format json --output .skill-workspace/search/github-workflow.json
bun src/index.ts find "github workflow" --interactive
```

当前 `find` 的 `--sources` 支持 `local`、`registry`、`directory`，`flins` 会映射为 `directory`。

规则化 inspect：

```bash
bun src/index.ts inspect skills/devops/git-workflow --mode rules --format markdown
bun src/index.ts inspect owner/repo --skill github-workflow --mode rules --format json
bun src/index.ts inspect skills/devops/git-workflow --mode rules --fail-on high
```

`inspect` 第一版使用 `--mode rules`，等价于 inspect-lite。它只做 deterministic report，不调用模型。

可选 skill 辅助解释：

```bash
skill-spark inspect skills/devops/git-workflow --via-skill skill-inspector
```

这个模式当前未实现；未来只生成解释型报告，不能替代 `validate` 或 rules gate。

组合 profile：

```bash
bun src/index.ts profile add github-devops \
  --source skills \
  --skill git-workflow \
  --skill github-cli \
  --skill scanning-for-secrets

bun src/index.ts profile list
bun src/index.ts profile show github-devops
bun src/index.ts profile install github-devops --agent codex claude-code --yes
```

`profile install` 当前在当前工作目录执行安装；需要指定目标项目时先切换 cwd，后续再补 `--project`。

## 当前 Monorepo 布局

当前已从单包 `src/` 迁到第一版 monorepo package 边界：

```text
packages/skill-cli
  commander command shell
  src/commands/*
  src/utils/*

packages/skill-core
  agents/discovery/sources/source-providers
  skill-parser/validation/inspection
  install/map/lock/update core

packages/skill-schemas
  shared zod schemas

src/index.ts
  compatibility shim -> packages/skill-cli/src/index.ts
```

根项目使用 pnpm workspace：`pnpm-workspace.yaml` 声明 `packages/*`，根 `package.json` 声明 `packageManager: pnpm@11.5.2`。内部 package 依赖使用 pnpm 支持的 `workspace:*` 协议，锁文件为 `pnpm-lock.yaml`。

当前验证命令：

```bash
pnpm install
pnpm run typecheck
pnpm run check
bun run build
bun packages/skill-cli/src/index.ts --help
./dist/index.js --help
```

不安装直接使用：

```bash
bun src/index.ts use skills/devops --skill git-workflow --objective "close stale GitHub issues" --format markdown
bun src/index.ts use owner/repo --skill github-workflow --agent codex --format json
```

## Interactive CLI 判断

当前 `commander + @clack/prompts` 方案中，`commander` 可以继续作为长期 command parser；`Zod` 作为验证层已经确认；`@clack/prompts` 更适合保留为简单 prompt 辅助，不适合承载复杂状态化交互。

monorepo 目标方案建议：

- `commander` 负责 command parser：命令注册、flags、help、子命令调度。
- `Zod` 负责 runtime validation：CLI options、frontmatter、source config、lockfile、profile、run session。
- TUI layer 负责 interactive terminal UI：find browse、profile wizard、inspect review、run monitor。
- TUI layer 优先评估 `@earendil-works/pi-tui`，备选 Ink。
- `picocolors` 只保留给非 interactive 的轻量输出。

这样分层后，一个 CLI 可以组合多个 package，而不是把所有命令堆在一个 `src/index.ts`：

```text
packages/skill-cli
  commander command shell
  commands/find.ts
  commands/validate.ts
  commands/profile.ts
  ui/find-browser.ts         # pi-tui or Ink
  ui/profile-wizard.ts       # pi-tui or Ink

packages/skill-core
  discover/parse/validate/source-provider

packages/skill-schemas
  zod schemas shared by CLI, core, web, runtime

packages/marketplace-client
  registry/skills-sh/flins/well-known/github sources
```

交互流应从一开始按 TUI screen 设计：

```text
search/find 无 query
  -> 输入关键词
  -> 选择 source
  -> 选择 skill
  -> preview SKILL.md metadata
  -> add / validate / inspect / use

add source
  -> discover installables
  -> multiselect skills/commands
  -> 选择 target agents
  -> 展示 summary
  -> confirm
```

CLI 框架备选：

| 方案 | 适合度 | 判断 |
| --- | --- | --- |
| `commander + Zod + pi-tui` | 推荐优先评估 | 接近 Kimi Code 现代 agent CLI 路线，轻量、可控、适合 monorepo 内部组合 |
| `commander + Zod + Ink` | 推荐备选 | React 心智模型和生态更熟，适合复杂 UI，但依赖和渲染模型更重 |
| `commander + clack + Zod` | 迁移期可用 | 适合简单 prompt，不适合复杂 browse/review/run monitor |
| `oclif + Ink + Zod` | 暂不优先 | 不是过时，而是更偏传统和重型；除非明确需要第三方插件生态和大型 CLI lifecycle |
| `Ink only` | 不推荐 | Ink 是 UI renderer，不是完整 command framework |

如果正式 goal 是“从一开始框架好一点”，建议以 `commander + Zod + TUI layer` 为目标：保留 commander，尽快引入 zod，并选 `pi-tui` 或 Ink 来承载复杂交互。

Kimi Code 依赖中可借鉴：

- `commander`：轻量 command parser，monorepo 不必天然上 oclif。
- `zod`：schema gate，必须借鉴。
- `@earendil-works/pi-tui`：优先评估的 TUI 方案。
- `tsx`：开发期运行 TS，比直接依赖 Bun 更容易贴近 Node/npm 生态。
- `pathe`：跨平台路径处理。
- `semver`：skill/source/profile 版本约束。
- `smol-toml`：如需 TOML config 再引入。
- `yazl`：后续 skill/profile 打包导出可用。
- `postject`：仅在做 Node SEA/原生可执行文件时考虑，Phase 0 不需要。

`zli` 参考结论：

- `references-projects/zli` 的核心价值是“Zod 驱动的 CLI option/args validation”范式。
- 当前项目不迁移到 `zli`，因为 `commander` 已经足够承载命令注册、help、别名和子命令。
- 可以继续借鉴 `zli` 的做法：命令入口只做解析，真正的 schema gate 放到 command/core 边界。

CreateCLI skill 参考结论：

- LobeHub 上的 `danielmiessler/personal_ai_infrastructure-createcli` 适合作为 CLI 命令设计和质量标准参考，不适合作为直接执行的 active skill。
- 已借鉴的方向：CLI-first、`--help` 明确、JSON/Markdown 输出、清晰 exit code、TypeScript 类型检查、命令边界可组合。
- 不直接采用的部分：PAI/Claude 私有路径、voice notification、本地个人工作流绑定。

`@earendil-works/pi-tui` 的具体判断：

- 它更像 TUI runtime，而不是 CLI framework。命令线仍然该交给 `commander`，而不是让 TUI 包同时负责 command parsing。
- 它的优势不在“能不能画界面”，而在于把 `Input`、`SelectList`、`SettingsList`、`Markdown`、`CancellableLoader`、`Overlay` 这些交互部件做成了可组合的基础块。
- 它适合 `find`、`validate`、`profile`、`inspect` 这类需要状态化交互的流程，尤其是列表选择、详情预览、确认弹层、取消下载/验证。
- 它对 IME、CJK 宽度、同步输出、焦点恢复、硬件光标这些细节处理得比较完整，比较适合中文环境的终端交互。
- 它有 Node `>=22.19.0` 的门槛，意味着如果当前 CLI 的发布基线更低，需要单独评估运行时要求。
- 本地参考仓库已经放到 `references-projects/pi/packages/tui`，后续要看交互实现可以直接对照 `packages/coding-agent` 的用法。

## find-skills.mjs 判断

`find-skills.mjs` 当前不是正式入口。

当前问题：

- 运行 `node find-skills.mjs github --json` 会因为缺少 `yaml` package 失败。
- 脚本假设存在 `data/sources.yaml` 和 `data/manifest.json`，当前仓库没有这两个文件。
- 它的 usage 写的是 `node scripts/find-skills.mjs`，但文件实际位于仓库根目录。

建议：

- 正式 goal 开始前确认是否必须保留 `.mjs`。
- 默认不保留为正式 CLI 入口。
- 把它的 local/API/CLI source 聚合思路迁入 TypeScript `skill-spark find/search`。
- 迁移完成后，将 `.mjs` 移入 prototype/archive，或删除。

## Monorepo 后的测试顺序

`src/core/*` 和 `src/commands/*` 已经迁入 package 边界。最小测试不再补到旧 `src/`，下一步直接围绕 package public API 和 CLI 命令补。

建议顺序：

```text
packages/skill-schemas tests
  -> packages/skill-core tests
  -> packages/skill-cli command smoke tests
  -> TUI screen smoke tests
```

优先测试对象：

- `skill-schemas`：Zod schema parse、错误消息、JSON schema 兼容性。
- `skill-core`：frontmatter parser、source resolver、discover、validate。
- `skill-cli`：commander command parse、JSON 输出、非交互 `--yes` 流程、TUI screen smoke tests。
- `apps/web`：只做 scan 数据契约测试，不阻塞 CLI Phase 0。

## 验收标准

Phase 0 验收：

```bash
pnpm run typecheck
pnpm run check
pnpm run build
bun packages/skill-cli/src/index.ts search
bun packages/skill-cli/src/index.ts add skills/devops --list --silent
bun packages/skill-cli/src/index.ts validate skills/devops/git-workflow --format json
./dist/index.js --help
```

Phase 1 验收：

```bash
bun packages/skill-cli/src/index.ts find "github workflow" --sources local --format json --output /tmp/skill-spark-find-local.json
bun packages/skill-cli/src/index.ts inspect skills/devops/git-workflow --mode rules --format json
bun packages/skill-cli/src/index.ts profile add smoke-profile --source skills --skill git-workflow github-cli --agent codex --force
bun packages/skill-cli/src/index.ts profile list
bun packages/skill-cli/src/index.ts profile show smoke-profile
bun packages/skill-cli/src/index.ts use skills/devops/git-workflow --objective "close stale GitHub issues" --format json --output /tmp/skill-spark-use.json
```

当前验证结果：`typecheck`、`check`、`build`、`validate`、`inspect`、`find`、`profile add/list/show`、`use`、`dist/index.js --help` 已跑通。
