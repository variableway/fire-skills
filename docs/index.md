# Fire Skills 文档中心

> 个人习惯的 AI Agent Skill 仓库，统一收集、管理和分发适配多种 AI 编程助手的 Skills。

## 快速链接

### 📚 文档

- [支持的 Agent 工具](./Agents.md) - Claude Code、Codex CLI、Kimi CLI、OpenCode、Trae、WorkBuddy 等
- [AI 编程工具配置指南](./ai-coding-tools-guide.md) - 详细配置教程
- [前端技能安装指南](./usage/install-frontend-skills.md) - Web 和桌面应用技能安装与使用
- [按 Tag 安装 Skills](./usage/install-by-tag.md) - 跨分类目录批量安装

### 🗂 Skill 分类

| 分类目录 | 内容 | 安装命令 |
|---------|------|---------|
| `dev/` | 开发工作流（git / GitHub / 安全 / 知识图谱） | `./install-by-tag.sh dev-workflow --system` |
| `analysis/` | 代码分析（CodeGraph 集成 / 技术调研 / 项目分析） | `./install-by-tag.sh analysis --system` |
| `office-skills/` | 办公效率（Markdown 转换 / Python 项目脚手架） | `./install-by-tag.sh office --system` |
| `references/skills-pool/` | 更多分类（前端 / 后端 / 产品 / AI 配置） | `./install-by-tag.sh <tag> --system --dir ./references/skills-pool/<subdir>` |

### 🚀 快速开始

```bash
# 克隆仓库
git clone https://github.com/variableway/fire-skills.git
cd fire-skills

# 安装 skills 到你的 Agent
./install-by-tag.sh dev-workflow --system --agent claude-code  # 或 kimi / codex / opencode / trae / workbuddy
```

### 🛠 推荐配置

#### 国内用户（无需代理）

**方案一：Claude Code + GLM-5.1（推荐）**

```bash
# 一键配置
npx @z_ai/coding-helper

# 或手动配置
export ANTHROPIC_BASE_URL="https://open.bigmodel.cn/api/anthropic"
export ANTHROPIC_API_KEY="your-zhipu-api-key"
claude
```

**方案二：Codex CLI + GLM-5.1**

```bash
npm install -g @openai/codex
cp ai-config/templates/codex/glm.toml ~/.codex/config.toml
export GLM_API_KEY="your-zhipu-api-key"
codex
```

**方案三：OpenCode + GLM**

```bash
opencode auth login
# 选择 "Zhipu AI Coding Plan"
opencode
```

#### 海外用户

**Claude Code**

```bash
curl -fsSL https://claude.ai/install.sh | bash
claude login
```

---

## 文档目录

```
docs/
├── index.md                         # 本文件（文档首页）
├── README.md                        # 文档索引
├── Agents.md                        # Agent 工具介绍
├── ai-coding-tools-guide.md         # 配置指南
├── architecture-output-flow.mmd     # 架构输出流程图
├── spec/                            # 协议和规范定义
│   ├── agent-communication-protocols.md
│   ├── agent-output-template.md
│   ├── ai-agent-protocol.md
│   ├── auto-doc-update-proposal.md
│   └── system-prompt-integration.md
├── usage/                           # 使用指南
│   ├── install-frontend-skills.md
│   ├── install-by-tag.md
│   └── fe-skills-reference-guide.md
└── validation/                      # 验证文档
    └── workflow-validation.md
```

---

更多信息请访问 [项目主页](../README.md)。
