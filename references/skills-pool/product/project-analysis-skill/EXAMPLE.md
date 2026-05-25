# Skill 使用示例

## 场景

将 `tasks/mindstorm/local-ai-playgound.md` 转化为完整的设计文档集。

## 执行过程

### 输入

原始需求文档：`tasks/mindstorm/local-ai-playgound.md`

核心内容：
- 目标用户：几乎没有编程经验的小白
- 核心功能：一键安装配置、UI 向导、教程系统
- 形式：Web 端 + 本地端
- 输出要求：技术分析、架构、功能分解、计划等不同维度文档

### 输出

生成的文档集结构：

```
tasks/mindstorm/
├── local-ai-playgound.md      # 原始需求（输入）
├── learn-ai-agent.md          # 综合分析文档（输出）
└── features/                   # 功能分解（输出）
    ├── F1-roadmap-visualization.md
    ├── F2-tutorial-system.md
    ├── F3-terminal-integration.md
    └── ...
```

### 输出文档内容特点

#### 1. learn-ai-agent.md - 技术分析文档

包含以下章节：
- **项目概述**：目标用户、核心价值、功能清单表格
- **技术选型分析**：推荐方案、对比表格（Tauri vs Electron）
- **核心难点分析**：系统命令执行、跨平台兼容、权限提升
- **架构设计**：整体架构图、模块划分、数据流图
- **实现计划**：分 Phase 的任务表格
- **可行性结论**：多维度评分表格

#### 2. features/*.md - 功能分解文档

每个功能包含：
- 功能描述和验收标准
- 界面布局示意图（ASCII）
- 交互流程图（ASCII）
- 技术实现要点

---

## 使用效果

通过使用本 Skill：

1. **从模糊需求到清晰设计**：原始需求是概念性的，输出是可实现的设计
2. **架构可视化**：通过 ASCII 图让架构一目了然
3. **开发可执行**：Phase 计划 + Feature 分解 = 可直接开工
4. **风险前置**：技术难点分析和可行性评估帮助提前规避风险

---

## 如何在自己的项目中使用

```bash
# 1. 准备原始需求文档
vim tasks/my-project/requirement.md

# 2. 应用本 Skill
# 按照 SKILL.md 中的 Step 1-7 执行

# 3. 输出设计文档集
tasks/my-project/
├── requirement.md      # 输入
├── analysis.md         # 技术分析
├── architecture.md     # 架构设计
├── plan.md             # 实施计划
└── features/           # 功能分解
    └── ...
```
