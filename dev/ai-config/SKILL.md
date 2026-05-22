---
name: ai-config
description: "配置 AI Agent Provider 到 AI 编程工具。当用户想配置或切换 AI 模型（如 GLM、OpenRouter、OpenAI）时调用此 Skill。支持自动安装和模板复制两种方式。"
type: skill
supported_agents:
  - claude-code
  - kimi
  - codex
  - opencode
tags:
  - ai
  - config
---

# AI Config Skill

一键配置 AI Agent Provider 到各种 AI 编程工具。

## 支持的工具和 Provider

| 工具 | GLM | OpenRouter | OpenAI | Anthropic |
|------|:---:|:----------:|:------:|:---------:|
| Claude Code | ✅ | ❌ | ❌ | ✅ |
| Codex CLI | ✅ | ✅ | ✅ | ❌ |
| OpenCode | ✅ | ❌ | ✅ | ❌ |
| Cline | ✅ | ❌ | ✅ | ❌ |
| OpenClaw | ✅ | ❌ | ❌ | ❌ |

## 两种配置方式

### 方式 A：自动安装（推荐）

使用官方工具自动完成安装、配置、MCP 管理。

**GLM（智谱 Coding Plan）— 一键配置：**

```bash
npx @z_ai/coding-helper
```

这个工具会自动完成：
- 工具安装（Claude Code / OpenCode / Crush / Factory Droid）
- API Key 配置
- 模型套餐加载
- MCP Server 管理

**OpenCode（内置 GLM 支持）：**

```bash
opencode auth login
# 选择 "Zhipu AI Coding Plan"，输入 API Key
opencode
# /models 选择 GLM 模型
```

### 方式 B：模板复制

从 `ai-config/templates/` 复制预置模板到目标位置，用户只需修改 API Key。

各工具的模板文件和目标路径：

| 工具 | 模板文件 | 复制到 |
|------|---------|-------|
| Claude Code + GLM | `templates/claude-code/glm.sh` | `source` 到终端 |
| Claude Code + GLM 模型映射 | `templates/claude-code/glm-settings.json` | 合并到 `~/.claude/settings.json` |
| Claude Code + Anthropic | `templates/claude-code/anthropic.sh` | `source` 到终端 |
| Codex + GLM | `templates/codex/glm.toml` | `~/.codex/config.toml` |
| Codex + OpenRouter | `templates/codex/openrouter.toml` | `~/.codex/config.toml` |
| Codex + OpenAI | `templates/codex/openai.toml` | `~/.codex/config.toml` |
| OpenCode + GLM | `templates/opencode/glm.json` | `~/.config/opencode/opencode.json` |
| OpenCode + OpenAI | `templates/opencode/openai.json` | `~/.config/opencode/opencode.json` |
| Cline + GLM | `templates/cline/glm.md` | 参考 IDE 内配置 |
| OpenClaw + GLM | `templates/openclaw/glm.json` | 合并到 `~/.openclaw/openclaw.json` |

## 使用指南

当用户说"配置 GLM"、"配置 OpenRouter"、"ai-config glm"等时：

### Step 1: 确认 Provider

- `glm` → 优先推荐方式 A（`npx @z_ai/coding-helper`），也可用方式 B
- `openrouter` / `openai` → 使用方式 B（模板复制）
- `anthropic` → 使用方式 B

### Step 2: 执行配置

#### GLM 配置（推荐方式 A）

```bash
npx @z_ai/coding-helper
```

按交互提示操作即可。如果用户偏好手动配置，使用方式 B：

```bash
# Claude Code + GLM
source ai-config/templates/claude-code/glm.sh
# 将 glm-settings.json 合并到 ~/.claude/settings.json 可切换模型到 GLM-5.1

# Codex CLI + GLM
mkdir -p ~/.codex
cp ai-config/templates/codex/glm.toml ~/.codex/config.toml

# OpenCode + GLM
cp ai-config/templates/opencode/glm.json ~/.config/opencode/opencode.json
```

#### OpenRouter / OpenAI 配置（方式 B）

```bash
# Codex CLI + OpenRouter
mkdir -p ~/.codex
cp ai-config/templates/codex/openrouter.toml ~/.codex/config.toml

# Codex CLI + OpenAI
mkdir -p ~/.codex
cp ai-config/templates/codex/openai.toml ~/.codex/config.toml
```

### Step 3: 提示设置 API Key

| Provider | 环境变量 | 获取地址 |
|----------|---------|---------|
| GLM | `ANTHROPIC_API_KEY`（Claude Code）/ `GLM_API_KEY`（Codex） | https://open.bigmodel.cn |
| OpenRouter | `OPENROUTER_API_KEY` | https://openrouter.ai |
| OpenAI | `OPENAI_API_KEY` | https://platform.openai.com |
| Anthropic | `ANTHROPIC_API_KEY` | https://console.anthropic.com |

```bash
echo 'export XXX_API_KEY="your-key"' >> ~/.zshrc
source ~/.zshrc
```

## 关键 API 端点

| 用途 | 端点 URL |
|------|---------|
| GLM Coding Plan (通用) | `https://open.bigmodel.cn/api/coding/paas/v4` |
| GLM Coding Plan (Claude Code) | `https://open.bigmodel.cn/api/anthropic` |
| GLM 通用 API | `https://open.bigmodel.cn/api/paas/v4` |
| OpenRouter | `https://openrouter.ai/api/v1` |
| OpenAI | `https://api.openai.com/v1` |

## Claude Code 模型映射

配置 GLM 后，Claude Code 自动映射：

| Claude 模型层级 | 默认 GLM 模型 |
|----------------|-------------|
| Opus | GLM-5.1 |
| Sonnet | GLM-5.1 |
| Haiku | GLM-4.5-Air |

这是通过 `glm-settings.json` 配置的结果。如不使用该配置，默认映射为 Opus→GLM-4.7, Sonnet→GLM-4.7, Haiku→GLM-4.5-Air。

启动后输入 `/status` 确认当前模型状态。

## 模板目录结构

```
ai-config/
├── SKILL.md                          # 本文件
└── templates/
    ├── claude-code/
    │   ├── glm.sh                    # Claude Code + GLM 环境变量
    │   ├── glm-settings.json         # Claude Code + GLM 模型映射
    │   └── anthropic.sh              # Claude Code + Anthropic 恢复
    ├── codex/
    │   ├── glm.toml                  # Codex CLI + GLM
    │   ├── openrouter.toml           # Codex CLI + OpenRouter
    │   └── openai.toml               # Codex CLI + OpenAI
    ├── opencode/
    │   ├── glm.json                  # OpenCode + GLM
    │   └── openai.json               # OpenCode + OpenAI
    ├── cline/
    │   └── glm.md                    # Cline + GLM 配置说明
    └── openclaw/
        └── glm.json                  # OpenClaw + GLM 配置片段
```

## 注意事项

1. **API Key 安全**：不要将 API Key 提交到 Git 仓库
2. **GLM Coding Plan 专属端点**：必须使用 `coding/paas/v4` 而非 `paas/v4`，否则不会消耗套餐额度
3. **已有 Claude 用户**：如不想覆盖原有配置，使用 alias 方式：`alias glm-cc='ANTHROPIC_BASE_URL=https://open.bigmodel.cn/api/anthropic ANTHROPIC_API_KEY="your-key" claude'`
4. **GLM 可用模型**：GLM-5.1、GLM-5、GLM-4.7、GLM-4.6、GLM-4.5、GLM-4.5-Air
5. **Codex CLI 配置优先级**：项目级 `.codex/config.toml` > 全局 `~/.codex/config.toml`
