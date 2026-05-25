# Product Skills

产品设计相关的 AI Agent Skill 集合。

## 技能列表

| Skill | 说明 |
|-------|------|
| **prd-writer-skill** | 产品需求文档（PRD）撰写，将产品想法转化为结构化需求文档 |
| **project-analysis-skill** | 从需求文档生成技术分析、架构设计、功能分解和实施计划 |

## 工作流

```
产品想法 → prd-writer-skill → requirement.md → project-analysis-skill → 设计文档集
                                                              ├── analysis.md
                                                              ├── architecture.md
                                                              ├── features/*.md
                                                              └── plan.md
```

## 安装

```bash
./install.sh --system --folder product --all
```
