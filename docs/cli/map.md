# map — Map Skills to Agent Directory

将已安装的技能映射到目标 Agent 的目录结构中。

## 语法

```
skill-spark map [options]
```

## 选项

| 选项 | 说明 |
|------|------|
| `--target <target>` | 目标环境：gemini, claude, codex, agent, qwen |
| `--global` | 从全局 skill-spark 安装映射 |
| `--universal` | 从 universal（.agents/skills）映射 |
| `--force-map` | 存在映射时强制覆盖 |

## 源目录

- 默认：`.claude/skills`
- `--global`：`~/.skill-spark/skills`
- `--universal`：`.agents/skills`

## 示例

```bash
# 映射到 Claude Code
skill-spark map --target claude

# 全局映射到 Codex
skill-spark map --target codex --global --force-map
```
