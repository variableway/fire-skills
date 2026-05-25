# Frontend Skills

前端开发相关的 AI Agent Skill 集合，包含 Web 应用和桌面应用开发技能。

## 技能列表

| Skill | 说明 | 详情 |
|-------|------|------|
| **innate-frontend** | Web 前端开发（Next.js + @innate/ui） | [SKILL.md](innate-frontend/SKILL.md) |
| **desktop-app** | 桌面应用开发（Tauri + Next.js） | [SKILL.md](desktop-app/SKILL.md) |

## 安装

```bash
# 安装所有前端技能
./install.sh --system --folder fe-skills --all

# 查看可用技能
./install.sh --folder fe-skills --list
```

详见 [install-frontend-skills.md](../../docs/usage/install-frontend-skills.md)。

## 目录结构

```
fe-skills/
├── innate-frontend/           # Web 前端 Skill（含验证规则 + 升级策略）
│   ├── SKILL.md
│   └── references/
│       ├── component-catalog.md
│       └── theme-system.md
├── desktop-app/               # 桌面应用 Skill（统一入口 + 可选模块）
│   ├── SKILL.md
│   └── references/
│       ├── playground-mode.md
│       └── ai-chat-mode.md
├── beginner/                  # 入门教程（Terminal 环境配置）
└── skill-schema.json          # Skill 定义 JSON Schema
```

## 技能关系

- `desktop-app` 是 `innate-frontend` 的超集，包含前端 UI 规范并增加 Tauri 桌面层和 Rust 后端
- `desktop-app` 通过可选模块（PTY 终端、AI 聊天、教程系统）适应不同场景
