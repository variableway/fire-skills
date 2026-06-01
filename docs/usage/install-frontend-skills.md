# Frontend Skills 安装指南

本指南介绍如何安装和使用 Fire Skills 中的前端开发技能：`innate-frontend`（Web 应用）。

## 技能概览

| 技能 | 用途 | 技术栈 |
|------|------|--------|
| **innate-frontend** | Web 应用开发 | Next.js 16, React 19, TypeScript, Tailwind CSS v4, @innate/ui |

该技能位于 `references/skills-pool/fe-skills/innate-frontend/`。

## 安装

### 通过 install-by-tag（推荐）

```bash
# 扫描 references/skills-pool/ 下的 fe-skills/ 目录并安装
./install-by-tag.sh innate --system --dir ./references/skills-pool/fe-skills

# 安装到特定 Agent
./install-by-tag.sh innate --system --agent claude-code --dir ./references/skills-pool/fe-skills

# 项目级安装
./install-by-tag.sh innate --project --dir ./references/skills-pool/fe-skills
```

### 手动符号链接

```bash
ln -s $(pwd)/references/skills-pool/fe-skills/innate-frontend ~/.claude/skills/innate-frontend
```

## 安装路径

系统级安装会在以下目录创建符号链接：

| Agent | 路径 |
|-------|------|
| Claude Code | `~/.claude/skills/` |
| Kimi CLI | `~/.kimi/skills/` |
| Codex CLI | `~/.codex/skills/` |
| OpenCode | `~/.opencode/skills/` |
| Trae / Trae Solo | `~/.trae/skills/` |
| WorkBuddy | `~/.workbuddy/skills/` |

## 验证安装

```bash
ls -la ~/.claude/skills/ | grep innate-frontend
```

应显示一个符号链接指向 `fire-skills` 仓库中的 `references/skills-pool/fe-skills/innate-frontend/`。

## 使用

### 创建 Web 应用

在 Agent 对话中触发 `innate-frontend` 技能：

> "使用 innate-frontend 创建一个新的 Web 应用项目"

技能提供：
- 57+ `@innate/ui` 组件
- 7 个 Landing 区块 + Auth/Mail/Chat 业务区块
- OKLCH 颜色主题系统
- 项目验证规则
- shadcn/ui 升级策略

## 更新技能

由于使用符号链接安装，更新只需拉取最新代码：

```bash
cd fire-skills
git pull
```

所有 Agent 的技能会自动更新。

## 卸载

移除符号链接即可：

```bash
rm ~/.claude/skills/innate-frontend
rm ~/.kimi/skills/innate-frontend
rm ~/.codex/skills/innate-frontend
rm ~/.opencode/skills/innate-frontend
rm ~/.trae/skills/innate-frontend
rm ~/.workbuddy/skills/innate-frontend
```
