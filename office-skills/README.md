# Office Skills

办公效率相关的 AI Agent Skill 集合。

## 技能列表

| Skill | 说明 |
|-------|------|
| **markdown-converter** | 文档转 Markdown（基于 markitdown），支持 PDF/Word/PPT/Excel/HTML/图片/音频/ZIP/YouTube |
| **python-uv-env** | Python 项目脚手架（基于 uv），一键创建 CLI/FastAPI/Django/Library 项目 |

## 安装

```bash
# 按 tag 批量安装所有 office 相关 skill
./install-by-tag.sh office --system

# 安装到特定 Agent
./install-by-tag.sh office --system --agent claude-code

# 手动符号链接
ln -s $(pwd)/office-skills/markdown-converter ~/.claude/skills/markdown-converter
ln -s $(pwd)/office-skills/python-uv-env ~/.claude/skills/python-uv-env
```
