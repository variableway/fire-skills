# find — Find Skills Locally

跨本地源、Registry 和目录查找技能。功能与 `search` 相同，默认搜索源为 `local,registry,directory`。

## 语法

```
skill-spark find [query] [options]
```

## 选项

与 [search](./search.md) 相同，默认 `--sources` 为 `local,registry,directory`。

## 示例

```bash
# 查找所有本地和远程技能
skill-spark find

# 按关键词查找
skill-spark find deployment
```
