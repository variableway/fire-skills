# 架构、文档结构与 MVP 计划

> 对应 `tasks/issues/refactor.md` Task 1。基于 `main` @ `9f447f8`（2026-07）现状整理。

---

## 1. 项目定位

本仓库同时承担两层角色：

1. **Skill 仓库**：按 category 存放可安装的个人 / 团队 Skills。
2. **skill-spark 工具**：CLI（后续 Web / Desktop）统一完成 Skill 的搜索、安装、评估、映射与维护。

长期闭环：**Search → Install → Evaluate → Use / Optimize → Re-evaluate**。筛选过的 Skill 才能进入 registry，供应用统一管理。

---

## 2. 推荐文档结构

```
docs/
├── README.md                 # 文档入口（索引）
├── projects/                 # 项目规划（多 Agent 共享 Context）
│   ├── README.md
│   └── architecture-and-mvp.md
├── skill-spark/              # 工具：概述、安装运行
│   ├── overview.md
│   └── install-and-run.md
├── usage/                    # 面向使用者的专题指南
│   └── install-devops-skills.md
├── install-skills.md         # 通用安装/增删改脚本说明
├── research/                 # 调研（只读）
├── skill-anslysis/           # 外部 Skill 分析（只读）
└── use-case/                 # 历史用例与搜索结果（逐步收敛）

tasks/issues/                 # 可执行任务（给不同 Agent 拆分）
skills/                       # Skill 内容与 category 清单
├── categories.json           # category 注册表（人工/生成）
├── index.json                # skill 索引（人工/生成）
├── base|devops|meta|sdlc|knowledge|skill-shared/
└── ...
```

### 文档分层原则（给多 Agent）

| 层 | 位置 | 谁读 | 是否可变 |
|----|------|------|----------|
| 共享 Context | `docs/projects/` | 所有 Agent | 变更需评审 |
| 工具文档 | `docs/skill-spark/`、`docs/usage/` | 实现 / 使用 Agent | 随代码更新 |
| 任务单 | `tasks/issues/*.md` | 单个 Agent | 任务生命周期内更新 |
| Skill 本体 | `skills/**/SKILL.md` | 运行时 Agent | 独立 PR |

任务文档要求：**独立可执行**、**依赖显式写出**、**不复制整份架构**（只链到本文件）。

---

## 3. 技术架构（当前）

### 3.1 Monorepo 包

| 包 | 路径 | 职责 |
|----|------|------|
| CLI | `packages/skill-cli` | Commander 命令、TUI、输出 |
| Core | `packages/skill-core` | 发现、源解析、安装、映射、校验、inspect、state |
| Schemas | `packages/skill-schemas` | Zod 模式与共享类型 |

运行时：**Bun** 构建 / 执行；包管理：**pnpm workspace**；语言：**TypeScript**。

### 3.2 CLI 命令分组（已落地）

```
packages/skill-cli/src/commands/
├── skill/          # add, list, remove, update, validate, inspect, use
├── search/         # search / find
├── map-sync/       # map, sync
├── agent/          # agent list|add|remove|schema
├── profile/        # profile CRUD + install
├── doctor/
└── shared/         # 选项类型、格式化、CommandMeta
```

用户侧命令未改名：`search|add|update|outdated|remove|list|validate|inspect|use|profile|map|sync|agent|doctor`。

### 3.3 Skill 仓库 Category（registry 雏形）

当前目录约定：

| Category | 路径 | 受众倾向 |
|----------|------|----------|
| base | `skills/base` | 全员（anysearch、skill-spark） |
| devops | `skills/devops` | 开发者工作流 |
| meta | `skills/meta` | Skill 作者 |
| sdlc | `skills/sdlc` | 开发（含 frontend 等子类） |
| knowledge | `skills/knowledge` | 非纯开发场景也可 |
| skill-shared | `skills/skill-shared` | 跨类复用 |

清单文件：`skills/categories.json`、`skills/index.json`（可手工维护，后续由 CLI 生成）。

### 3.4 安装与工作流脚本

| 脚本 | 作用 |
|------|------|
| `bun run build` / `build:exe` / `build:all` | 构建 CLI |
| `bun run build:install` → `scripts/build-install.sh` | 构建并安装到 `~/.local/bin` |
| `scripts/dev-workflow.sh` | DevOps git/local workflow 安装/校验 |
| `scripts/install.sh` 等 | add/remove/update 封装 |

---

## 4. 已实现能力（盘点）

### 已可用（手工 / CLI）

- [x] 多源安装：local / git / well-known / directory / registry
- [x] 项目级 / 全局安装；symlink / copy
- [x] 多 Agent 目录映射与自定义 agent 配置
- [x] validate / inspect（结构 + 风险规则评分）
- [x] list / outdated / update / remove + `skills.lock`
- [x] profile 组合安装；map / sync
- [x] doctor 环境诊断
- [x] DevOps skills 安装指南与 `dev-workflow` 脚本
- [x] CLI 按功能目录重组 + shared 元数据

### 部分落地 / 草稿

- [~] Category registry：`categories.json` / `index.json` 与各目录 README frontmatter 已有样例；**生成 CLI 尚未合入 main**
- [~] knowledge 类 skill（如 thought-distiller）目录整理中
- [~] Web / Desktop 应用：未开工

### 未实现（MVP 之后）

- [ ] 远程 registry 服务与审核流水线
- [ ] 使用后自动再评估与优化闭环
- [ ] 多 Agent 任务调度看板（谁在跑哪个 task）
- [ ] 正式评测集与 CI gate

---

## 5. MVP 范围与任务拆分

MVP 目标：**人可以手工完成「分类 → 索引 → 安装 → 校验」闭环；关键步骤有 CLI 脚本可重复执行。** 不做 Web/Desktop。

### MVP-0：文档与约定（本任务）

| ID | 任务 | 依赖 | 验收 |
|----|------|------|------|
| M0.1 | 固化 `docs/` 分层与本架构文档 | — | 本文档合并 |
| M0.2 | README 链接到 skill-spark / projects / usage | M0.1 | 新人 5 分钟能找到入口 |

### MVP-1：Category Registry（手工 → 半自动）

| ID | 任务 | 依赖 | 验收 |
|----|------|------|------|
| M1.1 | 各 category `README.md` frontmatter（name/icon/order）齐全 | M0 | 与 `categories.json` 字段一致 |
| M1.2 | 手工或脚本生成 `skills/categories.json` + `skills/index.json` | M1.1 | `count` / `skillCount` 与磁盘一致 |
| M1.3 | CLI：`categories` / `index --write`（复用 stash 中 categories 原型） | M1.2 | `pnpm categories` / `pnpm index` 可写回清单 |
| M1.4 | 文档：registry 字段说明 + Agent 使用约定 | M1.3 | `docs/skill-spark/` 或 `docs/usage/` 有专节 |

### MVP-2：筛选闭环（手工可跑）

| ID | 任务 | 依赖 | 验收 |
|----|------|------|------|
| M2.1 | 对仓库内全部 skill 跑 `validate` + `inspect`，输出报告目录 | M1 | 报告可归档到 `docs/` 或 `tasks/` |
| M2.2 | 定义「准入」门槛（risk / quality / portability 阈值） | M2.1 | 写在 projects 文档，index 可标记 status |
| M2.3 | Profile：至少 1 个官方 profile（如 devops-minimal） | M2.2 | `skill-spark profile install` 一键装齐 |

### MVP-3：工具化与可重复安装

| ID | 任务 | 依赖 | 验收 |
|----|------|------|------|
| M3.1 | 统一推荐入口：`build:install` + `docs/skill-spark/install-and-run.md` | M0 | Windows / macOS 各验证一次 |
| M3.2 | DevOps 一键：`scripts/dev-workflow.sh` 与 usage 文档对齐 | M3.1 | 文档命令可复制执行 |
| M3.3 | CI：typecheck + 对 `skills/**` 跑 validate（非阻塞 warning） | M2.1 | PR 可见结果 |

### 明确不在 MVP

- Web / Desktop UI
- 远程审核后台
- 自动「再评估」流水线（可只留手工 checklist）

---

## 6. 多 Agent 协作约定（简版）

1. **共享 Context**：只维护 `docs/projects/` + 本仓库 README；任务里用链接，不粘贴全文。
2. **任务独立性**：一个 `tasks/issues/*.md` 对应一个 Agent 会话；标题含 MVP ID（如 `M1.3`）。
3. **依赖**：任务正文写 `Depends-on: M1.2`；无依赖的可并行。
4. **追踪**：优先用现有 `local-workflow` / `git-workflow` skill 记 tracing；后续再做「Agent ↔ Task」看板。
5. **冲突面**：`packages/**` 与 `skills/categories.json` 同一时间只允许一个 Agent 改。

---

## 7. 可行性结论

| 维度 | 判断 |
|------|------|
| 技术 | CLI + core 已覆盖安装/校验主路径，MVP 主要是 **registry 元数据 + 文档/脚本固化**，风险低 |
| 组织 | 多 Agent 可行，前提是任务按 MVP ID 拆分且共享 Context 单一来源 |
| 产品 | Web/Desktop 延后正确；先证明「筛选过的 skill 清单」有价值 |
| 建议下一步 | 执行 **M1.1 → M1.3**（category 元数据与生成 CLI），再跑 **M2.1** 全量 inspect |

---

## 相关链接

- [skill-spark 概述](../skill-spark/overview.md)
- [安装与运行](../skill-spark/install-and-run.md)
- [DevOps Skills 安装](../usage/install-devops-skills.md)
- [通用 Install 指南](../install-skills.md)
- 任务来源：`tasks/issues/refactor.md`
