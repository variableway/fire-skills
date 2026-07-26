# search — Search Skills

从 Registry、目录或本地搜索技能。

## 别名

`s`

## 语法

```
skill-spark search [query] [options]
```

## 选项

| 选项 | 说明 |
|------|------|
| `--registry <url>` | Registry 地址覆盖 |
| `--category <slug>` | 按分类过滤 |
| `--limit <n>` | 每页结果数（最大 100） |
| `--offset <n>` | 分页偏移 |
| `--sort <value>` | 排序：votes, recent, stars |
| `--sources <sources...>` | 搜索源：registry, directory, local |
| `-i, --interactive` | 强制交互式浏览 |
| `-o, --output <path>` | 输出到文件（JSON 或 Markdown） |
| `-f, --format <type>` | 输出格式：json, markdown |

## 示例

```bash
# 交互式浏览
skill-spark search

# 搜索关键词
skill-spark search git-workflow

# 按分类过滤
skill-spark search --category devops

# 输出 JSON 到文件
skill-spark search --format json -o results.json
```
