# URL Content Extraction Use Cases

使用 anysearch skill 提取网页内容为 Markdown 格式。

## 使用场景

- 需要读取某个 URL 的正文内容
- 将网页转换为 Markdown 进行分析
- 从搜索结果中提取完整内容

## 示例

### 1. 提取 GitHub Issues 文档

```bash
bash skills/base/anysearch/scripts/anysearch_cli.sh extract "https://docs.github.com/en/issues"
```

结果: [url-extract-github-docs.md](url-extract-github-docs.md)

### 2. 提取 GitHub CLI 文档

```bash
bash skills/base/anysearch/scripts/anysearch_cli.sh extract "https://cli.github.com/"
```

结果: [url-extract-gh-cli.md](url-extract-gh-cli.md)

### 3. 从搜索到提取的流程

```bash
# 先搜索
bash skills/base/anysearch/scripts/anysearch_cli.sh search "GitHub workflow automation" --max_results 5

# 再提取有价值的 URL
bash skills/base/anysearch/scripts/anysearch_cli.sh extract "https://找到的URL"
```

## 自然语言提示

```
请用 AnySearch 抽取这个页面的 Markdown，并总结核心观点：https://example.com/article
```
