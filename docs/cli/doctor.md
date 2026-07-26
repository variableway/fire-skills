# doctor — Diagnose Environment

诊断 skill-spark 环境状态。

## 语法

```
skill-spark doctor
```

无参数。运行后检查：

- 项目根目录检测
- 关键目录是否存在（`.claude/skills`, `.agents/skills` 等）
- `skills.lock` 状态
- 已安装 Agent 检测
- 缺失的 Agent 目录
- 交互式提供自动创建缺失目录的选项

## 示例

```bash
skill-spark doctor
```
