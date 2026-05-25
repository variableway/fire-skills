# AI Music Skills Collector - Task 3 输出

## 任务目标
1. 搜索并列出30个Top AI Music Skill/项目（GitHub + ClawHub + 其他）
2. 把有GitHub的项目整理到方便程序执行的文件，并生成可直接使用的CLI程序

---

## 📦 文件清单

| 文件 | 说明 |
|------|------|
| `ai-music-skills.json` | 30个AI Music项目的结构化数据（方便程序读取） |
| `main.go` | Go语言CLI程序源码 |
| `ai_music_cli.py` | Python版本CLI（立即可用，无需编译） |
| `README.md` | 本说明文件 |

---

## 📊 30个AI Music项目总览

### GitHub开源项目（20个）

| # | 名称 | Stars | 分类 | 许可证 |
|---|------|-------|------|--------|
| 1 | [Amphion](https://github.com/open-mmlab/Amphion) | 8000+ | 综合工具包 | MIT |
| 2 | [YuE](https://github.com/multimodal-art-projection/YuE) | 10000+ | 全曲生成 | Apache-2.0 |
| 3 | [DiffRhythm](https://github.com/ASLP-lab/DiffRhythm) | 5000+ | 全曲生成 | Apache-2.0 |
| 4 | [AudioCraft/MusicGen](https://github.com/facebookresearch/audiocraft) | 25000+ | 音乐生成 | MIT |
| 5 | [ACE-Step](https://github.com/ace-step/ACE-Step-1.5) | 2000+ | 音乐生成 | Apache-2.0 |
| 6 | [Magenta](https://github.com/tensorflow/magenta) | 18000+ | 综合工具包 | Apache-2.0 |
| 7 | [Muzic](https://github.com/microsoft/muzic) | 5000+ | 音乐理解/生成 | MIT |
| 8 | [Mustango](https://github.com/amaai-lab/mustango) | 1500+ | 可控音乐生成 | MIT |
| 9 | [SongGen](https://github.com/liuzh-19/SongGen) | 800+ | 音乐生成 | Apache-2.0 |
| 10 | [OpenMusic](https://github.com/amazon-science/openmusic) | 600+ | 音乐生成 | MIT |
| 11 | [Stable Audio Tools](https://github.com/Stability-AI/stable-audio-tools) | 4000+ | 音频/音乐生成 | MIT |
| 12 | [Riffusion](https://github.com/riffusion/riffusion) | 13000+ | 音乐生成 | MIT |
| 13 | [DDSP](https://github.com/magenta/ddsp) | 3000+ | 音色合成 | Apache-2.0 |
| 14 | [Music2Latent](https://github.com/SonyCSLParis/music2latent) | 500+ | 音频编码 | CC-BY-NC |
| 15 | [Music FaderNets](https://github.com/vishnubob/music-fadernets) | 300+ | 可控音乐生成 | MIT |
| 16 | [Pop Music Transformer](https://github.com/YatingMusic/pop-music-transformer) | 1000+ | 钢琴生成 | MIT |
| 17 | [R-VAE](https://github.com/vigliensoni/R-VAE) | 200+ | 节奏生成 | GPLv3 |
| 18 | [Harmonai](https://github.com/Harmonai) | N/A | 社区/生态 | Various |
| 19 | [Bark](https://github.com/suno-ai/bark) | 35000+ | 音频/音乐生成 | MIT |
| 20 | [Tortoise TTS](https://github.com/neonbjb/tortoise-tts) | 13000+ | 语音合成 | Apache-2.0 |

### ClawHub Skills（9个）

| # | 名称 | 说明 | 链接 |
|---|------|------|------|
| 21 | clawhub/gen-music | ACE-Step兼容API生成歌曲 | [ClawHub](https://clawhub.ai/skills/gen-music) |
| 22 | clawhub/ace-step-music | Apple Silicon Mac本地生成 | [ClawHub](https://clawhub.ai/skills/ace-step-music) |
| 23 | clawhub/ai-music-generation | DiffRhythm+腾讯Song Generation | [ClawHub](https://clawhub.ai/skills/ai-music-generation) |
| 24 | wells1137/music-generator | 结构化作曲计划生成音频 | [GitHub](https://github.com/openclaw/skills/tree/main/skills/wells1137/music-generator) |
| 25 | ivangdavila/music-generation | 多提供商集成指南 | [ClawHub](https://clawhub.ai/skills/music-generation) |
| 26 | topmediai/music-generator | TopMediai客户端 | [ClawHub](https://clawhub.ai/topmediai/music-generator-topmediai) |
| 27 | evolinkai/evolink-media | 视频/图像/音乐生成 | [ClawHub](https://clawhub.ai/evolinkai/evolink-media) |
| 28 | dongjiangliu9-tech/melodylab-ai-song | ZeeLin Music AI歌曲 | [ClawHub](https://clawhub.ai/dongjiangliu9-tech/melodylab-ai-song) |
| 29 | xiyunnet/ace-suno-v5 | Suno V5本地Web UI | [ClawHub](https://clawhub.ai/xiyunnet/ace-suno-v5) |

### MCP Skills（1个）

| # | 名称 | 说明 | 链接 |
|---|------|------|------|
| 30 | Music Generation MCP Skill | Claude Code集成Google Lyria/Suno/Udio | [MCP Market](https://mcpmarket.com/tools/skills/music-generation) |

---

## 🚀 CLI程序使用

### Python版本（立即可用）

```bash
# 查看版本
python3 ai_music_cli.py version

# 列出所有30个项目
python3 ai_music_cli.py list

# 搜索项目
python3 ai_music_cli.py search diffusion

# 按分类统计
python3 ai_music_cli.py categories

# 只列有GitHub的项目
python3 ai_music_cli.py github-list

# 克隆指定项目（支持ID或名称）
python3 ai_music_cli.py clone 1
python3 ai_music_cli.py clone Amphion

# 克隆所有GitHub项目
python3 ai_music_cli.py clone-all
```

### Go版本（需编译）

```bash
# 安装Go (macOS)
brew install go

# 编译
 go build -o ai-music-skills main.go

# 使用（命令与Python版本完全相同）
./ai-music-skills list
./ai-music-skills clone-all
./ai-music-skills search diffusion
```

---

## 📁 数据文件格式

`ai-music-skills.json` 结构：

```json
{
  "metadata": { ... },
  "skills": [
    {
      "id": 1,
      "name": "...",
      "description": "...",
      "type": "github|clawhub|mcp",
      "github": "https://github.com/...",
      "clawhub": "https://clawhub.ai/...",
      "license": "MIT",
      "language": "Python",
      "stars": "10000+",
      "tags": ["..."],
      "category": "..."
    }
  ],
  "github_only": ["https://github.com/..."]
}
```

---

## 🔧 扩展建议

1. **自动获取GitHub Stars**: 可通过GitHub API自动更新stars数量
2. **添加HuggingFace模型**: 许多项目同时有HF模型页面
3. **按许可证筛选**: 增加 `--license MIT` 等筛选功能
4. **批量分析**: 使用AI Agent分析这些项目的共同点和关键概念
