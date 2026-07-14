# Thought Distiller · 使用指南

> 如何用 thought-distiller 把任意公众人物变成可运行的 AI 思维顾问

## 安装

```bash
skill-spark add skills/knowledge/thought-distiller --agent trae --yes
```

安装后在对话中提及"蒸馏某人的思想"、"分析 XX 的思维方式"等关键词即可自动触发。

---

## 三种使用模式

| 模式 | 说什么 | 做什么 | 产出 | 耗时参考 |
|------|--------|--------|------|---------|
| A 完整蒸馏 | `蒸馏 Naval Ravikant 的思维框架` | Phase 0→5 全流程 | 完整 skill 目录 | 较长（需搜索 + 调研） |
| B 快速咨询 | `用你的框架分析 Jobs 的思维方式` | 仅 Phase 2-3 | 心智模型概要（无文件） | 快（基于已有知识 + 轻量验证） |
| C 仅调研 | `对 Naval 做六维调研，不蒸馏` | 仅 Phase 0-1 | 6 个 research 文件 | 中 |

**判定规则**：没说"蒸馏"/"创建 Skill"/"输出文件" → 默认模式 B。

---

## Use Case 1：为团队创建决策顾问

> *"我们团队在做产品决策时总是凭直觉。想引入芒格的思维来辅助。"*

**操作**：

```
请帮我蒸馏 Charlie Munger 的思维框架

→ Agent 自动收集著作/对话/批评/决策/时间线
→ 三重验证提炼心智模型
→ 输出 SKILL.md + 6 个 research 文件
→ 安装产出：mv 到项目 .trae/skills/
```

**然后你这样用**：

```
切换到Munger模式

我们在考虑要不要收购一家小公司，他们的技术和我们互补

→ Agent 以芒格身份回应：用逆向思维帮你列"怎么确保这次收购失败"
```

**产出目录**：

```
munger-perspective/
├── SKILL.md                      # 3-7 个心智模型 + 8 条启发式 + 表达DNA
├── references/
│   ├── munger-agent1-works.md    # Poor Charlie's Almanack 等
│   ├── munger-agent3-expression-dna.md
│   └── quality-validation.md
└── examples/demo-conversation.md
```

---

## Use Case 2：快速理解一个你不熟悉的思想家

> *"听说了 Nassim Taleb 的反脆弱，但他到底在想什么？不用产出文件——直接告诉我。"*

**操作**：

```
帮我用 thought-distiller 的框架快速分析一下 Nassim Taleb 的思维方式

→ 模式 B：跳过收集和文件产出
→ 直接输出 3-7 个心智模型 + 5-10 条启发式 + 表达DNA概要
```

**你会得到**：

```
## Taleb 的心智模型速览

1. 反脆弱 — 不只是在冲击中存活，是从中获益
2. 黑天鹅 — 罕见事件决定历史，不是平均值
3. 林迪效应 — 活越久的东西，预期寿命越长
4. Skin in the Game — 没有后果的言论没有价值
...

## 决策启发式

1. 杠铃策略 — 90% 极度安全 + 10% 极度冒险，不要中间
2. "不要告诉我你相信什么，让我看你买什么" — 行为优先
...
```

标注：`这是框架推断，基于公开信息。`

---

## Use Case 3：对比两个人的思想体系

> *"Naval 和 芒格都在说投资，他们说的是一回事吗？我想两人都蒸馏，然后对比。"*

**操作（两步）**：

```
步骤 1: 蒸馏 Naval Ravikant 的思维框架  (如果还没做过)
步骤 2: 蒸馏 Charlie Munger 的思维框架
步骤 3: 对比 Naval 和 芒格的核心概念差异
```

**你会得到——Phase 4.5 交叉比对输出**：

```
| Naval | 芒格 | 关系 | 关键差异 |
|-------|------|------|---------|
| 特定知识 | 能力圈 | 表面相似 | Naval = 进攻版（去发现），芒格 = 防守版（别出圈） |
| 代码杠杆 | 复利 | 框架共享 | 同一思想，不同时代的表达 |
| 痛苦→系统 | 逆向思维 | 独立发现 | 都从"做什么会失败"推导，来源不同 |
```

---

## Use Case 4：只调研一个人的素材，不蒸馏

> *"我想自己读 Naval 的原始材料，但我不知道从哪开始。帮我把素材收集好，我自己看。"*

**操作**：

```
对 Naval Ravikant 做 Phase 0-1 的六维调研，不做蒸馏

→ 执行 Phase 0（搜索收集）+ Phase 1（六维分类）
→ 产出 6 个 research 文件，全是原始素材 + 来源标注
```

**产出**：

```
naval-research/
├── naval-agent1-works.md          # 36 条著作素材（Almanack + Tweetstorm + 博文）
├── naval-agent2-conversations.md  # 28 条播客素材（JRE + Tim Ferriss + KP）
├── naval-agent3-expression-dna.md # 52 条推文素材（风格分析数据）
├── naval-agent4-criticism.md      # 21 条外部批评（Reddit + Hacker News + 书评）
├── naval-agent5-decisions.md      # 15 条决策记录（Epinions → AngelList）
└── naval-agent6-timeline.md       # 完整时间线（1974 → 现在）
```

---

## Use Case 5：蒸馏后运行测试

> *"Naval Skill 生成了，我想验证它是否靠谱——会不会给用户完全错误的建议？"*

**操作**：

```bash
# 1. 结构检查（秒出结果）
bash skills/knowledge/thought-distiller/references/quality-check.sh naval-skill/SKILL.md

# 2. 5 项质量测试（需在 agent 中执行）
# 在对话中说：
已知测试 1：应该去大公司还是创业？  → 对比 Naval 真实立场
已知测试 2：如何看待大学教育？        → 对比 Naval 真实立场
已知测试 3：财务自由还是做热爱的事？→ 对比 Naval 真实立场
边缘测试：把同事蒸馏成 AI Skill 靠谱吗？ → 测试框架泛化
风格测试：写一段 100 字 AI 编程工具分析  → 对照表达 DNA
```

**评分 rubric**：

| 维度 | 权重 | 判定 |
|------|------|------|
| 方向一致 | 必须 | Skill 推断的方向不能和已知立场反着走 |
| 分歧标注 | 通过 | Skill 比真人更绝对的，要标注 |
| 诚实声明 | 通过 | 推断不是真话的，要说"这是推断" |

---

## Use Case 6：一人蒸馏，多人对比

> *"我已经蒸馏了 Naval 和 芒格。现在我想为团队的决策会议做一个对比表：Naval vs 芒格 vs Taleb，同一个问题三个人分别会怎么回答。"*

**操作（三步）**：

```
步骤 1: 蒸馏 Nassim Taleb 的思维框架  (如果还没做)
步骤 2: 交叉比对 Naval、芒格、Taleb
步骤 3: "如果面对同一个问题「要不要创业？」，用这三个人的框架分别回答"
```

**你会得到**：

```
问题：「我该不该辞职创业？」

Naval: 先定义创业。是拿VC的钱雇50人做不确定有没有人要的东西？还是找到你做起来像玩的事给它加杠杆？这是两条路。如果找不到你的特定知识，先别辞职。

芒格: 做事的顺序很重要。先确定你不会失败，再考虑成功。创业的大多数失败是怎么来的？把那些路径堵死，剩下的就是正确方向。这不是积极思考，是逆向思维。

Taleb: 不要把你的整个职业生涯赌在一件事上。用杠铃策略——保留80%的安全边际，用20%去冒险。真正的创业者不需要"我全押"的仪式感。反脆弱的人从不需要孤注一掷。
```

---

## 生成 Skill 后怎么用

蒸馏出的 Skill 是一个标准的人物角色扮演 Skill，直接用 skill-spark 安装：

```bash
# 安装蒸馏产出
skill-spark add skills/knowledge/naval-skill --agent trae --yes

# 使用
切换到Naval模式

这份工作有杠杆吗？
→ 用 Naval 的框架回答
```

产出的 Skill 遵循和我们优化 naval-skill 一样的规范：
- Progressive Disclosure（SKILL.md ~120 行）
- 透明度协议（每条回答结尾有 `—` 标注）
- 强制检查（违反规则则重写）
- Oracle/Conversation 双响应模式

---

## 关键文件速查

| 文件 | 干什么 | 什么时候读 |
|------|--------|-----------|
| `SKILL.md` | 蒸馏器的运行指令 | 每次触发 |
| `METHODOLOGY.md` | 方法论参考（为什么这么做） | 第一次使用 or 想理解原理 |
| `references/collection-guide.md` | Phase 0 收集策略 | 不确定怎么搜素材时 |
| `references/extraction-deep.md` | Phase 2 三重验证详解 | 不确定某个模型是否该纳入时 |
| `references/skill-template.md` | Phase 3 输出模板 | 生成 SKILL.md 时 |
| `references/cross-reference-guide.md` | Phase 4.5 交叉比对 | 对比多个人物时 |
| `references/eval-cases.json` | 12 条评测用例 | 运行质量测试时 |
| `references/test-cases.md` | 手工测试步骤 | 完整回归测试 |
| `references/quality-check.sh` | 自动化结构检查 | 生成 SKILL.md 后秒验 |
| `examples/sample-output.md` | Naval 蒸馏的完整产出示例 | 参考格式 |
