---
name: repo-analyzer
description: |
  代码仓库语义分析 Skill。
  克隆任意 GitHub / 本地代码仓库，结合 CodeGraph（可选）和静态扫描，
  生成结构化的仓库分析报告：技术栈、架构、入口点、关键模块、调用关系、路由映射等。
  分析结果默认归档到 ~/innate-revisit/analysis/repo/<repo-name>/，便于跨会话复用。
  TRIGGER: When user asks to "/analyze-repo", "分析仓库", "分析代码", "解读仓库", or wants to understand an unfamiliar codebase.
type: skill
supported_agents:
  - claude-code
  - codex
  - cursor
  - opencode
tags:
  - analysis
  - codegraph
  - repo
  - reverse-engineering
triggers:
  - pattern: "^/(analyze-repo|repo-analyze|分析仓库|解读仓库)"
  - pattern: "(分析|解读|理解|拆解).*(仓库|代码库|repo|codebase)"
---

# Repo Analyzer Skill

> 一个仓库一份「可复用的语义地图」。受 [CodeGraph](https://github.com/colbymchenry/codegraph) 启发。

## 用途

面对一个陌生的代码仓库（VS Code、Django、Tokio、自家 monorepo……）时，本 Skill 会：

1. 克隆仓库（或读取本地路径）
2. **优先调用 [CodeGraph](https://github.com/colbymchenry/codegraph)** 构建语义索引（如已安装）
3. 回退到静态扫描：语言识别、依赖解析、入口检测、目录摘要
4. 生成结构化分析报告：技术栈 / 架构 / 入口点 / 关键模块 / 调用图 / 路由表
5. **将分析归档到默认目录** `~/innate-revisit/analysis/repo/<repo-name>/`，下次再问同一个仓库可以秒查

## 默认输出目录

```
~/innate-revisit/analysis/repo/<repo-name>/
├── README.md             # 总览（人类阅读的入口）
├── analysis.md           # 完整分析报告
├── tech-stack.md         # 技术栈明细
├── architecture.md       # 架构图 + 模块边界
├── entry-points.md       # 入口、CLI、路由、API
├── codegraph/            # CodeGraph 输出（如可用）
│   ├── symbols.json
│   ├── routes.json
│   └── call-graph.json
├── metadata.json         # { repo_url, commit_sha, indexed_at, ... }
└── snippets/             # 关键源码截取（标注来源行号）
```

可通过 `--output` 覆盖默认目录。

## 使用方法

### 命令行

```bash
# 分析远程 GitHub 仓库（默认输出到 ~/innate-revisit/analysis/repo/<repo-name>/）
python .claude/skills/repo-analyzer/scripts/analyze_repo.py https://github.com/colbymchenry/codegraph

# 分析本地仓库
python .claude/skills/repo-analyzer/scripts/analyze_repo.py /path/to/local/repo

# 自定义输出目录
python .claude/skills/repo-analyzer/scripts/analyze_repo.py <repo> --output ./my-analysis

# 强制重新分析（默认会跳过已存在的分析目录）
python .claude/skills/repo-analyzer/scripts/analyze_repo.py <repo> --force

# 跳过 CodeGraph，只做静态扫描
python .claude/skills/repo-analyzer/scripts/analyze_repo.py <repo> --no-codegraph

# 仅输出 metadata.json（轻量探测）
python .claude/skills/repo-analyzer/scripts/analyze_repo.py <repo> --probe
```

### 参数

| 参数 | 说明 | 默认 |
|------|------|------|
| `source` | 仓库 URL 或本地路径（必填） | - |
| `--output`, `-o` | 输出目录 | `~/innate-revisit/analysis/repo/<repo-name>` |
| `--force`, `-f` | 重新分析覆盖已有结果 | False |
| `--no-codegraph` | 跳过 CodeGraph 索引步骤 | False |
| `--probe` | 仅探测元数据，不生成完整报告 | False |
| `--depth` | git clone 深度 | 1 |
| `--keep-clone` | 保留克隆目录（默认分析后删除） | False |

## 工作流程

```mermaid
flowchart TD
    A([输入仓库]) --> B{已分析过?}
    B -- 是且无 --force --> Z([读取缓存])
    B -- 否 --> C[克隆 / 定位]
    C --> D[元数据探测<br/>语言/规模/依赖]
    D --> E{codegraph 可用?}
    E -- 是 --> F[codegraph init -i<br/>生成 .codegraph/]
    E -- 否 --> G[静态扫描<br/>tree-sitter / ripgrep]
    F --> H[导出 symbols/routes/call-graph]
    G --> H
    H --> I[生成 Markdown 报告]
    I --> J[写入 metadata.json]
    J --> Z
```

## 分析报告内容

### `analysis.md` 章节模板

1. **仓库元数据** — URL / commit / 语言分布 / 文件数 / LOC
2. **一句话概述** — 这个仓库是做什么的
3. **技术栈** — 语言、框架、构建工具、运行时
4. **目录结构** — 顶层目录及其作用
5. **入口点** — `main()` / CLI / HTTP 路由 / package 导出
6. **核心模块** — 按调用频次和依赖度排序的关键文件
7. **依赖关系** — 第三方依赖 + 内部模块依赖图
8. **路由表**（如适用）— 框架感知的 URL → handler 映射
9. **关键概念词典** — 仓库内反复出现的术语
10. **下一步建议** — 如果要二次开发/集成，应该先读哪些文件

### `metadata.json` 字段

```json
{
  "repo_url": "https://github.com/...",
  "repo_name": "codegraph",
  "commit_sha": "abc123...",
  "indexed_at": "2026-05-24T10:00:00Z",
  "primary_language": "TypeScript",
  "language_breakdown": { "TypeScript": 0.87, "JavaScript": 0.10 },
  "file_count": 423,
  "loc": 51823,
  "codegraph_available": true,
  "frameworks": ["Express", "MCP"],
  "entry_points": ["src/cli.ts", "src/server/mcp.ts"]
}
```

## CodeGraph 集成

如果检测到 `codegraph` 在 PATH 上，Skill 会：

1. 在克隆目录运行 `codegraph init -i --yes`（生成 `.codegraph/` 索引）
2. 调用 CodeGraph 的 SQLite 索引导出：
   - `symbols.json` — 所有符号节点（functions / classes / methods）
   - `routes.json` — 框架感知的路由映射（Django/Flask/Express/...）
   - `call-graph.json` — `callers` / `callees` 关系
3. 在 `analysis.md` 中链接到这些产物

未安装时，提示安装命令：

```bash
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
# 或
npm i -g @colbymchenry/codegraph
```

并继续用 ripgrep + 启发式规则做退化版分析。

## 缓存与复用

- 同一个仓库（按 `repo_url` + `commit_sha` 判定）默认**不会重复分析**
- 后续会话中可直接读取 `~/innate-revisit/analysis/repo/<repo-name>/analysis.md`
- Claude 在回答「这个仓库怎么工作」时，应**先检查该目录是否已有分析**

## 与其他 Skill 的关系

- 与 `tech-research` 互补：`tech-research` 解决「该用什么技术」，本 Skill 解决「这份代码怎么工作」
- 与 `awesome-analyzer` 不同：后者解析 awesome list 的 README，本 Skill 解析真实代码
- 与 `project-analysis-skill` 不同：后者从需求 → 设计，本 Skill 从代码 → 反向理解

## 示例

```bash
# 第一次分析（约 30-90s，取决于仓库大小）
$ python .claude/skills/repo-analyzer/scripts/analyze_repo.py https://github.com/colbymchenry/codegraph

📥 Cloning colbymchenry/codegraph...
🔍 Detecting tech stack... TypeScript (87%) + Node.js
✅ CodeGraph found, building index... (12.3s)
📊 Generating analysis report...
✅ Done → ~/innate-revisit/analysis/repo/codegraph/

# 第二次（已缓存）
$ python .claude/skills/repo-analyzer/scripts/analyze_repo.py https://github.com/colbymchenry/codegraph

ℹ Cached analysis at ~/innate-revisit/analysis/repo/codegraph/ (use --force to re-run)
```

## 参考

- [CodeGraph](https://github.com/colbymchenry/codegraph) — 本 Skill 的底层语义索引引擎
- [tree-sitter](https://tree-sitter.github.io/) — 退化模式下的语法解析
- [ripgrep](https://github.com/BurntSushi/ripgrep) — 文本检索
