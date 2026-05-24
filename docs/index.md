# Spark Skills 文档中心

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
| `dev/` | 开发工作流（git / GitHub / 安全 / AI 配置 / 调研） | `./install-by-tag.sh dev-workflow --system` |
| `analysis/` | 代码仓库语义分析（含 CodeGraph 集成） | `./install-by-tag.sh analysis --system` |
| `fe-skills/` | 前端开发（@innate/ui · Tauri + Next.js） | `./install.sh --system --folder fe-skills --all` |
| `backend-skills/` | 后端开发（Go CLI 等） | `./install.sh --system --folder backend-skills --all` |
| `product/` | 产品设计（PRD / 项目分析） | `./install.sh --system --folder product --all` |

### 🚀 快速开始

```bash
# 克隆仓库
git clone https://github.com/your-username/spark-skills.git
cd spark-skills

# 安装 skills 到你的 Agent
./install.sh claude-code  # 或 kimi / codex / opencode / trae / workbuddy
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
├── index.md                    # 本文件（文档首页）
├── README.md                   # 文档索引
├── Agents.md                   # Agent 工具介绍
├── ai-coding-tools-guide.md    # 配置指南
└── usage/
    ├── install-frontend-skills.md  # 前端技能安装指南
    ├── install-by-tag.md           # 按 Tag 批量安装指南
    └── fe-skills-reference-guide.md
```

---

更多信息请访问 [项目主页](../README.md)。
