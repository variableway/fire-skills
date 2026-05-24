# Art Skills

创意 / 艺术类 AI Agent Skill 集合。

## 目录结构

```
art/
└── music/                                  # 音乐相关
    └── ai-music-style-reverse-engineering/ # → references/skills-pool/.../skills/...（符号链接）
```

## 技能列表

### `music/`

| Skill | 说明 |
|-------|------|
| **ai-music-style-reverse-engineering** | 从喜欢的歌曲/艺术家中逆向工程提炼风格配方，用于指导 AI 音乐生成工具（Suno/Udio）生成特定风格的音乐。包含素材收集、特征分析、Prompt 生成的完整流程。 |

> 该 Skill 通过符号链接引用自 `references/skills-pool/tasks/analysis/kimi/music-project/skills/ai-music-style-reverse-engineering/`，源数据（歌词、和弦、风格卡、Prompt 库）在 `references/skills-pool/music/` 与 `references/skills-pool/tasks/analysis/kimi/music-project/` 下。

## 安装

`art/` 不在 `install-by-tag.sh` 默认扫描目录中。如需启用按 tag 批量安装，可：

```bash
# 显式扫描 art 目录
./install-by-tag.sh <tag> --system --dir ./art/music

# 或手动符号链接到 Claude Code
ln -s "$(pwd)/art/music/ai-music-style-reverse-engineering" \
      ~/.claude/skills/ai-music-style-reverse-engineering
```

如需将 `art/` 加入默认扫描目录，编辑 `install-by-tag.sh` 的 `DEFAULT_SCAN_DIRS` 数组。
