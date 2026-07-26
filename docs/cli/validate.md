# validate — Validate SKILL.md

校验 SKILL.md 文件的结构、元数据、引用和文件安全性。

## 语法

```
skill-spark validate <path-or-source> [options]
```

## 选项

| 选项 | 说明 |
|------|------|
| `--all` | 校验源中发现的所有技能 |
| `--branch <branch>` | Git 分支覆盖 |
| `-s, --skill <skills...>` | 校验指定名称的技能 |
| `-f, --format <type>` | 输出格式：text, json, markdown |
| `-o, --output <path>` | 输出报告到文件 |
| `--strict` | 将 warning 视为错误 |

## 示例

```bash
# 校验单个技能目录
skill-spark validate skills/base/git-workflow

# 校验所有技能，输出 JSON
skill-spark validate skills/base --all -f json

# 严格模式
skill-spark validate skills/base --all --strict
```

## 校验内容

- SKILL.md 是否存在
- YAML frontmatter 格式是否正确
- 必填字段（name, description）是否存在
- 技能名是否为 lowercase kebab-case
- 技能名是否与目录名匹配
- 引用文件是否存在
- 是否包含二进制文件
- 路径遍历检查
