# docx-to-md — Convert DOCX to Markdown

将 `.docx` 文件转换为 Markdown 格式。

## 语法

```
skill-spark docx-to-md -s <source.docx> -o <target.md>
```

## 选项

| 选项 | 说明 |
|------|------|
| `-s, --source <path>` | 源 .docx 文件路径（必填） |
| `-o, --output <path>` | 输出 .md 文件路径（必填） |

## 示例

```bash
# 转换单个文件
skill-spark docx-to-md -s report.docx -o report.md

# 转换到指定目录
skill-spark docx-to-md -s ~/docs/spec.docx -o docs/spec.md
```
