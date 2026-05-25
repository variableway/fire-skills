# Tunee & Suno AI Music Skills - 深度分析报告

## 1. Tunee Music Skill 详解

### 1.1 项目信息
| 属性 | 详情 |
|------|------|
| **名称** | Tunee AI Music Generation Skill |
| **GitHub** | https://github.com/tuneeai/skills |
| **官网** | https://www.tunee.ai |
| **许可证** | MIT |
| **类型** | Agent Skill (Cursor/Codex/Claude Code/OpenClaw等40+工具) |
| **安装方式** | `npx skills add https://github.com/tuneeai/skills` |

### 1.2 核心能力
- **带歌词的歌曲生成**: 输入歌词 + 风格描述 → 生成完整歌曲
- **纯音乐/BGM生成**: 输入风格/场景描述 → 生成纯音乐
- **内置歌词写作指南**: AI辅助生成更高质量的歌词
- **多语言支持**: 中/英/日/韩/西/法/葡/德/意/阿/印/俄/荷/土/泰等15+语言
- **多模型切换**: Mureka V8, Tempolor 4.5+ 等顶级音乐模型

### 1.3 技术架构
```
skills/free-music-generator/
├── SKILL.md                    # 主技能定义文件
├── lyrics-guide.md             # 歌词写作指南
├── music-prompt-guide.md       # 音乐提示词构建指南
└── scripts/
    ├── generate.py             # 核心生成脚本
    ├── list_models.py          # 列出可用模型
    ├── credits.py              # 查询余额
    └── utils/
        ├── api_util.py         # API调用封装
        └── model_util.py       # 模型管理工具
```

### 1.4 使用方式

**独立脚本调用:**
```bash
# 列出模型
python scripts/list_models.py

# 生成纯音乐
python scripts/generate.py --title "Cafe Jazz" --prompt "Relaxing jazz piano" --model <modelID>

# 生成带歌词的歌曲
python scripts/generate.py --title "Summer Song" --prompt "Upbeat pop" --lyrics "lyrics here" --model <modelID>

# 查询余额
python scripts/credits.py
```

**环境变量:**
```bash
export TUNEE_API_KEY="your-access-key"
```

### 1.5 Prompt构建指南 (music-prompt-guide.md)

**格式规则**: 逗号分隔的英文关键词，不用句子

**六维构建法**:
| 维度 | 作用 | 示例 |
|------|------|------|
| Genre | 核心音乐风格 | pop, r&b, indie folk, hip-hop, jazz |
| Mood | 情感基调 | melancholic, uplifting, nostalgic, dark |
| Vocal | 人声特征 | female vocal, male vocal, soft, powerful |
| Tempo | 速度和强度 | slow, mid-tempo, uptempo, 120bpm |
| Instruments | 特色乐器 | acoustic guitar, piano, strings, synth |
| Production | 声音质感 | lo-fi, cinematic, warm, ambient |

**最佳实践**:
- 始终包含Genre（锚定整体风格）
- 3-6个关键词效果最佳，超过8个可能产生冲突
- 不要写句子，`a sad song with piano` ❌ → `melancholic, piano, slow` ✅

### 1.6 输出格式
成功时输出单行JSON数组:
```json
[{"id": "itemXXX", "url": "https://...", "title": "Song Title"}]
```
返回的是**作品分享页面链接**（shareUrl），不是直接音频文件。

---

## 2. Suno Skills 详解

### 2.1 项目总览

| 项目 | GitHub | 说明 | 类型 |
|------|--------|------|------|
| suno-song-creator-plugin | https://github.com/nwp/suno-song-creator-plugin | 最专业的Suno提示词创作Skill | Claude Code Plugin |
| suno-cli | https://github.com/slauger/suno-cli | Suno CLI命令行工具 | Python CLI |
| claude-code-suno-musicgen-skill | https://github.com/fltman/claude-code-suno-musicgen-skill | Suno自动化技能 | Claude Code Skill |

### 2.2 Suno Song Creator Plugin (最专业)

**版本**: 2.0.0 (持续更新)
**核心能力**:
- 7步完整工作流创作专业Suno提示词
- 自动化艺术家/歌曲研究（通过sub-agent）
- AI-slop避免指南（避免陈词滥调）
- 版权安全风格描述（避免艺人名字）
- 独立质量审查sub-agent
- Chrome自动化上传 (`/suno-upload`)
- 自动文件组织和保存

**9步工作流**:
1. **理解愿景** - 通过AskUserQuestion收集风格/情绪/人声信息
2. **模型选择** - v5(人声最佳) / v4.5(重型风格) / v4.5+(创意实验)
3. **构建结构化提示词** - 冒号引号格式，严格1000字符限制
4. **配置高级参数** - 人声性别、排除风格、START_ON等
5. **写有效歌词** - Meta标签控制，音节一致性，避免lyric bleed
6. **应用流派特定策略** - 声学/电子/摇滚不同策略
7. **质量审查(可选)** - 独立sub-agent评估
8. **保存到文件** - 自动项目目录结构
9. **上传到Suno(可选)** - Chrome自动化

**关键限制**: 
- 提示词严格**1000字符上限**（含空格标点）
- **禁止空白行**分隔各section
- **禁止提及艺人/乐队/专辑/歌曲名**

**提示词结构模板**:
```
genre: "indie folk rock, 2020s bedroom pop aesthetic, confessional singer-songwriter style"
vocal: "soft female alto, intimate whisper-to-belt, gentle vibrato, slight nasal quality"
instrumentation: "fingerpicked acoustic guitar, warm upright bass, sparse piano, light ambient pads"
production: "lo-fi intimacy, tape warmth, close-miked vocals, narrow stereo, natural room reverb"
mood: "melancholic, nostalgic, late-night introspection"
```

**AI-Slop避免清单**:
- ❌ 过度使用的技术词: neon, static, wire, circuits, digital, electric
- ❌ 抽象模糊意象: echoes, shadows, void, fragments, shattered, broken
- ❌ 城市黑色意象: city lights, neon streets, midnight rain
- ❌ 机器中的幽灵主题: trapped consciousness, digital prison
- ✅ 用具体细节替换抽象: "the 7-Eleven sign buzzing at 2 AM"

**文件结构**:
```
skills/suno-song-creator/
├── SKILL.md                          # 主技能(1300+行)
├── references/
│   ├── genre-clouds.md              # 流派共现数据
│   ├── meta-tags-reference.md       # Meta标签大全
│   ├── model-comparison.md          # 模型对比
│   ├── realism-descriptors.md       # 声学真实感描述词
│   ├── artist-research-guide.md     # 艺人研究指南
│   ├── genre-evaluation-matrix.md   # 流派评估矩阵
│   ├── pop-evaluation-guide.md      # Pop评估指南
│   └── indie-folk-evaluation-guide.md # Indie/Folk评估指南
├── agents/
│   ├── song-researcher.md           # 自动化研究sub-agent
│   └── quality-reviewer.md          # 质量审查sub-agent
├── utils/
│   ├── count-prompt.py              # 字符计数工具(Python)
│   └── count-prompt.js              # 字符计数工具(Node)
└── examples/
    ├── acoustic-folk-prompt.md      # 声学民谣示例
    ├── electronic-edm-prompt.md     # 电子EDM示例
    └── rock-alternative-prompt.md   # 摇滚替代示例
```

### 2.3 Suno CLI (命令行工具)

**功能**:
- 从歌词+风格提示生成歌曲
- 批量生成（适合专辑制作）
- 自动ID3标签和封面艺术
- 多模型支持(V5, V4.5-All等)

**安装**:
```bash
git clone https://github.com/slauger/suno-cli.git
cd suno-cli
python3 -m pip install -e .
suno init-config
# 编辑 ~/.suno-cli/config.yaml 添加API Key
```

**命令**:
```bash
suno generate -p lyrics.txt -t "My Song" -s "pop, upbeat" -o ./output
suno batch songs.yaml -o ./album
suno status <task-id>
suno download <task-id> -o ./output
```

**批量配置示例** (songs.yaml):
```yaml
songs:
  - title: "Track 1"
    prompt: track1.txt
    style: "pop, energetic"
  - title: "Track 2"
    prompt: track2.txt
    style: "ballad, emotional"
```

---

## 3. Tunee vs Suno 对比

| 维度 | Tunee | Suno |
|------|-------|------|
| **定位** | 免费AI音乐平台，Agent Skill封装 | 最知名的AI音乐生成平台 |
| **商业模式** | 免费API额度，可充值 | 订阅制/按生成付费 |
| **开源技能** | ✅ GitHub开源Skill | ✅ 多个开源Skill/CLI |
| **模型选择** | Mureka, MiniMax, ACE-Step, TemPolor | 自研v5/v4.5/v4.5+ |
| **歌词控制** | 用户提供歌词或AI生成 | 高度结构化meta标签控制 |
| **风格控制** | 逗号分隔关键词 | 结构化5-section提示词 |
| **上传自动化** | ❌ | ✅ Chrome自动化(v2.0) |
| **质量审查** | ❌ | ✅ 独立sub-agent |
| **艺人研究** | ❌ | ✅ 自动化研究 |
| **批量生成** | ❌ | ✅ suno-cli支持 |
| **文件管理** | ❌ | ✅ 自动项目目录 |
| **最佳场景** | 快速免费生成，多模型切换 | 专业级提示词工程 |

---

## 4. 推荐的使用策略

### 快速上手路线

**如果你想免费快速生成音乐**:
1. 注册 tunee.ai 获取API Key
2. 安装 Tunee Skill: `npx skills add https://github.com/tuneeai/skills`
3. 直接聊天: "帮我写一首关于夏天的歌"

**如果你想深入研究Suno提示词工程**:
1. 安装 Suno Song Creator Plugin
2. 学习7步工作流
3. 用 `/research-artist` 研究你喜欢的艺人风格
4. 用 `/review-song` 审查提示词质量

**如果你想批量生成专辑**:
1. 使用 suno-cli
2. 准备 batch YAML 配置文件
3. 一键生成整张专辑

---

## 5. 关键概念总结

### 从这两个Skill学到的核心概念

1. **Prompt Engineering是音乐生成的核心** - 提示词的质量直接决定输出质量
2. **结构化提示词 > 自然语言描述** - 用metadata格式描述比写句子更有效
3. **具体细节 > 抽象形容词** - "the 7-Eleven sign buzzing at 2 AM" > "neon lights"
4. **流派重力井** - 某些标签(如pop)会 overpower 其他标签，需要主动对抗
5. **版权安全** - 永远不用艺人/乐队/专辑/歌名，用风格+年代+特征描述
6. **Meta标签控制歌词结构** - `[Verse | intimate delivery | sparse instrumentation]`
7. **1000字符限制** - Suno的硬性限制，需要精打细算每个字符
8. **独立审查** - 用独立sub-agent审查质量，避免AI偏见
