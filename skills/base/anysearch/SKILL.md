---
name: anysearch
description: 实时搜索与网页内容抽取 Skill。用于需要当前信息检索、事实核验、GitHub/文档/网页搜索、垂直领域搜索、批量搜索、URL 内容提取，或从问题出发发现相关 Skill/开源资料的任务；支持中文查询、中文总结和中文工作流说明。
version: 2.1.0
credentials:
  - name: ANYSEARCH_API_KEY
    required: false
    description: 可选 API key，用于更高限额；无 key 时可匿名访问。
    storage: .env file, environment variable, or --api_key CLI flag
---

# AnySearch

AnySearch 提供实时搜索、垂直领域搜索、批量搜索和网页 Markdown 抽取。优先用中文理解用户问题；查询词可以是中文、英文，或中英混合；最终回答默认使用用户使用的语言。

## 何时使用

- 用户需要最新信息、事实核验、资料检索、网页/文档/GitHub 搜索。
- 用户给出一个问题，希望从搜索开始做调研、发现 Skill、发现开源项目或收集证据。
- 用户需要读取某个 URL 的正文内容，而搜索摘要不够。
- 问题属于垂直领域：finance、academic、travel、health、code、legal、gaming、film、business、security、ip、energy、environment、agriculture、resource、social_media,ai,ai-agent。

## 隐私与安全

AnySearch 会把查询词、URL 和可选 API key 发送到 `https://api.anysearch.com/mcp`。不要搜索密钥、令牌、私有源码、私人身份信息或未授权的内部资料；如任务确实需要，先向用户确认。不要在对话中明文展示 API key。

## 运行方式

如果目录中存在 `runtime.conf`，优先读取其中的 `Command`。否则按当前环境选择一种 CLI：

```bash
python3 <skill_dir>/scripts/anysearch_cli.py <command> [options]
node <skill_dir>/scripts/anysearch_cli.cjs <command> [options]
bash <skill_dir>/scripts/anysearch_cli.sh <command> [options]
powershell -ExecutionPolicy Bypass -File <skill_dir>/scripts/anysearch_cli.ps1 <command> [options]
```

macOS/Linux 上如果 Python 缺少 `requests`，优先尝试 Bash CLI；Node CLI 使用 `.cjs`，避免在 ESM 项目中被当作 ESM 加载。

## 常用命令

把 `<cmd>` 替换为上面的某个运行命令。

```bash
<cmd> search "agent skills SKILL.md github workflow" --max_results 5
<cmd> batch_search --query "Codex skills" --query "Claude Code skills" --max_results 5
<cmd> extract "https://example.com/article"
<cmd> get_sub_domains --domain code
```

需要完整命令参考时运行：

```bash
<cmd> doc
```

## Markdown 抽取示例

当用户要求“打开这个网页看看”“把这篇文章转成 Markdown”“基于这个 URL 总结”时，使用 `extract` 抽取网页正文。`extract` 返回的是 Markdown，适合继续做摘要、引用要点、整理成调研笔记或写入文档。

直接抽取指定 URL：

```bash
<cmd> extract "https://example.com/article"
```

从搜索到抽取的典型流程：

```bash
<cmd> search "Mastra AI workflow agent runtime" --max_results 5
<cmd> extract "https://example.com/high-value-result"
```

用户可用的自然语言提示示例：

```text
请用 AnySearch 抽取这个页面的 Markdown，并总结核心观点：https://example.com/article
```

抽取后输出时，先说明来源 URL，再用中文总结；如果正文过长，只保留与用户问题相关的段落和证据。

## 搜索决策

1. 简单百科类问题可以直接 `search`。
2. 涉及当前信息、软件生态、GitHub、产品、法律、金融、医学、安全或专业领域时，先搜索再总结来源。
3. 垂直领域搜索前先调用 `get_sub_domains`，选择最贴近问题的 `sub_domain`，并按返回说明传入必填 `--sdp` 参数。
4. 问题跨多个领域或不确定领域时，用 `batch_search` 同时跑通用搜索和垂直搜索。
5. 搜索结果摘要不够时，对高价值 URL 使用 `extract` 获取正文，再做判断。

## Skill 发现用法

当用户从一个问题出发寻找可复用 Skill 时：

1. 把用户问题改写成 2-5 个搜索查询，覆盖问题本身、`SKILL.md`、相关 agent 名称、GitHub/open source 关键词。
2. 使用 `batch_search` 批量搜索。
3. 对疑似 Skill 仓库、文档或清单页使用 `extract`。
4. 输出候选 Skill 的名称、用途、来源、适配 agent、依赖、可信度和是否值得安装。
5. 如果本地项目已有 `skill-spark add` 或 `sync` 能安装，优先给出可执行命令。

示例：

```bash
<cmd> batch_search \
  --query "GitHub workflow AI coding agent SKILL.md" \
  --query "Codex Claude Code skills GitHub automation" \
  --query "skill-spark add skills GitHub workflow"
```

## API Key

API key 可选。优先从环境变量或 `.env` 读取：

```bash
export ANYSEARCH_API_KEY="..."
```

如果需要写入 `.env`，先询问用户。不要把 key 写进 Skill 文档、日志或最终回答。

## 失败处理

如果当前 CLI 不可用，换另一种运行方式。若 AnySearch API 无响应、限流或环境缺少必要工具，说明原因，并在继续使用其它搜索方式前告知用户。
