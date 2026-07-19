# OpenWiki 设置与使用指南

## 概述

[OpenWiki](https://github.com/langchain-ai/openwiki) 是 LangChain AI 开源的 CLI 工具，专为 AI Agent 设计，用于自动生成和维护代码仓库的文档 Wiki。它能扫描整个代码库，通过 LLM 理解代码结构和意图，生成结构化的文档。

本文档涵盖：
- 安装与初始化
- 在本项目中配置 Code Mode 文档
- 持续更新文档（含 CI 集成）
- 日常使用方式

---

## 1. 安装 OpenWiki

### 前置要求

- Node.js >= 18
- 一个 LLM Provider 的 API Key（支持 OpenAI / Anthropic / OpenRouter / Bedrock 等）

### 安装

```bash
npm install -g openwiki
```

> **Windows 注意**：推荐使用 npm 或 pnpm 安装。`bun install -g openwiki` 需要提前安装 Visual Studio Build Tools（含 Desktop development with C++ workload），因为 better-sqlite3 依赖需要编译原生模块。

### 验证安装

```bash
openwiki --help
```

### 配置 LLM Provider

OpenWiki 首次运行 `--init` 时会进入交互式配置向导，引导你选择 Provider 并输入 API Key。

**支持的 Provider（部分）：**

| Provider | 环境变量 |
|----------|---------|
| OpenAI | `OPENAI_API_KEY` |
| Anthropic | `ANTHROPIC_API_KEY` |
| OpenRouter | `OPENROUTER_API_KEY` |
| AWS Bedrock | `BEDROCK_AWS_ACCESS_KEY_ID` + `BEDROCK_AWS_SECRET_ACCESS_KEY` + `BEDROCK_AWS_REGION` |
| OpenAI Compatible | `OPENAI_COMPATIBLE_API_KEY` + `OPENAI_COMPATIBLE_BASE_URL` |

所有配置和密钥会保存在 `~/.openwiki/.env`。

**手动配置示例（跳过向导）：**

```bash
# 使用 OpenAI
export OPENWIKI_PROVIDER=openai
export OPENAI_API_KEY=sk-xxx
export OPENWIKI_MODEL_ID=gpt-5.6-terra
```

---

## 2. 在项目中初始化 OpenWiki 文档

### 2.1 首次初始化

在项目根目录运行：

```bash
cd /path/to/fire-skills
openwiki --init
```

这会：
1. 首次运行会引导配置 Provider / API Key / Model
2. 扫描整个代码库（`packages/`、`skills/`、`scripts/` 等）
3. 在 `openwiki/` 目录下生成结构化的文档页面
4. 在仓库根目录自动维护 `AGENTS.md` 和 `CLAUDE.md`（会在已有内容中追加 `<!-- OPENWIKI:START -->...<!-- OPENWIKI:END -->` 区块）

### 2.2 生成的文档结构

```
fire-skills/
├── openwiki/              # OpenWiki 生成的文档
│   ├── index.md           # 文档索引
│   ├── INSTRUCTIONS.md    # 自定义编写范围说明（可手动编辑，不会被自动覆盖）
│   └── ...                # 自动生成的各模块文档
├── AGENTS.md              # 自动维护，引导 Agent 参考 openwiki/ 中的文档
└── CLAUDE.md              # 同上
```

### 2.3 自定义文档范围

`openwiki/INSTRUCTIONS.md` 是用户可以手动编写的项目说明文件。OpenWiki 在生成/更新文档时会先读取此文件，了解文档范围与优先级。

**示例内容：**

```markdown
# OpenWiki Instructions for fire-skills

## Scope
- 重点记录 skill-core 和 skill-cli 的 API 设计与模块交互
- 每个 command 的功能与参数说明
- Agent 配置系统的扩展方式

## Priority
- packages/skill-core/src/ > packages/skill-cli/src/ > skills/
- 类型定义与接口优先于实现细节
```

> `INSTRUCTIONS.md` 不会被 `--init` 或 `--update` 覆盖，除非显式要求修改。

---

## 3. 持续更新文档

### 3.1 手动更新

当代码变更后，重新生成最新文档：

```bash
openwiki --update
```

也可以带提示词指导更新方向：

```bash
openwiki --update "重点更新新添加的 CLI commands 说明"
```

### 3.2 CI 自动更新（推荐）

将 OpenWiki 集成到 CI 中，每次提交自动生成文档 PR。

**GitHub Actions：**

复制 [openwiki-update.yml](https://github.com/langchain-ai/openwiki/blob/main/examples/openwiki-update.yml) 到 `.github/workflows/`：

```bash
mkdir -p .github/workflows
curl -o .github/workflows/openwiki-update.yml \
  https://raw.githubusercontent.com/langchain-ai/openwiki/main/examples/openwiki-update.yml
```

然后在 GitHub 仓库的 **Settings > Secrets and variables > Actions** 中配置：

| Secret 名称 | 说明 |
|------------|------|
| `OPENAI_API_KEY` | OpenAI API Key（如果用 OpenAI） |
| `ANTHROPIC_API_KEY` | Anthropic API Key（如果用 Anthropic） |

> CI 中只需 `openwiki code --update --print`，不需要先 `--init`——`--update` 会在 `openwiki/` 不存在时自动创建。

**GitLab CI：**

复制 [openwiki-update.gitlab-ci.yml](https://github.com/langchain-ai/openwiki/blob/main/examples/openwiki-update.gitlab-ci.yml)。

---

## 4. 日常使用

### 4.1 交互式会话

```bash
# 在项目根目录启动交互式会话
cd /path/to/fire-skills
openwiki
```

在会话中可以：
- 使用 `/api-key` 更新 API Key（输入时被遮蔽）
- 发送任意文档编写指令
- 输入 `exit` 或 Ctrl+C 退出

### 4.2 单次命令（非交互式）

```bash
# 一条命令生成文档
openwiki -p "为 CLI 的所有 command 生成参数对照表"

# 指定模式输出
openwiki "请总结项目的模块架构图"
```

### 4.3 指定 Code Mode

```bash
openwiki code --init          # 初始化代码文档
openwiki code --update         # 更新代码文档
openwiki code --update --print # 非交互式更新并打印输出
```

### 4.4 查看已有文档

生成后在浏览器中查看 Markdown 文件，或使用编辑器预览：

```bash
ls openwiki/
cat openwiki/index.md
```

---

## 5. 最佳实践

1. **先写 INSTRUCTIONS.md**：在 `openwiki --init` 之后，编辑 `openwiki/INSTRUCTIONS.md` 定义文档偏好，再运行 `--update`。
2. **纳入版本控制**：将 `openwiki/`、`AGENTS.md`、`CLAUDE.md` 提交到 Git，让团队成员和 AI Agent 共享文档。
3. **CI 定期更新**：配置 CI workflow 定期（如每天或每次推送）自动更新文档。
4. **与现有文档共存**：`docs/` 目录中的手动文档可以保留，与 `openwiki/` 自动生成的文档互补——手动文档写设计决策与规划，自动文档写代码结构。
5. **避免重复**：如果 openwiki 生成的文档已覆盖某部分内容，可以移除 `docs/` 下的对应手动文档以减少维护负担。

---

## 6. 常见问题

**Q: `--update` 会覆盖我手动编辑的文档吗？**

A: 不会覆盖 `openwiki/INSTRUCTIONS.md`。其他 `openwiki/` 下的页面会在更新时被重写，如有手动补充请写入 `INSTRUCTIONS.md` 中。

**Q: 支持哪些 LLM？**

A: 支持 OpenAI、Anthropic、OpenRouter、AWS Bedrock、Google Vertex AI、Nebius、Fireworks、Baseten、NVIDIA NIM，以及任意 OpenAI 兼容端点。

**Q: 如何更换模型？**

A: 设置 `OPENWIKI_MODEL_ID` 环境变量，或删除 `~/.openwiki/.env` 重新运行 `--init` 进入配置向导。

**Q: 生成的文档可以用于 Codex/Cursor/Trae 等 Agent 吗？**

A: 可以。OpenWiki 自动维护的 `AGENTS.md` 会提示 Agent 在搜索上下文时参考 `openwiki/` 中的文档。
