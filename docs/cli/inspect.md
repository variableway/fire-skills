# inspect — Inspect Skills

对技能进行确定性的风险规则和质量检查。

## 语法

```
skill-spark inspect <path-or-source> [options]
```

## 选项

| 选项 | 说明 |
|------|------|
| `--all` | 检查源中发现的所有技能 |
| `--branch <branch>` | Git 分支覆盖 |
| `-s, --skill <skills...>` | 检查指定名称的技能 |
| `--mode <mode>` | 检查模式：rules（默认） |
| `-f, --format <type>` | 输出格式：text, json, markdown |
| `-o, --output <path>` | 输出报告到文件 |
| `--fail-on <level>` | 风险级别阈值退出码：low, medium, high, critical |

## 检查内容

### 风险信号（9 条规则）

| 级别 | 规则 | 说明 |
|------|------|------|
| critical | `destructive-rm-rf` | 提到 `rm -rf` |
| high | `curl-pipe-shell` | curl/wget 管道到 shell |
| high | `git-reset-hard` | `git reset --hard` |
| high | `git-push-force` | 强制推送 Git 历史 |
| high | `credential-assignment` | 可能的凭证赋值 |
| medium | `sudo-command` | sudo 使用 |
| medium | `chmod-777` | `chmod 777` |
| medium | `external-write-github` | GitHub 操作可能修改外部状态 |
| medium | `workflow-write` | 写入 GitHub Actions workflow |

### 质量评分

- 减分项：error 25 分/warning 8 分
- 缺少使用场景说明：-10
- 内容过短：-10

### 可移植性评分

- 含 scripts 目录：-10
- 含 sudo：-15
- 含外部写操作：-10
- critical 风险：-30
- high 风险：-20

## 示例

```bash
# 检查单个技能
skill-spark inspect skills/base/git-workflow

# 检查所有，JSON 输出
skill-spark inspect skills/base --all -f json

# strict 模式退出
skill-spark inspect skills/base --all --fail-on high
```
