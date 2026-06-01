# Fire Skills 文档

欢迎来到 Fire Skills 文档中心。本目录包含项目相关的详细文档和指南。

## 文档索引

### 核心文档

| 文档 | 说明 |
|------|------|
| [index.md](./index.md) | 文档首页（含快速开始和技能分类） |
| [Agents.md](./Agents.md) | 支持的 AI Agent 工具介绍和配置说明 |
| [ai-coding-tools-guide.md](./ai-coding-tools-guide.md) | AI 编程工具配置指南（Claude Code、Codex、OpenCode、GLM） |
| [usage/install-by-tag.md](./usage/install-by-tag.md) | 按 Tag 批量安装 Skills 指南 |
| [usage/install-frontend-skills.md](./usage/install-frontend-skills.md) | 前端技能安装指南 |
| [usage/fe-skills-reference-guide.md](./usage/fe-skills-reference-guide.md) | 前端技能参考指南 |

### 规范文档

| 文档 | 说明 |
|------|------|
| [spec/auto-doc-update-proposal.md](./spec/auto-doc-update-proposal.md) | 任务完成后自动文档更新方案设计 |
| [spec/ai-agent-protocol.md](./spec/ai-agent-protocol.md) | AI Agent 通用协议定义 |
| [spec/agent-communication-protocols.md](./spec/agent-communication-protocols.md) | Agent 间通信协议 |
| [spec/agent-output-template.md](./spec/agent-output-template.md) | Agent 输出模板规范 |
| [spec/system-prompt-integration.md](./spec/system-prompt-integration.md) | System Prompt 集成方案 |
| [validation/workflow-validation.md](./validation/workflow-validation.md) | 工作流验证文档 |

### 快速导航

#### 新手入门

1. 阅读 [Agents.md](./Agents.md) 了解支持的 AI Agent 工具
2. 根据你的网络环境选择合适的工具：
   - 国内用户推荐：Claude Code + GLM-5.1 或 Codex CLI + GLM-5.1
   - 海外用户推荐：Claude Code + Anthropic
3. 参考 [ai-coding-tools-guide.md](./ai-coding-tools-guide.md) 进行配置

#### 常见问题

- **Claude Code 连接失败**：参考 [AI 编程工具配置指南 - 连接问题排查](./ai-coding-tools-guide.md#2-claude-code-配置指南)
- **如何使用国产模型**：参考 [智谱 GLM Coding Plan](./ai-coding-tools-guide.md#6-智谱-glm-coding-plan)
- **工具对比选择**：参考 [工具对比与选择建议](./ai-coding-tools-guide.md#7-工具对比与选择建议)
- **一键配置 GLM**：运行 `npx @z_ai/coding-helper`

## 项目主文档

- [项目 README](../README.md) - 项目概览和快速开始
- [安装脚本](../install-by-tag.sh) - 按 Tag 批量安装 Skills（macOS/Linux）
- [清理脚本](../clean-skills.sh) - 清理已安装 Skills

## 贡献文档

如需添加新文档，请：

1. 在 `docs/` 目录下创建 Markdown 文件
2. 更新本索引文件
3. 确保文档格式规范、内容准确
