#!/usr/bin/env python3
"""文档更新检查器 — 任务完成后检测哪些文档需要更新。

可被 git-workflow 和 local-workflow 的 finish 阶段调用。

Usage:
    python doc_checker.py [--since COMMIT] [--json]
    python doc_checker.py --since HEAD~1          # 对比最近一次提交
    python doc_checker.py --since HEAD~3          # 对比最近三次提交
    python doc_checker.py --json                  # JSON 格式输出
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


def get_changed_files(since="HEAD~1"):
    """获取相比指定 commit 修改的所有文件。"""
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only", since, "HEAD"],
            capture_output=True, text=True, check=False,
        )
        if result.returncode != 0:
            return []
        return [f for f in result.stdout.strip().split("\n") if f]
    except Exception:
        return []


def _has_skill_changes(files):
    return any("SKILL.md" in f for f in files)


def _has_dir_struct_changes(files):
    """检测是否有新增/删除目录级别的变化。"""
    return any("README.md" in f or "SKILL.md" in f for f in files)


def check_docs(files):
    """检查哪些文档可能需要更新，返回建议列表。"""
    suggestions = []

    # 规则 1: SKILL.md 变更 → 更新 README.md Skill 列表
    if _has_skill_changes(files):
        # 找出受影响的 skill 目录
        skill_dirs = set()
        for f in files:
            if "SKILL.md" in f:
                skill_dir = os.path.dirname(f)
                if skill_dir:
                    skill_dirs.add(skill_dir)

        if skill_dirs:
            suggestions.append({
                "doc": "README.md",
                "reason": f"Skill 变更影响: {', '.join(sorted(skill_dirs))}",
                "priority": "P0",
            })

    # 规则 2: 目录结构变化 → 更新受影响目录的 README.md
    checked_dirs = set()
    for f in files:
        dir_path = os.path.dirname(f)
        if not dir_path or dir_path.startswith(".") or dir_path in checked_dirs:
            continue
        checked_dirs.add(dir_path)

        # 检查该目录是否有 README.md
        readme = os.path.join(dir_path, "README.md")
        if os.path.exists(readme):
            # 检查 README 内容是否引用了变更的文件
            try:
                content = Path(readme).read_text(encoding="utf-8")
                base = os.path.basename(f)
                if base in content or os.path.basename(dir_path) in content:
                    suggestions.append({
                        "doc": f"{dir_path}/README.md",
                        "reason": f"文件 '{base}' 被引用",
                        "priority": "P1",
                    })
            except Exception:
                pass
        else:
            # 目录没有 README.md，且包含 SKILL.md 或 .md 文件
            has_content = any(
                os.path.exists(os.path.join(dir_path, name))
                for name in ["SKILL.md", "package.json", "Cargo.toml"]
            )
            md_files = [
                g for g in os.listdir(dir_path)
                if g.endswith(".md") and g != "README.md"
            ] if os.path.isdir(dir_path) else []

            if has_content or len(md_files) >= 2:
                suggestions.append({
                    "doc": f"{dir_path}/README.md",
                    "reason": "目录缺少 README.md",
                    "priority": "P1",
                })

    # 规则 3: fe-skills/ 变更 → 检查安装文档
    if any("fe-skills/" in f for f in files):
        install_doc = "docs/usage/install-frontend-skills.md"
        if os.path.exists(install_doc):
            suggestions.append({
                "doc": install_doc,
                "reason": "前端 skill 目录结构变化",
                "priority": "P1",
            })

    # 规则 4: dev/ 下的 skill 变更 → 检查 dev/README.md
    if any(f.startswith("dev/") and "SKILL.md" in f for f in files):
        dev_readme = "dev/README.md"
        if os.path.exists(dev_readme):
            suggestions.append({
                "doc": dev_readme,
                "reason": "dev/ 下的 skill 变更",
                "priority": "P1",
            })

    # 规则 5: docs/ 文件本身变化 → 检查 docs/README.md 索引
    if any(f.startswith("docs/") and f.endswith(".md") for f in files):
        docs_readme = "docs/README.md"
        if os.path.exists(docs_readme):
            suggestions.append({
                "doc": docs_readme,
                "reason": "docs/ 目录下的文档变化",
                "priority": "P2",
            })

    # 规则 6: skill 脚本变更 → 检查对应 SKILL.md
    for f in files:
        if "scripts/" in f and f.endswith(".py"):
            skill_dir = os.path.dirname(os.path.dirname(f))
            skill_md = os.path.join(skill_dir, "SKILL.md")
            if os.path.exists(skill_md):
                script_name = os.path.basename(f)
                try:
                    content = Path(skill_md).read_text(encoding="utf-8")
                    if script_name in content:
                        suggestions.append({
                            "doc": f"{skill_dir}/SKILL.md",
                            "reason": f"脚本 '{script_name}' 被引用",
                            "priority": "P1",
                        })
                except Exception:
                    pass

    # 规则 7: skill 变更 → 检查 CLAUDE.md 工作流描述
    skill_changed = (
        _has_skill_changes(files)
        or any("scripts/" in f and f.endswith(".py") and "workflow" in f for f in files)
    )
    if skill_changed:
        claude_md = "CLAUDE.md"
        if os.path.exists(claude_md):
            try:
                content = Path(claude_md).read_text(encoding="utf-8")
                if "workflow" in content.lower() or "skill" in content.lower():
                    suggestions.append({
                        "doc": claude_md,
                        "reason": "skill/workflow 变更可能影响项目指令",
                        "priority": "P1",
                    })
            except Exception:
                pass

    # 规则 8: docs/ 核心文档变化 → 检查 Agents.md
    if any(f.startswith("docs/") for f in files):
        agents_md = "docs/Agents.md"
        if os.path.exists(agents_md):
            suggestions.append({
                "doc": agents_md,
                "reason": "docs/ 内容变化可能影响 Agent 配置说明",
                "priority": "P2",
            })

    # 规则 9: install 脚本变化 → 检查安装文档
    if any(f.startswith("install") for f in files):
        for doc in ["docs/usage/install-frontend-skills.md", "README.md"]:
            if os.path.exists(doc):
                suggestions.append({
                    "doc": doc,
                    "reason": "安装脚本变化",
                    "priority": "P1",
                })

    # 去重
    seen = set()
    unique = []
    for s in suggestions:
        key = s["doc"]
        if key not in seen:
            seen.add(key)
            unique.append(s)

    return unique


def format_suggestions(suggestions):
    """格式化建议为可读文本。"""
    if not suggestions:
        return "✅ 文档检查通过，无需更新。"

    lines = ["📋 文档更新建议：", ""]
    for s in suggestions:
        marker = "🔴" if s["priority"] == "P0" else "🟡" if s["priority"] == "P1" else "🟢"
        lines.append(f"  {marker} {s['doc']} — {s['reason']}")
    lines.append("")
    return "\n".join(lines)


def format_suggestions_markdown(suggestions):
    """格式化建议为 Markdown 文本（适合 Issue 评论）。"""
    if not suggestions:
        return ""

    lines = ["## 文档更新建议", ""]
    for s in suggestions:
        lines.append(f"- **{s['doc']}**: {s['reason']} ({s['priority']})")
    lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="文档更新检查器")
    parser.add_argument("--since", default="HEAD~1", help="对比的起始 commit（默认 HEAD~1）")
    parser.add_argument("--json", action="store_true", help="JSON 格式输出")
    parser.add_argument("--markdown", action="store_true", help="Markdown 格式输出（适合 Issue）")
    args = parser.parse_args()

    files = get_changed_files(args.since)
    if not files:
        if args.json:
            print("[]")
        else:
            print("✅ 无文件变更，跳过文档检查。")
        return

    suggestions = check_docs(files)

    if args.json:
        print(json.dumps(suggestions, ensure_ascii=False, indent=2))
    elif args.markdown:
        md = format_suggestions_markdown(suggestions)
        if md:
            print(md)
    else:
        print(format_suggestions(suggestions))


if __name__ == "__main__":
    main()
