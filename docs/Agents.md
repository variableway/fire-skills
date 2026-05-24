# 支持的 AI Agent 工具

本文档介绍 Spark Skills 仓库支持的 AI Agent 工具及其配置方式。

## 支持的 Agent 列表

| Agent | 配置文件位置 | Skills 目录 | 说明 |
|-------|-------------|-------------|------|
| **Claude Code** | `~/.claude/` | `~/.claude/skills/` | Anthropic 官方 CLI 工具，支持 GLM |
| **Kimi CLI** | `~/.kimi/` | `~/.kimi/skills/` | 月之暗面出品的 CLI 工具 |
| **Codex CLI** | `~/.codex/` | `~/.codex/skills/` | OpenAI 出品的 CLI 工具 |
| **OpenCode** | `~/.opencode/` | `~/.opencode/skills/` | 开源多模型 CLI 工具 |
| **Trae** | `~/.trae/` | `~/.trae/skills/` | 字节跳动 AI IDE，支持 SOLO 模式 |
| **Trae Solo** | `~/.trae/` | `~/.trae/skills/` | Trae 独立开发模式 |
| **WorkBuddy** | `~/.workbuddy/` | `~/.workbuddy/skills/` | 腾讯云 AI 编程工具 |

## Agent 详细说明

### Claude Code

Anthropic 官方推出的 AI 编程助手 CLI 工具。支持通过 `ANTHROPIC_BASE_URL` 接入智谱 GLM。

**特点**：
- 编程能力强大，理解复杂代码库
- 自动执行代码修改和 Git 操作
- 支持多轮对话和上下文记忆
- 原生支持 GLM Coding Plan

**安装**：
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**使用 GLM（推荐国内用户）**：
```bash
export ANTHROPIC_BASE_URL="https://open.bigmodel.cn/api/anthropic"
export ANTHROPIC_API_KEY="your-zhipu-api-key"
claude
```

**一键配置**：
```bash
npx @z_ai/coding-helper
```

**Skills 安装**：
```bash
./install.sh claude-code
```

**模型映射**：

| Claude 层级 | 默认 GLM | 升级 GLM-5.1 |
|------------|---------|-------------|
| Opus | GLM-4.7 | GLM-5.1 |
| Sonnet | GLM-4.7 | GLM-5.1 |
| Haiku | GLM-4.5-Air | GLM-4.5-Air |

---

### Codex CLI

OpenAI 推出的 AI 编程助手 CLI 工具，支持多种模型后端。

**特点**：
- 支持自定义模型 Provider
- 原生支持 OpenAI、GLM、OpenRouter 等
- TOML 配置文件，灵活切换

**安装**：
```bash
npm install -g @openai/codex
```

**配置文件**：`~/.codex/config.toml`

**使用 GLM**：
```toml
model = "GLM-5.1"
model_provider = "glm"

[model_providers.glm]
name = "GLM"
base_url = "https://open.bigmodel.cn/api/coding/paas/v4"
env_key = "GLM_API_KEY"
wire_api = "chat"
```

**使用 OpenRouter**：
```toml
model = "anthropic/claude-sonnet-4.6"
model_provider = "openrouter"

[model_providers.openrouter]
name = "OpenRouter"
base_url = "https://openrouter.ai/api/v1"
env_key = "OPENROUTER_API_KEY"
wire_api = "chat"
```

**使用 OpenAI**：
```toml
model = "gpt-5.4"
model_provider = "openai"

[model_providers.openai]
name = "OpenAI"
base_url = "https://api.openai.com/v1"
env_key = "OPENAI_API_KEY"
wire_api = "chat"
```

**Skills 安装**：
```bash
./install.sh codex
```

---

### Kimi CLI

月之暗面出品的 AI 编程助手，基于 Kimi 模型。

**特点**：
- 国产模型，国内访问无障碍
- 支持超长上下文（200K+ tokens）
- 中文理解能力强

**安装**：
```bash
npm install -g @moonshot/kimi-cli
kimi login
```

**Skills 安装**：
```bash
./install.sh kimi
```

---

### OpenCode

开源多模型 AI 编程助手，内置 GLM Coding Plan 支持。

**特点**：
- 内置智谱 GLM Coding Plan 支持
- TUI 界面，轻量级
- 支持多种模型

**安装**：
```bash
brew install opencode-ai/tap/opencode
# 或
curl -fsSL https://opencode.ai/install | bash
```

**使用 GLM**：
```bash
opencode auth login
# 选择 "Zhipu AI Coding Plan"，输入 API Key
opencode
```

**Skills 安装**：
```bash
./install.sh opencode
```

---

### Trae IDE

字节跳动推出的 AI 编程 IDE，基于 VS Code，支持多种模型和 SOLO 模式。

**特点**：
- 支持 Claude、Gemini、Kimi K2 等多种模型
- SOLO 模式提供端到端软件工程能力
- 内置 MCP 支持和 Web 搜索
- 支持自定义 Agent

**安装**：
从 [trae.ai](https://trae.ai/) 下载安装

**使用多种模型**：
```bash
# 在 Settings 中配置 Provider
# 支持 OpenAI、Anthropic、Google Gemini、月之暗面 Kimi K2 等
```

**Skills 安装**：
```bash
# 系统级安装
./install-by-tag.sh dev-workflow --system --agent trae

# 项目级安装
./install-by-tag.sh github --project --agent trae
```

---

### Trae Solo

Trae IDE 的独立开发模式，提供更聚焦的开发体验。

**特点**：
- 专注于 SOLO 开发场景
- 与 Trae 使用相同的 skills 目录
- 支持 Web 应用一键部署到 Vercel

**Skills 安装**：
```bash
# 与 Trae 共享 skills 目录
./install-by-tag.sh dev-workflow --system --agent trae-solo
```

---

### WorkBuddy

腾讯云推出的 AI 编程工具，支持多种模型配置。

**特点**：
- 支持通过 `models.json` 配置多种模型
- 支持 Evolink 等 API 集成
- 支持自定义 Provider

**配置文件**：`~/.workbuddy/models.json`

**使用 Evolink**：
```json
{
  "models": [
    {
      "id": "evolink/auto",
      "name": "Evolink Auto (Smart Routing)",
      "vendor": "Evolink",
      "apiKey": "sk-your-api-key-here",
      "url": "https://direct.evolink.ai/v1/chat/completions"
    }
  ]
}
```

**Skills 安装**：
```bash
./install-by-tag.sh dev-workflow --system --agent workbuddy
```

---

## 快速对比

| 特性 | Claude Code | Codex CLI | Kimi CLI | OpenCode | Trae | WorkBuddy |
|------|-------------|-----------|----------|----------|----------|------|-----------|
| 最新模型 | GLM-5.1 / Claude Opus 4.6 | GLM-5.1 / GPT-5.4 | Kimi | GLM-5.1 | Claude 4.6 / Gemini 2.5 | 多种 |
| GLM Coding Plan | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ |
| OpenRouter | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| 国内可用 | GLM 原生 | GLM 原生 | 原生支持 | GLM 原生 | 良好 | 良好 |
| 自定义 Provider | GLM only | 完全支持 | 有限 | 内置 | 多Provider | 完全支持 |
| 开源 | 否 | 否 | 否 | 是 | 否 | 否 |
| IDE 界面 | CLI | CLI | CLI | CLI | VS Code 风格 | VS Code 风格 |

## 选择建议

- **国内用户，最强编码能力** → Claude Code + GLM-5.1
- **灵活切换模型** → Codex CLI
- **轻量终端工具** → OpenCode + GLM
- **中文场景** → Kimi CLI
- **VS Code 风格 IDE** → Trae / Trae Solo
- **预算有限** → Codex CLI + GLM Coding Plan Lite
- **腾讯云集成** → WorkBuddy

## 更多信息

详细的配置指南请参考 [AI 编程工具配置指南](./ai-coding-tools-guide.md)。
