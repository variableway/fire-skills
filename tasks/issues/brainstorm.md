# Top 5 Brainstorm Skills for Software Product Ideation

> 调研时间：2026-06-04
> 适用场景：软件产品构思、功能规划、架构设计
> 调研来源：Miro、Optimizely、Aha!、Conceptboard、Storyflow 等行业最佳实践

---

## 为什么需要结构化 Brainstorm 方法？

传统的"自由发散式头脑风暴"（free-form brainstorming）在软件产品领域存在三个致命缺陷：

1. **认知偏差** — 声音大的人主导方向，内向者的深度思考被淹没
2. **过早收敛** — 团队往往在问题尚未被充分理解时就急于寻找解决方案
3. **缺乏行动性** — 产生大量想法但无法转化为可执行的产品决策

以下五种结构化 brainstorm 方法，分别解决上述问题中的一个或多个，组合使用可形成完整的产品构思工作流。

---

## 1. First Principles Thinking（第一性原理思维）

### 定义
将问题拆解到最基本、不可再约简的事实（fundamental truths），然后从这些事实出发重新构建解决方案，而非基于类比或既有经验进行推理。

### 核心步骤
```
识别既有假设 → 追问"为什么是这样" → 剥离所有类比和惯例
→ 定义不可再约简的基本事实 → 从零构建新解
```

### 在软件开发中的应用
- **需求分析**：不问"竞品怎么做的"，而是问"用户要解决的根本问题是什么"
- **架构设计**：不被"微服务/单体"等标签束缚，从系统约束（吞吐量、一致性、团队规模）出发推导架构
- **技术选型**：不从"大家都在用"出发，而是从"我们的性能/维护/学习成本约束"出发

### 适用阶段
产品方向探索、架构顶层设计、技术债务重构

### 优点
- 突破行业惯例的束缚，产生真正创新的方案
- 避免"这是行业标准做法"的惯性思维

### 缺点
- 时间成本高，不适合日常迭代决策
- 需要团队具备足够的领域知识才能识别真正的"基本事实"

---

## 2. SCAMPER（系统化创新七维法）

### 定义
通过 7 个维度的结构化提问，对现有产品/功能进行系统化改进，产生新的产品概念。

### 七维提问框架

| 维度 | 英文 | 核心问题 | Capture 项目应用示例 |
|------|------|----------|---------------------|
| S | Substitute（替代） | 什么可以被替换？ | 用 GitHub Project 替代飞书多维表格作为进度源？ |
| C | Combine（组合） | 什么可以合并？ | 将 CLI 命令与 TUI 看板合并为统一交互界面？ |
| A | Adapt（适应） | 从哪里借鉴？ | 借鉴 Linear/Jira 的 Issue 工作流设计？ |
| M | Modify（修改） | 可以改变什么？ | 将 Task 的阶段流从固定改为可配置的？ |
| P | Put to another use（另作他用） | 还有什么用途？ | 用 Capture 的 Markdown 存储引擎管理产品 PRD 文档？ |
| E | Eliminate（消除） | 可以去掉什么？ | 去掉飞书同步，专注本地 GitHub 集成？ |
| R | Reverse（反转） | 可以反转什么？ | 从"用户创建任务"反转为"AI 自动识别待办事项"？ |

### 适用阶段
功能迭代、竞品分析后的差异化设计、现有功能的深度优化

### 优点
- 系统化覆盖所有改进方向，避免遗漏
- 每个维度都有明确的提问模板，降低发散门槛

### 缺点
- 聚焦在"改进"而非"颠覆"，适合迭代而非从 0 到 1
- 7 个维度全部执行耗时较长，建议每次聚焦 2-3 个维度

---

## 3. Starbursting（星爆提问法）

### 定义
以中心主题为原点，围绕 **Who/What/Why/Where/When/How** 六个维度生成问题（而非答案），确保在投入开发前对问题空间有全面理解。

### 六维提问结构

```
                Who 谁会使用/维护/受影响？
                   ↑
    What 要解决什么核心问题？  →  ★中心主题★  ←  How 如何衡量成功/失败？
                   ↓
    Where 在哪里使用/部署？    Why 为什么现在做？
                   ↓
                When 什么时候发布/迭代？
```

### Capture 项目的 Starbursting 示例

| 维度 | 关键问题 |
|------|----------|
| **Who** | 目标用户是独立开发者、小团队 Tech Lead，还是企业 PMO？谁来维护 Workspace 配置？ |
| **What** | 核心问题是"任务管理"还是"产品交付管理"？与 Linear/Notion/Jira 的差异化是什么？ |
| **Why** | 为什么现在需要 Workspace 和 Project 层级？现有单任务模式遇到了什么瓶颈？ |
| **Where** | 数据存储在本地还是云端？Workspace 配置是 per-repo 还是 per-machine？ |
| **When** | MVP 何时可用？GitHub Project 集成优先级高于飞书 Bot 扩展吗？ |
| **How** | 如何衡量产品成功？用户留存率、任务完成率、还是代码交付速度？ |

### 适用阶段
产品需求定义前、任何功能开发前的需求澄清会议

### 优点
- 强制团队在"寻找答案"之前先"充分理解问题"
- 揭示隐藏假设和风险

### 缺点
- 只生成问题不生成答案，需要后续会议产出方案
- 在经验丰富的团队中可能显得重复

---

## 4. Reverse Brainstorming（逆向头脑风暴）

### 定义
不直接思考"如何成功"，而是思考"如何确保这个项目彻底失败"，然后将这些失败因素反转为成功策略。

### 核心流程
```
定义目标 → 反转提问"如何确保失败？" → 列出所有失败因素
→ 对每个失败因素反转得到防护策略 → 按风险优先级排序
```

### Capture 项目的逆向分析示例

| 如何确保 Capture v2 彻底失败 | 反转后的防护策略 |
|---------------------------|----------------|
| 让 Workspace/Project 配置极其复杂，需要手写 YAML | 提供 `capture workspace init` 交互式引导命令 |
| 与 GitHub Project 的同步频繁出错且不提示 | 实现完善的 sync-status 和 conflict-resolution |
| Markdown 存储格式不兼容 v1，导致数据丢失 | 设计 v1→v2 的自动迁移机制 |
| TUI 看板加载 100+ 任务时卡顿 | SQLite 分页查询 + 虚拟滚动 |
| 飞书 Bot 和 CLI 的数据模型不一致 | 统一 model 层，Bot/CLI/TUI 共用同一服务层 |
| 引入太多概念（Workspace/Project/Stage/Task）让用户困惑 | 提供渐进式概念暴露，默认隐藏高级功能 |

### 适用阶段
风险评估、架构评审、发布前的 checklist 检查

### 优点
- 人类大脑对"识别威胁"比对"识别机会"更敏感，更容易产生深度洞察
- 直接产出风险清单和防护措施

### 缺点
- 容易产生过度悲观的情绪，需要引导者控制节奏
- 部分反转后的策略可能过于防御性，限制创新

---

## 5. Impact vs Effort Matrix（影响-努力矩阵）

### 定义
以 **影响力（Impact）** 和 **实现努力（Effort）** 为两轴，将 brainstorm 产生的所有想法映射到 2×2 矩阵中，指导优先级决策。

### 矩阵分区

```
高努力 ↑  │  战略项目        │  快速胜利
          │  (高影响高努力)   │  (高影响低努力) ★ 优先做
          │  需要规划资源     │
          ├─────────────────┼─────────────────→ 高影响
          │  时间陷阱        │  填充工作
          │  (低影响高努力)   │  (低影响低努力)
          │  坚决不做        │  有时间再做
          └─────────────────┴─────────────────→ 低影响
                        低努力
```

### Capture v2 功能点的矩阵映射（初步）

| 功能 | 影响 | 努力 | 区域 | 优先级 |
|------|------|------|------|--------|
| Workspace 基础模型 + CLI 命令 | 高 | 中 | 战略项目 | P0 |
| GitHub Project 只读同步 | 高 | 低 | 快速胜利 | P0 |
| TUI 看板按 Project 分组 | 高 | 中 | 战略项目 | P1 |
| Spec 文档的 Markdown 模板 + 分发 | 中 | 低 | 快速胜利 | P1 |
| 飞书 Bot 支持 Project 筛选 | 中 | 低 | 快速胜利 | P1 |
| GitHub Project 双向写回同步 | 高 | 高 | 战略项目 | P2 |
| Workspace 多用户协作 | 中 | 高 | 时间陷阱 | 暂不做 |
| Web Dashboard（非 TUI） | 中 | 高 | 时间陷阱 | 暂不做 |

### 适用阶段
所有想法产生后的优先级排序、Sprint 规划、技术方案选型

### 优点
- 将主观争论转化为客观二维映射
- 资源分配决策可视化、可沟通

### 缺点
- Impact 和 Effort 的评估本身带有主观性
- 忽略战略依赖关系（某些高努力低影响的功能可能是其他功能的前置条件）

---

## 五种方法的组合使用工作流

推荐在 Capture v2 的规划过程中按以下顺序组合使用：

```
Phase 1: Starbursting
    → 充分理解问题空间，识别关键问题

Phase 2: First Principles Thinking  
    → 从根本约束出发，定义产品核心差异化

Phase 3: Reverse Brainstorming
    → 识别所有可能导致失败的因素

Phase 4: SCAMPER
    → 基于前三步的洞察，系统化产生功能改进方案

Phase 5: Impact vs Effort Matrix
    → 对所有方案进行优先级排序，产出可执行的 Roadmap
```

---

## 参考来源

1. [Miro - What is Brainstorming? Techniques and Methods](https://miro.com/brainstorming/what-is-brainstorming/)
2. [Optimizely - 10 product ideation techniques to spark innovation](https://www.optimizely.com/insights/blog/product-ideation-techniques/)
3. [Aha! - Brainstorming techniques for product teams](https://www.aha.io/roadmapping/guide/brainstorming-techniques-for-product-builders)
4. [Conceptboard - 15 Brainstorming Techniques Templates](https://conceptboard.com/blog/brainstorming-techniques-templates/)
5. [Storyflow - Best Brainstorming Tools 2026](https://storyflow.so/blog/best-brainstorming-tools-2026)
