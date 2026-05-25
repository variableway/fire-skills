---
name: markdown-converter
description: |
  Convert documents and files to Markdown using markitdown.
  Supports PDF, Word (.docx), PowerPoint (.pptx), Excel (.xlsx, .xls), HTML, CSV, JSON, XML,
  images (with EXIF/OCR), audio (with transcription), ZIP archives, YouTube URLs, and EPub.
  TRIGGER: When user asks to "convert to markdown", "convert PDF", "convert docx", "convert document",
  "提取文档内容", "转换为markdown", "读取PDF", "解析文档", or wants to extract text from documents.
type: skill
supported_agents:
  - claude-code
  - kimi
  - codex
  - opencode
  - trae
  - trae-solo
  - workbuddy
tags:
  - office
  - document
  - conversion
  - markdown
  - productivity
triggers:
  - pattern: "^/(markdown-convert|convert-markdown|to-markdown)"
  - pattern: "(转换|转换|提取|解析).*(markdown|文档|PDF|docx|Word|Excel|PPT)"
  - pattern: "convert.*(pdf|docx|xlsx|pptx|document).*to.*markdown"
---

# Markdown Converter

> Convert files to Markdown using `uvx markitdown` — no installation required.

## 用途

将各种文档格式转换为 Markdown，便于 LLM 处理或文本分析：

- **文档**: PDF, Word (.docx), PowerPoint (.pptx), Excel (.xlsx, .xls)
- **Web/数据**: HTML, CSV, JSON, XML
- **媒体**: 图片 (EXIF + OCR), 音频 (EXIF + 转录)
- **其他**: ZIP (遍历内容), YouTube URL, EPub

## 重要提示

Office 文档 (docx, pptx, xlsx) 需要额外依赖，使用 `--with` 参数：

```bash
# Office 文档必须加 --with "markitdown[docx]"
uvx --with "markitdown[docx]" markitdown input.docx -o output.md

# 其他格式可直接使用
uvx markitdown input.pdf -o output.md
```

## 工作流程

```mermaid
flowchart TD
    A[输入文件] --> B{格式检测}
    B --> C[markitdown 转换]
    C --> D[输出 Markdown]
    D --> E[保存/显示结果]
```

## 使用方法

### 基本用法

```bash
# 转换到标准输出
uvx markitdown input.pdf

# 保存到文件
uvx markitdown input.pdf -o output.md

# Office 文档需要额外依赖
uvx --with "markitdown[docx]" markitdown input.docx -o output.md
uvx --with "markitdown[docx]" markitdown input.pptx -o output.md
uvx --with "markitdown[docx]" markitdown input.xlsx -o output.md

# 从标准输入
cat input.pdf | uvx markitdown
```

### 命令行参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `input` | 输入文件路径或 URL | - |
| `-o OUTPUT` | 输出文件路径 | 标准输出 |
| `-x EXTENSION` | 提示文件扩展名（用于 stdin） | - |
| `-m MIME_TYPE` | 提示 MIME 类型 | - |
| `-c CHARSET` | 提示字符集（如 UTF-8） | - |
| `-d` | 使用 Azure Document Intelligence | False |
| `-e ENDPOINT` | Document Intelligence 端点 | - |
| `--use-plugins` | 启用第三方插件 | False |
| `--list-plugins` | 显示已安装插件 | - |

### 示例

```bash
# 转换 Word 文档（需要 --with）
uvx --with "markitdown[docx]" markitdown report.docx -o report.md

# 转换 Excel 表格（需要 --with）
uvx --with "markitdown[docx]" markitdown data.xlsx > data.md

# 转换 PowerPoint 演示文稿（需要 --with）
uvx --with "markitdown[docx]" markitdown slides.pptx -o slides.md

# 转换 PDF（无需 --with）
uvx markitdown document.pdf -o document.md

# 带文件类型提示（用于 stdin）
cat document | uvx markitdown -x .pdf > output.md

# 使用 Azure Document Intelligence 提升 PDF 提取质量
uvx markitdown scan.pdf -d -e "https://your-resource.cognitiveservices.azure.com/"

# 转换 YouTube 视频（提取字幕）
uvx markitdown "https://www.youtube.com/watch?v=VIDEO_ID" -o transcript.md
```

## 前置要求

```bash
# 需要安装 uv (Python 包管理器)
# macOS
brew install uv

# Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# markitdown 会通过 uvx 自动下载，无需单独安装
```

## 输出特点

- 保留文档结构：标题、表格、列表、链接
- 首次运行会缓存依赖，后续运行更快
- 对于复杂 PDF，使用 `-d` 配合 Azure Document Intelligence 可获得更好效果

## 相关 Skill

| Skill | 说明 |
|-------|------|
| [tech-research](../tech-research/SKILL.md) | 对转换后的内容进行深度分析 |
| [repo-analyzer](../repo-analyzer/SKILL.md) | 分析代码仓库结构 |

## 默认输出路径配置

### 方法 1: 环境变量

设置默认输出目录：

```bash
# 在 ~/.zshrc 或 ~/.bashrc 中添加
export MARKDOWN_CONVERTER_OUTPUT_DIR="$HOME/workspace/innate-revisit/km/notes"

# 使用时直接指定文件名
uvx markitdown input.pdf -o "$MARKDOWN_CONVERTER_OUTPUT_DIR/output.md"
```

### 方法 2: 快捷命令

在 Shell 配置中添加别名：

```bash
# ~/.zshrc
alias mc='cd ~/workspace/innate-revisit/km/notes && uvx markitdown'
alias mc-docx='cd ~/workspace/innate-revisit/km/notes && uvx --with "markitdown[docx]" markitdown'
alias mc-pdf='cd ~/workspace/innate-revisit/km/notes && uvx markitdown'

# 使用
mc input.pdf -o result.md
```

### 方法 3: 一键转换脚本

创建转换脚本 [scripts/convert.sh](scripts/convert.sh)：

```bash
#!/bin/bash
OUTPUT_DIR="${1:-.}"

for file in "$@"; do
    if [ "$file" = "${@: -1}" ]; then break; fi
    
    filename=$(basename "$file")
    ext="${filename##*.}"
    
    if [[ "$ext" == "docx" || "$ext" == "pptx" || "$ext" == "xlsx" ]]; then
        uvx --with "markitdown[docx]" markitdown "$file" -o "$OUTPUT_DIR/${filename%.*}.md"
    else
        uvx markitdown "$file" -o "$OUTPUT_DIR/${filename%.*}.md"
    fi
done

# 使用
./convert.sh ~/workspace/innate-revisit/km/notes/ file1.pdf file2.docx
```

## 安装

### 项目级安装

```bash
# macOS / Linux
./scripts/install.sh --project

# Windows PowerShell
.\scripts\install.ps1 -Project
```

### 系统级安装

```bash
# macOS / Linux
./scripts/install.sh --system

# Windows PowerShell
.\scripts\install.ps1 -System
```

### 指定 Agent

```bash
# 仅安装到 Trae
./scripts/install.sh --system --agent trae

# Windows
.\scripts\install.ps1 -System -Agent trae
```
