# Analysis Skills

代码与仓库分析相关的 AI Agent Skill 集合。

## 技能列表

| Skill | 说明 |
|-------|------|
| **repo-analyzer** | 代码仓库语义分析。克隆任意 GitHub / 本地仓库，集成 [CodeGraph](https://github.com/colbymchenry/codegraph) 构建索引（可选），生成结构化分析报告（技术栈 / 架构 / 入口点 / 路由表），归档到 `~/innate-revisit/analysis/repo/<repo-name>/`。 |
| **tech-research** | 技术问题解决方案搜索与分析。Web 搜索 + 结构化分析报告 + 技术成熟度评估。 |
| **awesome-analyzer** | Awesome List 解析与项目分析。从 Awesome List 中提取项目信息并做结构化分析。 |

## 安装

```bash
# 通过 tag 批量安装（推荐）
./install-by-tag.sh analysis --system

# 或指定单个分类
./install-by-tag.sh analysis --system --agent claude-code

# Windows
.\install-by-tag.ps1 -Tag analysis -System
```

安装目标：`~/.claude/skills/`、`~/.kimi/skills/`、`~/.codex/skills/`、`~/.opencode/skills/`（根据 `--agent` 过滤）。

## 输出归档目录

所有 `analysis/` 下的 Skill 默认将分析产物写入：

```
~/innate-revisit/analysis/
└── repo/
    └── <repo-name>/
        ├── README.md       # 索引
        ├── analysis.md     # 完整报告
        ├── metadata.json   # 结构化元数据
        └── codegraph/      # CodeGraph 索引产物（如可用）
```

可通过各 Skill 的 `--output` 参数覆盖。
