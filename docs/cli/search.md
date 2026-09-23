# search — Search Skills

从 Registry 或本地目录搜索技能。

## 别名

`s`

## 语法

```
skill-spark search [query] [options]
```

## 源模型

| 源 | 说明 |
|------|------|
| `registry` | 远程 registry（需要查询关键词） |
| `directory` | 扫描本地目录：默认当前目录往下 2 层；`--dir <path>` 指定起点目录；`--depth <n>` 指定层数 |

`local` 与 `flins` 是 `directory` 的历史别名，仍可使用。`find` 与 `search` 行为一致。

## 选项

| 选项 | 说明 |
|------|------|
| `--registry <url>` | Registry 地址覆盖 |
| `--category <slug>` | 按分类过滤 |
| `--limit <n>` | 每页结果数（最大 100） |
| `--offset <n>` | 分页偏移 |
| `--sort <value>` | 排序：votes, recent, stars |
| `--sources <sources...>` | 搜索源：registry, directory |
| `--dir <path>` | directory 源的扫描起点（默认：当前目录） |
| `--depth <n>` | directory 源的扫描层数（默认：2） |
| `-i, --interactive` | 强制交互式浏览 |
| `-o, --output <path>` | 输出到文件（JSON 或 Markdown） |
| `-f, --format <type>` | 输出格式：json, markdown |

## 示例

```bash
# 扫描当前目录（往下 2 层）
skill-spark search git --sources directory

# 指定起点目录，默认 2 层
skill-spark search git --sources directory --dir factory/skills

# 扫得更深
skill-spark search --sources directory --dir . --depth 5

# 交互式多选 + 选择安装范围（Project / Global）
skill-spark search --sources directory --dir factory/skills -i

# 按关键词过滤后进入交互多选
skill-spark search git -i --sources directory

# 远程 registry 搜索
skill-spark search git-workflow

# 输出 JSON 到文件
skill-spark search --format json -o results.json
```

交互多选按键：方向键聚焦选项，空格 / Tab 勾选，Enter 确认，随后选择安装范围（Project 或 Global）。交互模式需要终端（TTY），管道环境下会直接报错退出。
