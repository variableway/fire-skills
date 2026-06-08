# AnySearch Skill 解读与 search CLI 集成分析

日期：2026-06-08

## 1. 结论

AnySearch Skill 可以加入当前项目，但建议分成两个角色处理：

```text
角色 A：作为 Agent Skill 安装给 Codex/Claude/Cursor 使用
角色 B：作为 skill-spark search/discover 的外部搜索源
```

它不应该替代当前 `searchRegistry` 和 `listDirectory`，因为 AnySearch 返回的是 Web 搜索结果，而不是标准化的 Skill registry item。更好的做法是：

1. 保留现有 `search` 的 registry + directory 搜索。
2. 增加可选 source：`anysearch`。
3. 用 AnySearch 做 “Web 发现 / GitHub Skill 发现 / 文档发现”。
4. 把 AnySearch 结果转换成 discovery candidate，而不是直接当成可安装 Skill。
5. 后续在 `discover -> inspect` 流程中，对 AnySearch 搜到的 GitHub URL 再做 `SKILL.md` 预览和风险审查。

## 2. AnySearch Skill 解读

项目中 AnySearch 已整理为 base skill，位于：

```text
skills/base/anysearch/
```

核心文件：

```text
SKILL.md
README.md
runtime.conf.example
scripts/anysearch_cli.py
scripts/anysearch_cli.cjs
scripts/anysearch_cli.sh
scripts/anysearch_cli.ps1
```

`SKILL.md` frontmatter：

```yaml
name: anysearch
description: Real-time search engine supporting web search, vertical domain search, parallel batch search, and URL content extraction.
version: 2.1.0
credentials:
  - name: ANYSEARCH_API_KEY
    required: false
```

它提供四类能力：

| 能力 | 命令 | 说明 |
| --- | --- | --- |
| 单查询搜索 | `search` | 通用 Web 或垂直领域搜索 |
| 批量搜索 | `batch_search` | 2-5 个查询并行搜索 |
| 页面抽取 | `extract` | 读取 URL 内容，输出 Markdown |
| 垂直领域发现 | `get_sub_domains` | 查询 finance/code/legal/academic 等领域 subdomain |

它适合触发的场景：

- 当前信息检索。
- 事实核验。
- URL 内容提取。
- 垂直领域搜索，例如 finance、academic、code、legal、security。
- 多意图并行搜索。

## 3. 当前实测结果

### 3.1 可以通过 GitHub 源安装

远程源可被当前 `add` 识别：

```bash
bun src/index.ts add anysearch-ai/anysearch-skill --list --silent
```

输出能发现：

```text
skill:anysearch
```

所以如果使用远程 repo，当前安装路径是通的：

```bash
bun src/index.ts add anysearch-ai/anysearch-skill --agent codex --yes
```

### 3.2 本地 base skills 路径可以直接安装

本地目录 source 已支持。当前运行：

```bash
bun src/index.ts add skills/base --list --silent
```

会直接从本地目录发现：

```text
skill:anysearch
```

实现方式是在 `downloadSource` 前判断 source 是否是已经存在的本地路径：

```text
if source path exists -> SourceBundle(kind: "local", root: resolvedPath, cleanup: no-op)
```

### 3.3 CLI runtime 有环境兼容问题

当前环境测试结果：

| Runtime | 结果 | 原因 |
| --- | --- | --- |
| Python | 失败 | 缺少 `requests` |
| Node.js | 失败 | 项目 `package.json` 是 `type: module`，但脚本使用 CommonJS `require` |
| Bash | 成功 | 依赖 `curl` + `jq`，当前可用 |

Bash 版实际搜索成功：

```bash
bash skills/base/anysearch/scripts/anysearch_cli.sh search "agent skills SKILL.md github workflow" --max_results 3
```

返回了 agent skills 相关 GitHub 页面和文档。这说明 AnySearch 可以作为外部 discovery source 使用。

## 4. 与当前 search CLI 的关系

当前 `src/commands/search.ts` 搜索来源只有两个：

```text
searchRegistry(searchParams, options.registry)
listDirectory()
```

它的输出类型是 `SkillListItem[]`，适合展示 Skill registry item：

```typescript
interface SkillListItem {
  schemaVersion: string;
  slug: string;
  name: string;
  description: string;
  repository: string;
  verified?: boolean;
  stars?: number;
  tags?: string[];
}
```

AnySearch 输出不是这个结构，而是 Markdown 搜索结果：

```text
### 1. Title
- URL: https://...
- snippet...
```

所以直接把 AnySearch 混进 `SkillListItem` 会有信息损失。更合适的是新增统一的 search source result：

```typescript
type SearchSourceKind = "registry" | "directory" | "gh-skill" | "anysearch";

interface SearchSourceResult {
  source: SearchSourceKind;
  title: string;
  description: string;
  url?: string;
  repository?: string;
  path?: string;
  installable?: boolean;
  raw?: unknown;
}
```

然后在 `search` 命令里分层展示：

```text
Registry skills
Directory skills
GitHub skill results
AnySearch web discoveries
```

## 5. 推荐集成方式

### 5.1 MVP 集成

新增 `--source` 或 `--sources`：

```bash
skill-spark search "github workflow" --sources registry,directory,anysearch
```

或者：

```bash
skill-spark search "github workflow" --anysearch
```

行为：

1. 原有 registry/directory 搜索照常运行。
2. 如果启用 AnySearch，调用 AnySearch CLI 做 Web 搜索。
3. 将 AnySearch 搜索结果作为 “discovery hints” 输出。
4. 不自动安装 AnySearch 搜到的 URL。
5. 对 GitHub URL 尝试解析 `repo/path`，交给后续 `inspect`。

### 5.2 更产品化的 discover 集成

在 `solve/discover` 工作流中使用 AnySearch：

```text
problem
  -> query planner
  -> registry source
  -> directory source
  -> gh skill source
  -> anysearch source
  -> candidate normalization
  -> inspect
```

AnySearch 在这里的价值是补充：

- 搜到 registry 没收录的 Skill。
- 搜到 GitHub 上的 Skill 文章和规范文档。
- 搜到类似项目、awesome 列表、example repo。
- 对 `gh skill search` 结果做交叉验证。

## 6. 需要修改的模块

### 6.1 支持本地 source 安装

文件：

```text
src/core/sources.ts
```

任务：

1. 在 `downloadSource` 前判断 source 是否是本地路径。
2. 如果 `existsSync(resolve(source))`，返回 local `SourceBundle`。
3. `cleanupSource` 对 local bundle no-op。
4. `kind` 增加 `local`。

收益：

```bash
skill-spark add skills/base --skill anysearch --agent codex --yes
```

可以安装本仓库 reference skill。

### 6.2 增加 AnySearch adapter

文件建议：

```text
src/core/search-sources/anysearch.ts
```

任务：

1. 查找 AnySearch skill 路径：
   - `skills/base/anysearch`
   - `.agents/skills/anysearch`
   - global Codex/Claude skills path
2. 检测可用 runtime：
   - 优先 Bash in project，避免 Node ESM 问题。
   - 如果 Python 有 `requests`，可用 Python。
   - Node 版需要绕开 `type: module` 或改 `.cjs`，不建议作为项目内默认。
3. 执行搜索命令。
4. 解析 Markdown 结果为 `SearchSourceResult[]`。
5. 出错时返回 warning，不阻断主搜索。

### 6.3 修改 search CLI

文件：

```text
src/commands/search.ts
```

任务：

1. 新增选项：

```text
--sources <list>     registry,directory,anysearch
--anysearch          include AnySearch web discovery
```

2. 并发执行 registry/directory/anysearch。
3. 输出 source counts。
4. JSON output 中增加 `sources` 或 `web` 字段。
5. 保持现有默认行为不变。

### 6.4 在 solve/discover 中使用

后续 `solve` 命令中，AnySearch 应默认作为候选 source 之一，但只作为辅助，不是主 registry：

```text
default sources = local,registry,gh-skill,anysearch
```

## 7. 安全和隐私边界

AnySearch 会把 query 和 URL 发到：

```text
https://api.anysearch.com/mcp
```

因此要做这些限制：

1. 不用 AnySearch 搜索 secrets、个人信息、token、私有代码内容。
2. `search --anysearch` 第一次使用时提示外部请求。
3. 支持 `--no-web` 或配置禁用外部搜索。
4. API key 只从 env 或 skill `.env` 读取，不在聊天或日志中打印。
5. AnySearch 结果只作为候选线索，不能直接自动安装。

## 8. 是否值得加入

建议加入，但分阶段：

### 阶段 1：作为可安装 Skill

优先使用远程安装：

```bash
skill-spark add anysearch-ai/anysearch-skill --agent codex --yes
```

同时改进 local source 支持，允许：

```bash
skill-spark add skills/base --skill anysearch --agent codex --yes
```

### 阶段 2：作为 search CLI 可选 source

增加：

```bash
skill-spark search "github workflow" --anysearch
```

输出 AnySearch web discovery hints。

### 阶段 3：作为 discover/solve 默认辅助源

在最小目标 `solve` 中：

```bash
skill-spark solve "如何自动化本地开发的 GitHub 流程"
```

自动并行调用 registry、directory、gh skill、AnySearch，再由 inspect 降噪。

## 9. 推荐最小实现任务

1. `src/core/sources.ts` 增加 local source support。
2. `src/core/search-sources/anysearch.ts` 增加 AnySearch adapter。
3. `src/commands/search.ts` 增加 `--anysearch`。
4. JSON 输出增加：

```json
{
  "query": "github workflow",
  "registry": 5,
  "directory": 0,
  "anysearch": 3,
  "skills": [],
  "web": []
}
```

5. README 增加说明：AnySearch 是外部 Web discovery source，会访问 `api.anysearch.com`。
6. 测试：

```bash
bun src/index.ts search "agent skills github workflow" --anysearch --limit 3 -o /tmp/search.json
```

## 10. 最终判断

AnySearch 很适合当前 Skill Manager 的“发现”阶段，但应该被放在正确位置：

```text
AnySearch = external web discovery source
gh skill search = GitHub SKILL.md source
registry = installable skill source
directory = curated skill source
inspect = 降噪和风险判断
```

这样加入 AnySearch 后，`search` CLI 不只是“查已有 registry”，还能帮助发现 registry 之外的 Skill、规范文档、awesome 列表和相似项目。它会直接增强当前最小目标里的 `discover -> inspect -> recommendation -> task-packet` 链路。
