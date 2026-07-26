# Skill CLI Commands

关于Skill CLI 命令行的需求和编写说明.


## 一、完整命令清单

共 **14 个顶级命令**（含子命令共 **22 个操作**）。

### 技能管理

| 命令 | 别名 | 实现 | 行数 |
|------|------|------|------|
| `add <source>` | `a`, `install`, `i` | [skill/add.ts](../../packages/skill-cli/src/commands/skill/add.ts) | 543 |
| `remove [skills...]` | `r`, `rm`, `uninstall` | [skill/remove.ts](../../packages/skill-cli/src/commands/skill/remove.ts) | 89 |
| `update [skills...]` | `u` | [skill/update.ts](../../packages/skill-cli/src/commands/skill/update.ts) | 199 |
| `outdated [skills...]` | `o`, `status` | 同上 | — |
| `list` | `l` | [skill/list.ts](../../packages/skill-cli/src/commands/skill/list.ts) | 58 |
| `validate <path-or-source>` | — | [skill/validate.ts](../../packages/skill-cli/src/commands/skill/validate.ts) | 121 |
| `inspect <path-or-source>` | — | [skill/inspect.ts](../../packages/skill-cli/src/commands/skill/inspect.ts) | 166 |
| `use <path-or-source>` | — | [skill/use.ts](../../packages/skill-cli/src/commands/skill/use.ts) | 105 |

### 搜索发现

| 命令 | 别名 | 实现 | 行数 |
|------|------|------|------|
| `search [query]` | `s` | [search/index.ts](../../packages/skill-cli/src/commands/search/index.ts) | 301 |
| `find [query]` | — | 同上（同 search） | — |

### 同步映射

| 命令 | 别名 | 实现 | 行数 |
|------|------|------|------|
| `map` | — | [map-sync/map.ts](../../packages/skill-cli/src/commands/map-sync/map.ts) | 73 |
| `sync` | — | [map-sync/sync.ts](../../packages/skill-cli/src/commands/map-sync/sync.ts) | 174 |

### Agent 配置

| 命令 | 别名 | 实现 | 行数 |
|------|------|------|------|
| `agent list` | `agents list` | [agent/index.ts](../../packages/skill-cli/src/commands/agent/index.ts) | 177 |
| `agent schema` | — | 同上 | — |
| `agent add <name>` | — | 同上 | — |
| `agent remove <name>` | — | 同上 | — |

### Profile 管理

| 命令 | 别名 | 实现 | 行数 |
|------|------|------|------|
| `profile add <name>` | — | [profile/index.ts](../../packages/skill-cli/src/commands/profile/index.ts) | 117 |
| `profile list` | — | 同上 | — |
| `profile show <name>` | — | 同上 | — |
| `profile install <name>` | — | 同上 | — |

### 诊断与工具

| 命令 | 别名 | 实现 | 行数 |
|------|------|------|------|
| `doctor` | — | [doctor/index.ts](../../packages/skill-cli/src/commands/doctor/index.ts) | 171 |
| `docx-to-md` | — | [docx/index.ts](../../packages/skill-cli/src/commands/docx/index.ts) | 17 |

---

## 二、命令评分与评估

评分标准（1-5）：
- **5** — 生产级：功能完整、错误处理健壮、边缘情况覆盖、代码质量高
- **4** — 良好：核心功能完善、有小改进空间
- **3** — 可用：基本功能可用、缺失关键特性或存在轻微问题
- **2** — 需改进：功能薄弱、有明显 gap 或 bug
- **1** — 原型级：仅最小可行、需要重写

### ★★★★☆ 良好（4 分）

| 命令 | 评分 | 优势 | 改进建议 |
|------|------|------|----------|
| **add** | 4 | 安装流程完整，交互体验好，支持 filtering/silent/global/symlink，try/finally cleanup | 无逐项安装进度条，`resolveSourceInput` 查找失败直接 `process.exit(1)`，universal agents 静默替换逻辑让用户困惑 |
| **validate** | 4 | 代码简洁干净，多格式输出（text/json/md），`--strict` 模式，resolveSkillTargets 抽象好 | 无修复建议提示，无 `--ignore` 跳过特定规则码 |
| **agent** | 4 | 结构清晰，slug 验证严格，内置/自定义 agent 隔离分明，JSON 输出完善 | 缺少 `agent show`、`agent update`，未验证目录路径有效性 |

### ★★★☆☆ 可用（3 分）

| 命令 | 评分 | 优势 | 改进建议 |
|------|------|------|----------|
| **update** | 3 | 完整的 outdated→diff→confirm→reinstall 流程，per-item 错误不中断批量 | 无 `--dry-run` / `--rollback`，`latestCommit` 空值时锁定永不更新（perpetual outdated bug），无版本锁定 |
| **inspect** | 3 | 风险规则覆盖 9 种模式，质量/可移植性双评分 | `--mode` 仅支持 `rules`，LLM 模式未实现，`--via-skill` 未实现 |
| **use** | 3 | resolveSkillTargets + inspection 集成好，多格式输出 | markdown/text 格式输出完全相同（无独立 markdown 函数），JSON 中 `description` 为 `undefined` 导致格式不一致，无模板 |
| **search** | 3 | 多源搜索（registry + directory + local），交互式选择 + 直接安装链 | 无模糊搜索，结果上限 20 硬编码，`--output` 时仍打印终端输出，dedup 可能丢弃不同源的本地技能 |
| **sync** | 3 | 完整的 discover→filter→install→track 流程，路径去重，JSON 输出含 per-skill/agent 结果 | `--yes` 参数定义了但从未读取，无 `--dry-run`，无效路径静默传递到 downloadSource |
| **doctor** | 3 | 根目录检测 + agent 目录检查 + 交互式修复 | 仅检查 project 路径不检查 global，summary 比例误导（installed agents 全算 passed），路径解析 `cwd` 不一致 |

### ★★☆☆☆ 需改进（2 分）

| 命令 | 评分 | 优势 | 改进建议 |
|------|------|------|----------|
| **remove** | 2 | `type:name` 语法灵活，per-item 确认 | **Bug**: 仅移除 project 目录，global 文件从不触碰；tracking 清理了 global 但文件完好，状态不一致。无 `--all` / `--dry-run` / orphan 检测 |
| **list** | 2 | 按 scope 分组展示 | 无 JSON / verbose 模式，不显示版本/commit/source URL，不调用 hydrateTracked（看不到更新状态），`validInstallations` 为 undefined 时可能崩溃 |
| **map** | 2 | 三种 source base 配置灵活 | 无过滤器/预览/dry-run，错误静默吞掉 `catch {}`，包含隐藏目录，无去重/清理 |
| **profile** | 2 | JSON 存储 + Zod schema 校验 | **Bug**: `profile.targetAgents` 被忽略（`agent: agents.length > 0 ? agents : undefined`），install 永远 auto-confirm。缺少 `remove` / `edit`，无批量错误汇总 |
| **docx-to-md** | 2 | 功能实现干净 | 无输入校验（文件是否存在、是否为 .docx），无 `--overwrite` 检查，无批量转换。`convertDocxToMarkdown` 抛出时导致 unhandled promise rejection |

---

## 三、整体统计

```
评分分布:
  5 分: 0 个
  4 分: 3 个  (add, validate, agent)
  3 分: 6 个  (update, inspect, use, search, sync, doctor)
  2 分: 5 个  (remove, list, map, profile, docx-to-md)

总代码量: ~2,399 行
```

## 四、优先修复建议

按影响程度排序：

### P0 — 功能性 Bug

1. **remove**: Global 范围的文件从不删除，tracking 与文件系统状态不一致
2. **profile**: `profile.targetAgents` 被静默忽略，install 无法使用 profile 预设的 targets
3. **update**: `latestCommit` 为空时锁定永不更新

### P1 — 体验缺口

4. **list**: 缺少 `--json` / `--verbose`，信息展示过于简陋
5. **map/sync**: 无 `--dry-run` 模式，用户无法预知操作结果
6. **search**: 终端输出在 `--output` 模式下不应显示

### P2 — 功能增强

7. **profile**: 添加 `remove` / `edit` 子命令
8. **agent**: 添加 `show` / `update` 子命令
9. **inspect**: 实现 `--mode llm` LLM 辅助检查模式
10. **docx-to-md**: 添加输入校验、批量转换、`--format` 选项
