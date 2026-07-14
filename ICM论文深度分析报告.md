# ICM (Interpretable Context Methodology) 论文深度分析报告

> **论文标题**: Interpretable Context Methodology: Folder Structure as Agent Architecture  
> **作者**: Jake Van Clief, David McDermott (Eduba, University of Edinburgh)  
> **arXiv**: 2603.16021v2 (2026年3月18日)  
> **GitHub**: https://github.com/RinDig/Interpretable-Context-Methodology-ICM-  
> **许可证**: MIT  
> **页数**: 21页

---

## 一、核心论点

**一句话总结**: ICM 用**文件系统结构**替代**多Agent框架代码**，实现AI工作流的编排——编号文件夹代表阶段，Markdown文件承载提示和上下文，本地脚本处理非AI的机械工作。

**核心洞察**: 
> "如果工作流每个阶段的提示和上下文已经以文件形式存在于组织良好的文件夹层次结构中，你就不需要协调框架来管理多个专业Agent。你只需要一个编排Agent，在正确的时刻读取正确的文件。"

---

## 二、五层上下文层次结构（核心架构）

```
Layer 0: CLAUDE.md / IDENTITY.md    "Where am I?"         ~800 tokens   (始终加载)
Layer 1: CONTEXT.md (root)          "Where do I go?"      ~300 tokens   (进入时读取)
Layer 2: Stage CONTEXT.md           "What do I do?"       200-500 tokens (每阶段读取)
Layer 3: Reference material         "What rules apply?"   500-2k tokens (选择性加载)
Layer 4: Working artifacts          "What am I working with?" varies (选择性加载)
```

### 各层详解

| 层级 | 文件 | 问题 | Token预算 | 内容类型 | 变化频率 |
|------|------|------|-----------|----------|----------|
| **Layer 0** | `CLAUDE.md` / `IDENTITY.md` | "我在哪里？" | ~800 | 全局身份文件 | 从不 |
| **Layer 1** | 根目录 `CONTEXT.md` | "我该去哪里？" | ~300 | 任务路由 | 很少 |
| **Layer 2** | 阶段 `CONTEXT.md` | "我该做什么？" | 200-500 | 阶段契约 | 每阶段 |
| **Layer 3** | `references/` / `_config/` | "什么规则适用？" | 500-2k | 参考材料（工厂） | 跨运行稳定 |
| **Layer 4** | `output/` | "我在处理什么？" | 变化 | 工作产物（产品） | 每次运行变化 |

### Layer 3 vs Layer 4 的关键区分

| 维度 | Layer 3: Reference（工厂） | Layer 4: Working（产品） |
|------|---------------------------|------------------------|
| 跨运行变化 | 否 | 是 |
| 示例文件 | voice.md, design-system.md, conventions.md | research-output.md, script-draft.md |
| 模型应如何对待 | 内化为约束 | 作为输入处理 |
| 配置时机 | 工作空间设置（一次） | 管道执行（每次） |
| 文件夹位置 | `references/`, `_config/`, `shared/` | `output/` |
| 类比 | 食谱 | 食材 |

---

## 三、文件夹结构（标准工作空间）

```
workspace/
  CLAUDE.md                 # Layer 0: 全局身份文件
  CONTEXT.md                # Layer 1: 任务路由
  stages/
    01_research/
      CONTEXT.md            # Layer 2: 阶段契约
      references/           # Layer 3: 参考材料
      output/               # Layer 4: 工作产物
    02_script/
      CONTEXT.md
      references/
      output/
    03_production/
      CONTEXT.md
      references/
      output/
  _config/                  # Layer 3: 品牌/声音/设计系统
  shared/                   # Layer 3: 跨阶段资源
  skills/                   # Layer 3: 领域知识包
  setup/
    questionnaire.md        # 一次性入职配置
```

### 命名规范
- **编号编码执行顺序**: `01_research/`, `02_script/`, `03_production/`
- **文件夹边界强制关注点分离**
- **`output/` 目录是Layer 4交接点**: 阶段01的输出成为阶段02的输入

---

## 四、阶段契约模板（CONTEXT.md）

```markdown
## Inputs
- Layer 4 (working): ../01_research/output/
- Layer 3 (reference): ../../_config/voice.md
- Layer 3 (reference): references/structure.md

## Process
Write a script based on the research output.
Follow the structure in structure.md.
Match the tone described in voice.md.

## Outputs
- script_draft.md -> output/
```

**契约三部分**:
1. **Inputs**: 读取什么（区分Layer 3参考材料和Layer 4工作产物）
2. **Process**: 做什么（阶段具体指令）
3. **Outputs**: 写什么（输出文件和位置）

---

## 五、五大设计原则

| 原则 | 来源 | 说明 |
|------|------|------|
| **One stage, one job** | Unix原则 + Parnas信息隐藏 | 每个阶段处理单一步骤，研究的不写，写的不构建 |
| **Plain text as the interface** | Kernighan & Pike | 阶段通过Markdown/JSON通信，无二进制格式 |
| **Layered context loading** | Liu et al. "Lost in the Middle" | 只加载当前阶段需要的上下文，预防而非压缩 |
| **Every output is an edit surface** | Horvitz混合主动 + Shneiderman直接操作 | 每个中间输出都是人类可编辑的文件 |
| **Configure the factory, not the product** | 持续交付原则 | 工作空间一次性设置，每次运行产生新交付物 |

---

## 六、与现有框架的对比

| 维度 | 框架方法 | ICM方法 |
|------|----------|---------|
| **改变阶段顺序** | 编辑编排代码，重新部署 | 重命名或重新排序文件夹 |
| **修改提示** | 编辑代码中的Agent配置 | 编辑Markdown文件 |
| **添加/移除阶段** | 编写新Agent类，更新编排器 | 添加/删除文件夹 |
| **检查中间状态** | 添加日志，构建仪表板 | 打开文件夹，读取文件 |
| **交接给他人** | 文档化环境、依赖、设置 | 复制文件夹 |
| **谁可以更改** | 开发者 | 任何有文本编辑器的人 |
| **错误恢复** | 内置重试、回退、异常处理 | 手动重新运行失败阶段 |
| **条件分支** | 基于Agent输出的程序化路由 | 人类在阶段间决定 |
| **并发执行** | 原生并行Agent协调 | 按设计顺序执行 |
| **外部服务集成** | 程序化API调用、认证管理 | 本地脚本或MCP连接 |

---

## 七、三个已实现的工作空间

### 1. Script-to-Animation Pipeline（3阶段）
```
01_research/    → 主题 → 结构化研究输出
02_script/      → 研究输出 → 脚本
03_production/  → 脚本 → 动画规格 + Remotion代码
```

### 2. Course Deck Production（5阶段）
```
01_extraction/     → PDF/笔记 → 内容提取
02_structuring/    → 提取内容 → 结构规划
03_drafting/       → 结构 → 幻灯片草稿
04_visual_design/  → 草稿 → 视觉设计规格
05_assembly/       → 规格 → 最终PPT
```

### 3. Workspace-Builder（5阶段）
```
01_discovery/      → 领域识别
02_mapping/        → 阶段映射
03_scaffolding/    → 文件夹结构创建
04_questionnaire/  → 设置问卷设计
05_validation/     → 端到端验证
```

---

## 八、实践者观察（52人社区，33人使用报告）

### U形干预模式
```
Stage 1: ████████████████████ 92% 频繁编辑（方向设定）
Stage 2: ██████ 30% 较少编辑（受约束执行）
Stage 3: ████████████████ 78% 频繁编辑（对齐调试）
```

- **Stage 1编辑**: 创意判断——从广泛可能性缩小到特定角度
- **中间阶段**: 最少干预——前后锚点已定义，执行空间受限
- **Stage 3编辑**: 对齐工作——检查输出是否忠实于早期决策

### 非技术用户成功案例
- 3名无编程经验、无Claude Code使用经验的社区成员
- 使用workspace-builder的问卷和设置流程
- 成功创建并运行工作空间，从脚本生成十分钟动画视频
- 编辑CONTEXT.md文件，审查阶段输出，迭代工作空间

---

## 九、与Anthropic MCP的关系

> **互补而非竞争**

- **MCP**: 标准化模型如何访问外部工具和数据源（集成层）
- **ICM**: 如何结构化和传递上下文给Agent（编排层）
- **组合使用**: ICM阶段可以使用MCP连接访问外部服务，而阶段文件夹结构决定Agent在这样做时接收什么上下文

---

## 十、适用与不适用场景

### ✅ 适用（顺序、可审查、可重复）
- 内容生产管道（脚本→动画、短视频）
- 培训材料开发（幻灯片生成）
- 学术研究工作流程
- 政策分析
- 报告生成

### ❌ 不适用
- **实时多Agent协作**: 需要动态消息传递（AutoGen等）
- **高并发系统**: 需要队列、状态隔离、部署基础设施
- **复杂自动分支逻辑**: 基于AI决策的中途分支

---

## 十一、未来方向：编译、调试和源完整性

### 1. ICM作为多遍增量编译
- **类比**: 编译器的词法分析→语法分析→语义分析→优化→代码生成
- **ICM对应**: 研究→脚本→生产，每阶段产生中间表示
- **增量编译**: 只重新编译变化的部分，而非从头构建

### 2. 语义调试
- **输出溯源**: 通过标识符将输出部分链接到源指令
- **跨阶段追踪验证**: 检查阶段n的输出是否与阶段n-2一致
- **Markdown断点**: 在CONTEXT.md中设置"处理后暂停检查"点

### 3. 编辑源原则（Edit-Source Principle）
> "如果从业者连续三次在同一阶段的输出中编辑同一种内容，系统应该浮现该模式并建议源级更改。"

- 编辑输出 = 修补二进制（治标）
- 编辑源 = 修复编译器（治本）
- 目标: 将一次性修复转化为持久的系统改进

---

## 十二、关键引用与学术基础

| 概念 | 来源 | 论文引用 |
|------|------|----------|
| Unix管道设计 | McIlroy, 1978 | [1] |
| 信息隐藏 | Parnas, 1972 | [9] |
| 关注点分离 | Dijkstra, 1974 | [8] |
| 文学编程 | Knuth, 1984 | [10] |
| "Worse is Better" | Gabriel, 1991 | [11] |
| Lost in the Middle | Liu et al., 2024 | [25] |
| 混合主动系统 | Horvitz, 1999 | [37] |
| 可解释模型 | Rudin, 2019 | [45] |
| 人类-AI交互指南 | Amershi et al., 2019 | [47] |
| 多遍编译 | Aho et al., 2006 | [52] |

---

## 十三、结论

> "使Unix管道在1970年代有效的原则适用于2020年代的AI Agent编排。程序做一件事。一个程序的输出成为另一个的输入。纯文本作为通用接口。人类可读的中间状态。"

ICM将这些原则应用于特定问题：为跨多步骤工作流的AI Agent结构化上下文。结果是文件夹结构替代了框架。一个Agent在每个阶段读取不同的上下文，而不是多个Agent通过代码协调。本地脚本处理不需要AI的机械工作。每个中间输出都是人类可以阅读和编辑的文件。

**对于工作流是顺序的、可审查的、可重复的从业者，这意味着**：
- 无需学习框架
- 无需维护服务器
- 日常操作无需开发者
- 工作空间是一个文件夹，可以复制、版本控制、共享、用文本编辑器编辑

**最简单的可行架构是每台计算机上已经存在的架构：文件系统。**
