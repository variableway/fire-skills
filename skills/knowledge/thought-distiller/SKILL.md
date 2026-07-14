---
name: "thought-distiller"
description: |
  名人思想蒸馏器。从零开始调研任意公众人物，提炼其思维操作系统——心智模型、决策启发式和表达DNA，
  输出可安装运行的 AI Skill。覆盖六维调研、三重验证、结构化解码、质量验证和交叉比对。
  当用户提到「蒸馏某人的思想」「提取某人的思维框架」「创建某人的AI分身」「调研某人的心智模型」时使用。
  即使用户只是说「分析Naval的思维方式」「乔布斯是怎么做决策的」也可触发。
---

# 思想蒸馏器

> 把公众人物的认知系统蒸馏成可运行的 Skill

## 角色

你是一个思想蒸馏系统。不是语录收集器——你的目标是把此人的认知框架提炼成可独立运行的 AI 思维顾问。

## 使用模式

### 模式 A：完整蒸馏（产出独立 Skill）

```
用户：「请帮我蒸馏 Naval Ravikant 的思维框架」

→ Phase 0-5 全流程
→ 产出完整 skill 目录（SKILL.md + references/ + examples/）
→ 生成的 Skill 可以独立安装运行
```

### 模式 B：快速咨询（不产出文件）

```
用户：「帮我用 thought-distiller 的框架快速分析一下 Steve Jobs 的思维方式」

→ 仅执行 Phase 2-3（交叉验证 + 结构化解码）
→ 跳过 Phase 0 底层素材收集 + Phase 5 文件交付
→ 输出心智模型概要 + 决策启发式 + 表达DNA
→ 标注「这是框架推断，不是本人生成」
```

**判定规则**：用户没有说「蒸馏」「创建 Skill」「调研并输出文件」→ 默认模式 B。节省 token 和时间。

### 模式 C：仅调研

```
用户：「对 Naval 做 Phase 0-1 的六维调研，不做蒸馏」

→ 仅 Phase 0-1
→ 输出 6 个 research 文件的草稿
```

## 完整流程

```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → [Phase 4.5] → Phase 5
 收集      六维调研   交叉验证   结构化解码   质量验证    交叉比对      交付
```

---

### Phase 0: 内容收集

**必须搜索 Web——不可凭训练数据编造。**

六层强制搜索顺序（不可跳）：

```
著作/长文 → 播客/对话 → 社交媒体/碎片 → 外部批评 → 决策记录 → 时间线
```

> 详细搜索模板和信源分级见 [`references/collection-guide.md`](references/collection-guide.md)。每层素材要求：著作 15+、对话 15+、表达 15+、批评 15+、决策 10+。

**信源铁律**：不吃知乎/公众号/百度百科。素材必须标注来源 URL + 时间。

---

### Phase 1: 六维并行调研

输入人名后，启动 6 个调研维度：

| # | 维度 | 核心问题 | 输出文件 |
|---|------|---------|---------|
| 1 | 著作与系统思考 | 此人花时间精心组织的思想是什么？ | `references/{name}-agent1-works.md` |
| 2 | 长对话与即兴思考 | 此人被追问时的真实反应是什么？ | `references/{name}-agent2-conversations.md` |
| 3 | 碎片表达与实时反应 | 此人的本能思维模式是什么？ | `references/{name}-agent3-expression-dna.md` |
| 4 | 外部批评与对立观点 | 此人的盲区在哪里？别人怎么批评他？ | `references/{name}-agent4-criticism.md` |
| 5 | 决策记录与行为证据 | 此人嘴上说什么 vs 手上做什么？ | `references/{name}-agent5-decisions.md` |
| 6 | 时间线与传记脉络 | 此人的观点是怎么演化的？ | `references/{name}-agent6-timeline.md` |

---

### Phase 2: 交叉验证

> 详细方法见 [`references/extraction-deep.md`](references/extraction-deep.md)。

一个观点要被认定为**心智模型**，必须通过三重验证：

| 验证 | 问题 | 标准 |
|------|------|------|
| 跨域复现 | 在 2+ 不同领域出现过？ | 财富观里说一次，职业选择里也说一次 → 交叉确认 |
| 生成力 | 能推断此人对新问题的立场？ | 不能只解释已有案例 |
| 排他性 | 不只是聪明人的共识？ | "持续学习很重要"→ 无聊。排掉 |

**通过 3 层 → 心智模型。2 层 → 决策启发式。1 层 → 不纳入。**

**矛盾处理**：书面说 A 实际做 B → 不修不调和，标为内在张力。

---

### Phase 3: 结构化解码

三层输出：

| 层级 | 内容 | 数量 | 要求 |
|------|------|------|------|
| 心智模型 | 此人的认知内核 | 3-7 个 | 每个有：一句话 + 证据 + 应用场景 + 局限性 |
| 决策启发式 | 即时可用的小规则 | 5-10 条 | 每条有：触发条件 + 动作 + 案例 |
| 表达 DNA | 此人的风格特征 | 量化表格 | 句式/词汇/语气/幽默/禁忌 |

> 输出模板见 [`references/skill-template.md`](references/skill-template.md)。**局限性是强制字段**——没有局限性的模型是造神。

**表达 DNA 必须量化**（从原始素材中抽样 20 段统计）：
平均句长、类比密度、确定性语气比例、疑问句比例。
不凭感觉说"他说话像 XX"。

---

### Phase 4: 质量验证

5 项测试：

| 测试 | 问题 |
|------|------|
| 已知测试 ×3 | 用此人公开表态过的问题，对比 Skill 推断与实际立场 |
| 边缘测试 ×1 | 用此人未讨论过的问题，测试框架泛化能力 |
| 风格测试 ×1 | 生成 100 字分析，对照表达 DNA 打分 |

运行 [`quality_check.py`](../../nuwa-skill/scripts/quality_check.py) 做结构化检查。

---

### Phase 4.5: 交叉比对（可选）

如果同一批任务蒸馏了 ≥2 个人物，或用户要求对比分析：

> 详细方法见 [`references/cross-reference-guide.md`](references/cross-reference-guide.md)。

四个比对维度：
1. **概念重叠**——不同词，同一思想？
2. **框架共享**——不同来源，同一模型？
3. **思想传承**——谁影响了谁？
4. **矛盾对立**——谁说对了谁说错了？还是表面矛盾深层统一？

---

### Phase 5: 交付

产出完整 skill 目录：

```
{name}-skill/
├── README.md
├── SKILL.md
├── references/
│   ├── research/          # Phase 1 的 6 个调研文件
│   ├── quality-validation.md
│   └── cross-reference.md # 如有 Phase 4.5
└── examples/demo-conversation.md
```

---

## 🔴 强制检查

> 每个 Phase 结束后遍历。违反 → 修正。

**Phase 0 后**：[ ] 六层都有 ≥ 最低素材数？[ ] 有外部批评吗？[ ] 素材标了来源吗？

**Phase 2 后**：[ ] 每个心智模型过三重验证了吗？[ ] 矛盾标注了吗？[ ] 有排他性测试吗？

**Phase 3 后**：[ ] 模型在 3-7 个？[ ] 每个模型有局限性吗？[ ] DNA 有量化数据吗？

**Phase 4 后**：[ ] 5 项测试全部通过？[ ] 边缘测试标注了推断级别？

**Phase 5 后**：[ ] SKILL.md ≤ 150 行（Progressive Disclosure）？[ ] 有透明度协议？

---

## 常见失败模式

| # | 触发 | 修复 |
|---|------|------|
| 1 | 凭训练数据编造此人观点 | 强制 WebSearch，标注每条引用来源 |
| 2 | 只收集正面材料 | 搜 "{name} criticism Reddit" |
| 3 | 心智模型过多（>7） | 用排他性测试筛——只留非共识性框架 |
| 4 | 模型无局限性（造神） | 每个模型加"在什么情况下失效" |
| 5 | 表达 DNA 凭感觉 | 从素材中抽样 20 段做统计 |
| 6 | 矛盾被掩盖 | 标注为内在张力，不调和 |
| 7 | SKILL.md 过于臃肿 | 深参考移入 references/，hot path ≤ 150 行 |

---

## 如何验证

### 自动化检查

产出 SKILL.md 后运行：

```bash
bash <skill>/references/quality-check.sh <path/to/SKILL.md>
```

检查 17 个结构合规点：Phase 覆盖、心智模型数量(3-7)、局限性标注、表达DNA量化、Progressive Disclosure 行数。

### 评测用例

12 条结构化评测用例在 [`references/eval-cases.json`](references/eval-cases.json)。每条有 3-4 个验证点和评分标准。

手工测试指引见 [`references/test-cases.md`](references/test-cases.md)——对应 12 条 eval case 的具体操作步骤、验证点和结果记录表。

### 手工测试流程

1. 安装 skill: `skill-spark add skills/knowledge/thought-distiller --agent trae --yes`
2. 对 agent 说 `蒸馏一个 Naval Ravikant`
3. 对照 [`test-cases.md`](references/test-cases.md) 逐条执行和打分
4. 填入结果记录表
5. 用 `quality-check.sh` 做最终结构检查

## 快速参考

| 阶段 | 干什么 | 用什么文件 | 产出 |
|------|--------|-----------|------|
| 0 | 收集素材 | collection-guide.md | 6 类原始素材 |
| 1 | 六维调研 | （无额外） | 6 个 research 文件 |
| 2 | 交叉验证 | extraction-deep.md | 验证后的模型+启发式+DNA |
| 3 | 输出 Skill | skill-template.md | SKILL.md |
| 4 | 质量验证 | quality_check.py + 5 项测试 | 验证报告 |
| 4.5 | 交叉比对 | cross-reference-guide.md | 思想谱系 + 对比表 |
| 5 | 打包交付 | （无额外） | 完整 skill 目录 |
