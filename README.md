# skill-spark（innate-spark-cli）

`skill-spark` 是一个 **SkillOps CLI**：面向 AI coding agent 的 skill 安装、同步与治理工具（安装 / 移除 / 校验 / 风险检查 / 多 agent 目录映射 / registry 扫描克隆 / 自托管 SMB 挂载等）。

本仓库是 `innate-spark` hub 中唯一允许放代码的位置（见 hub 根目录 `AGENTS.md`），以独立 git 仓库形式嵌在 `tools/innate-spark-cli/` 下。

## 工程形态：Bun monorepo

- 运行时与包管理均为 **Bun**（`packageManager: bun@1.3.11`），workspace 通过根 `package.json` 的 `workspaces` 字段声明，锁文件为 `bun.lock`。
- 源码即 TypeScript，直接以 `bun <entry>.ts` 运行，无需预编译；发布产物构建到 `dist/`（已 gitignore）。

| 包 | 说明 |
| --- | --- |
| `packages/skill-cli` | CLI 入口（commander 命令注册、各子命令实现） |
| `packages/skill-core` | 核心逻辑：skill 发现、来源下载解包、安装、校验、agent 目录映射 |
| `packages/skill-schemas` | 共享 Zod schema |
| `packages/tool-docx` | `.docx` → Markdown 转换（mammoth） |

其余目录：`skills/`（本地 skill 源，`base/` + `meta/`）、`docs/`（文档站源，docmd 构建）、`config.json`（selfhost SMB 配置）、`.github/workflows/docs.yml`（GitHub Pages 文档部署）。

## 开发

```bash
bun install            # 安装依赖，生成 bun.lock

bun run dev            # 以源码运行 CLI（= bun packages/skill-cli/src/index.ts）
bun test               # 运行测试
bun run typecheck      # tsc --noEmit
bun run build:all      # 构建 dist/index.js（bundle）+ dist/skill-spark（单文件可执行）
bun run format         # biome format
bun run check          # biome check
```

在 hub 根目录（`innate-spark/`）使用的惯用方式：

```bash
SPARK="bun tools/innate-spark-cli/packages/skill-cli/src/index.ts"
$SPARK registry scan
```

或直接使用构建出的单文件二进制 `tools/innate-spark-cli/dist/skill-spark`。

## CLI 命令总览

命令按 `packages/skill-cli/src/index.ts` 实际注册列出；详细用法见 `docs/cli/`（各命令一页）。

| 命令 | 说明 |
| --- | --- |
| `search [query]`（`s`） | 从 registry / 目录搜索 skill，支持交互式浏览、JSON/Markdown 输出 |
| `find [query]` | 跨本地、registry、目录三源查找（默认全开） |
| `add <source>`（`a` / `install` / `i`） | 安装一个来源的全部 skill 到检测到的 agent 目录（`-g` 全局、`-a --agent` 指定 agent、`-f` 跳过确认） |
| `remove [skills...]`（`r` / `rm` / `uninstall`） | 移除已安装 skill；无参数按 scope 全清（global / project / `--path`） |
| `register <source>`（`reg`） | 仅登记外部 skill 来源，不安装 |
| `generate agents-md` | 生成 `AGENTS.md` 供 agent 做 skill 发现 |
| `list`（`l`） | 列出已安装 skill（`~/.skill-spark/skills.lock` 与 `./skills.lock`） |
| `validate <path-or-source>` | 校验 SKILL.md 结构、元数据、引用与基础文件安全（`--all` / `-s` / `--strict`） |
| `inspect <path-or-source>` | 规则式风险与质量检查（`--fail-on low|medium|high|critical`） |
| `map` | 把已安装 skill 映射到目标 agent 目录（gemini / claude / codex / agent / qwen） |
| `sync` | 从源目录同步 skill 到各 agent 的 skill 目录（默认源 `skills/base`，默认 agent：codex、claude-code、opencode、trae、kimi-cli；默认 symlink，`--no-symlink` 改复制） |
| `agent list / schema / add / remove` | 管理目标 agent 目录配置（`agents` 别名；自定义配置写 `skill-spark.agents.json` 或 `~/.skill-spark/agents.json`） |
| `doctor` | 诊断 skill-spark 环境与 agent 目录 |
| `docx-to-md -s <in.docx> -o <out.md>` | 转换 `.docx` 为 Markdown |

### registry 子命令

扫描 / 克隆 registry YAML 中登记的 git 仓库（hub 侧的配套约定见 hub 根目录 `AGENTS.md` 的 "Registry contract"）。

```bash
skill-spark registry scan          # 目录内容 → tools/registry/apps.yaml（read → merge → write）
skill-spark registry scan-refs     # → sibling innate-works/registry.yaml
skill-spark registry clone         # 按 apps.yaml 克隆 / 拉取
skill-spark registry clone-refs    # 按 works registry 克隆
```

布局解析顺序：命令行 `--config` → 环境变量 `REGISTRY_CLI_CONFIG` / `REGISTRY_CLI_HUB_ROOT` / `REGISTRY_CLI_WORKS_ROOT` / `REGISTRY_CLI_WORKS_NAME` / `REGISTRY_CLI_APPS_ROOT` → 从当前目录向上查找 `.innate-registry-cli.yaml`（或 `registry-cli.yaml`）。通用 flag：`--depth`、`--keep-missing`、`--regenerate`（重建并丢弃手工扩展字段）。

### selfhost 子命令（macOS SMB）

```bash
skill-spark selfhost profiles --config config.json
skill-spark selfhost open    --profile lazycat   # smb://… 直接开 Finder
skill-spark selfhost mount                        # mount_smbfs 挂载（via=open 时退化为 Finder）
skill-spark selfhost umount / status / path
```

配置从最近的 `config.json` 读取（`default` + `profiles`，见仓库根示例）；密码只从 `SELFHOST_CLI_PASSWORD` 环境变量读取，不落盘。

## 相关文档

- 命令详解：`docs/cli/`（`cli-commands.md` 为索引）
- 文档站：`docmd.config.mjs` + GitHub Pages workflow
- hub 内定位与工作规则：hub 根目录 `AGENTS.md`
