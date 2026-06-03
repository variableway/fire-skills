# skill-spark

AI 编码智能体的通用技能管理器 — 融合 Fire-Skill 和 Flins 的最佳特性。

## 安装

```bash
cd skill-spark
bun install
```

## 快速开始

```bash
# 交互式浏览（推荐首次使用）
bun src/index.ts search

# 安装第一个技能
bun src/index.ts add better-auth

# 查看已安装列表
bun src/index.ts list
```

---

## 命令示例

### 1. search — 搜索技能

交互式搜索或使用查询条件搜索。

#### 交互式浏览（无查询）

```bash
bun src/index.ts search
```

打开 TUI 界面，你可以：
- 输入过滤技能
- 按空格多选技能
- 回车安装选中的技能

#### 使用关键词搜索

```bash
bun src/index.ts search "authentication"
```

输出示例：
```
┌─ skill-spark ────────────────────────────────────────────────
│
│ ◇  Found 15 skills
│
│    fastapi            Python REST API 框架
│    next-auth          Next.js 认证方案
│    better-auth        全栈应用完整认证方案
│    supabase-auth      Supabase 认证集成
│    ...
│
└─  Found 15 skills
```

#### 指定 Registry 搜索

```bash
bun src/index.ts search "api" --registry https://custom.registry.com/api
```

#### 带过滤条件的搜索

```bash
bun src/index.ts search "validation" --category security --limit 10 --sort stars
```

---

### 2. add — 安装技能

从多种来源安装技能。

#### 从 flins 目录安装

```bash
bun src/index.ts add better-auth
```

#### 从 GitHub 安装（简写形式）

```bash
bun src/index.ts add github.com/powroom/fire-skill-base
```

#### 从 GitHub 安装（完整 URL）

```bash
bun src/index.ts add https://github.com/powroom/fire-skill-base
```

#### 指定分支/子路径

```bash
bun src/index.ts add github.com/user/skills/tree/main/analytics
```

#### 全局安装（用户级别）

```bash
bun src/index.ts add better-auth --global
```

#### 指定目标 Agent

```bash
bun src/index.ts add better-auth --agent claude-code --agent cursor
```

#### 仅安装指定技能

```bash
bun src/index.ts add github.com/user/multi-skill --skill my-skill
```

#### 仅列出可用技能（不安装）

```bash
bun src/index.ts add github.com/user/skills --list
```

输出：
```
Available Installables from github.com/user/skills
  ◇ skill:analytics      分析仪表板技能
  ◇ skill:auth           认证模块
  ◇ command:deploy       部署命令
```

#### 使用复制模式（非符号链接）

```bash
bun src/index.ts add better-auth --no-symlink
```

#### 自动确认安装

```bash
bun src/index.ts add better-auth --yes
```

#### 完整安装流程示例

```bash
$ bun src/index.ts add better-auth

┌─ skill-spark ────────────────────────────────────────────────
│
│ ◇  Looking up better-auth in the flins directory...
│ ◇  Found 1 skill and 0 commands
│
│ ◇  Choose items to add
│   ● better-auth  Complete auth solution for full-stack apps
│
│ ◇  Universal Folder
│   .agents/skills is always included locally.
│   Used by: Claude Code, Cline, Codex, Cursor, Gemini CLI, ...
│
│ ◇  Install Summary
│   Source: flins.tech
│   Scope: Local
│   Items: skill:better-auth
│   Included local folder: .agents/skills
│
│ ○ Ready to install?
│
│  Yes  No
```

---

### 3. list — 列出已安装技能

显示所有已安装的技能和命令。

```bash
bun src/index.ts list
```

输出示例：
```
┌─ skill-spark ────────────────────────────────────────────────
│
│ ◇  Installed Skills and Commands
│
│   Local (./skills.lock)
│     ✓ skill:better-auth      (Claude Code, Cursor)
│     ⚡ command:deploy        (missing files)
│
│   Global (~/.skill-spark/skills.lock)
│     ✓ skill:analytics        (Claude Code)
│
└─  Showing installed items
```

---

### 4. outdated — 检查更新

检查哪些已安装的技能有更新或文件缺失。

```bash
bun src/index.ts outdated
```

输出示例：
```
┌─ skill-spark ────────────────────────────────────────────────
│
│ ◇  Update Available
│     better-auth    (abc123 → def456)
│
│ ◇  Up to Date
│     ✓ skill:analytics
│
│ ◇  Missing Files
│     ✗ command:deploy
│
└─  1 outdated, 1 current, 1 missing
```

#### 检查指定技能

```bash
bun src/index.ts outdated better-auth
```

---

### 5. update — 更新技能

将过时的技能更新到最新版本。

```bash
bun src/index.ts update
```

交互确认：
```
┌─ skill-spark ────────────────────────────────────────────────
│
│ ◇  Outdated Skills
│     better-auth    (abc123 → def456)
│
│ ○  Update all outdated skills?
│
│  Yes  No
```

#### 自动确认并更新

```bash
bun src/index.ts update --yes
```

输出：
```
┌─ skill-spark ────────────────────────────────────────────────
│
│ ◇  Installing...
│
│ ✓  Installed 1 item.
│
└─  Done! Skills ready to use.
```

---

### 6. remove — 移除技能

移除已安装的技能和命令。

#### 交互式移除

```bash
bun src/index.ts remove better-auth
```

确认提示：
```
┌─ skill-spark ────────────────────────────────────────────────
│
│ ○  Remove skill:better-auth?
│
│  Yes  No
```

#### 批量移除

```bash
bun src/index.ts remove better-auth analytics deploy
```

#### 自动确认移除

```bash
bun src/index.ts remove better-auth --yes
```

---

### 7. map — 映射技能到目标 Agent

将技能从源 Agent 目录映射到目标 Agent 目录。

#### 映射到 Claude Code

```bash
bun src/index.ts map --target claude-code
```

输出：
```json
{
  "schemaVersion": "1",
  "mapped": 3,
  "sourceBase": "/path/to/.claude/skills",
  "targetRoot": "/path/to/.claude/skills"
}
```

#### 从全局安装映射

```bash
bun src/index.ts map --target gemini --global
```

#### 从通用文件夹映射

```bash
bun src/index.ts map --target gemini --universal
```

#### 覆盖已有映射

```bash
bun src/index.ts map --target claude-code --force-map
```

#### 支持的目标

- `codex` → `.codex/skills`
- `gemini` → `.gemini/skills`
- `claude` → `.claude/skills`
- `agent` → `.agent/skills`
- `qwen` → `.qwen/skills`

---

### 8. doctor — 环境诊断

诊断你的 skill-spark 环境。

```bash
bun src/index.ts doctor
```

输出示例：
```
┌─ skill-spark ────────────────────────────────────────────────
│
│ ◇  Environment Diagnosis
│
│   Workspace root: /Users/patrick/project
│   Root detection: .git
│
│ ◇  Directories
│     ✗ .claude/skills (.claude/skills)
│     ✗ .agents/skills (.agents/skills)
│     ✓ .gemini/skills (.gemini/skills)
│     ✗ skills.lock (skills.lock)
│
│ ◇  Detected Agents
│     ✓ Claude Code
│     ✓ Cursor
│     ✓ Gemini CLI
│
└─  Diagnosis complete
```

---

## 常用场景

### 场景 1：首次设置

```bash
# 1. 检查环境
bun src/index.ts doctor

# 2. 浏览可用技能
bun src/index.ts search

# 3. 安装第一个技能
bun src/index.ts add better-auth

# 4. 查看已安装列表
bun src/index.ts list
```

### 场景 2：安装到多个 Agent

```bash
# 安装并指定 Claude Code 和 Cursor
bun src/index.ts add better-auth --agent claude-code --agent cursor

# 验证安装
bun src/index.ts list
```

### 场景 3：更新工作流

```bash
# 检查更新
bun src/index.ts outdated

# 更新所有过时技能
bun src/index.ts update --yes
```

### 场景 4：同步技能到不同 Agent

```bash
# 将 Claude Code 技能映射到 Gemini
bun src/index.ts map --target gemini --universal
```

### 场景 5：清理

```bash
# 查看已安装内容
bun src/index.ts list

# 移除未使用的技能
bun src/index.ts remove unused-skill --yes
```

---

## 配置

### Registry URL

```bash
# 环境变量
export FIRE_SKILL_REGISTRY_URL=https://custom.registry.com/api

# CLI 参数
bun src/index.ts search "query" --registry https://custom.registry.com/api
```

### 全局 vs 项目范围

```bash
# 项目级别（默认）- 创建 ./skills.lock
bun src/index.ts add better-auth

# 用户级别 - 创建 ~/.skill-spark/skills.lock
bun src/index.ts add better-auth --global
```

---

## 故障排除

### "No skills yet" 提示

还没有安装技能。运行：
```bash
bun src/index.ts search
```

### "Target already exists" 错误

映射时使用 `--force-map`：
```bash
bun src/index.ts map --target claude-code --force-map
```

### 安装失败（权限错误）

尝试使用复制模式：
```bash
bun src/index.ts add better-auth --no-symlink
```

### 查看版本

```bash
bun src/index.ts --version
```

---

## 支持的 Agent

skill-spark 支持 42+ AI 编码 Agent，包括：

- **通用型** (共享 `.agents/skills`)：Amp, Claude Code, Cline, Codex, Cursor, Gemini CLI, GitHub Copilot, Kimi CLI, OpenCode, Replit
- **专用型**：Antigravity, Augment, CodeBuddy, Command Code, Continue, Cortex Code, Crush, Droid, Goose, Junie, iFlow CLI, Kilo Code, Kiro CLI, Kode, Letta, MCPJam, Mistral Vibe, Mux, OpenHands, Pi, Qoder, Qwen Code, Roo Code, Trae, Trae CN, Windsurf, Zencoder, Neovate, Pochi, AdaL

详细目录映射请参考 [AGENTS.md](AGENTS.md)。

---

## 技术文档

| 文档 | 内容 |
|------|------|
| [README.md](README.md) | 使用指南（本文件） |
| [AGENTS.md](AGENTS.md) | Agent 目录映射表 |
| [SPEC.md](SPEC.md) | 技术规格文档 |
| [SKILL.md](SKILL.md) | Skill 元数据格式 |

---

## 许可证

MIT