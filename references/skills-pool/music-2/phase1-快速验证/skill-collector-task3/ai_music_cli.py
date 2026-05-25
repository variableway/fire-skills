#!/usr/bin/env python3
"""
AI Music Skills CLI - Python版本
功能与Go版本完全一致，用于在没有Go环境时立即使用

用法: python3 ai_music_cli.py <命令> [选项]
"""

import json
import os
import subprocess
import sys
import urllib.request
from pathlib import Path

VERSION = "1.0.0"
DEFAULT_JSON_PATH = "ai-music-skills.json"


def load_data(json_path):
    try:
        with open(json_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"错误: 无法找到JSON文件 {json_path}")
        print("提示: 可以使用 'download-json' 命令下载数据文件")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"解析JSON失败: {e}")
        sys.exit(1)


def truncate(s, max_len):
    return s if len(s) <= max_len else s[:max_len] + "..."


def print_skill(s):
    github_mark = "⭐" if s.get("github") else ""
    clawhub_mark = "🐾" if s.get("clawhub") else ""
    print()
    print(f"[{s['id']:02d}] {s['name']} {github_mark}{clawhub_mark}")
    print(
        f"     类型: {s['type']:<10} | 分类: {s['category']:<12} | "
        f"语言: {s.get('language', 'N/A'):<8} | Stars: {s.get('stars', 'N/A'):<8} | 许可: {s.get('license', 'N/A')}"
    )
    print(f"     标签: {', '.join(s.get('tags', []))}")
    print(f"     描述: {truncate(s.get('description', ''), 100)}")
    if s.get("github"):
        print(f"     GitHub: {s['github']}")
    if s.get("clawhub"):
        print(f"     ClawHub: {s['clawhub']}")


def cmd_list(data):
    meta = data["metadata"]
    print(f"\n{meta['title']}")
    print(f"生成日期: {meta['generated_at']} | {meta['description']}")
    print("=" * 120)
    for s in data["skills"]:
        print_skill(s)
    print(f"\n总计: {len(data['skills'])} 个项目")


def cmd_clone(data, target):
    found = None
    for s in data["skills"]:
        if str(s["id"]) == target:
            found = s
            break
    if not found:
        target_lower = target.lower()
        for s in data["skills"]:
            if target_lower in s["name"].lower():
                found = s
                break
    if not found:
        print(f"未找到匹配的项目: {target}")
        sys.exit(1)

    if not found.get("github"):
        print(f"项目 '{found['name']}' 没有GitHub仓库链接")
        if found.get("clawhub"):
            print(f"ClawHub页面: {found['clawhub']}")
        sys.exit(1)

    clone_repo(found["github"], "")


def cmd_clone_all(data):
    github_skills = [s for s in data["skills"] if s.get("github")]
    target_dir = "ai-music-repos"
    Path(target_dir).mkdir(parents=True, exist_ok=True)

    print(f"准备克隆 {len(github_skills)} 个GitHub项目到 {target_dir}/\n")
    success = 0
    failed = 0
    for s in github_skills:
        print(f"[{success + failed + 1}/{len(github_skills)}] 克隆 {s['name']} ...")
        if clone_repo(s["github"], target_dir):
            success += 1
        else:
            failed += 1
    print(f"\n完成! 成功: {success}, 失败: {failed}")
    print(f"项目保存在: {target_dir}/")


def clone_repo(repo_url, target_dir):
    parts = repo_url.rstrip("/").split("/")
    if len(parts) < 2:
        print(f"  无效的GitHub URL: {repo_url}")
        return False
    repo_name = parts[-1]
    if target_dir:
        repo_name = os.path.join(target_dir, repo_name)

    if os.path.exists(repo_name):
        print(f"  目录已存在，跳过: {repo_name}")
        return True

    try:
        subprocess.run(
            ["git", "clone", "--depth", "1", repo_url, repo_name],
            check=True,
            stdout=sys.stdout,
            stderr=sys.stderr,
        )
        return True
    except subprocess.CalledProcessError as e:
        print(f"  克隆失败: {e}")
        return False
    except FileNotFoundError:
        print("  错误: 未找到 git 命令，请确保已安装 Git")
        return False


def cmd_search(data, keyword):
    keyword_lower = keyword.lower()
    results = []
    for s in data["skills"]:
        tags = [t.lower() for t in s.get("tags", [])]
        if (
            keyword_lower in s["name"].lower()
            or keyword_lower in s.get("description", "").lower()
            or keyword_lower in s.get("category", "").lower()
            or any(keyword_lower in t for t in tags)
        ):
            results.append(s)

    if not results:
        print(f"未找到匹配 '{keyword}' 的项目")
        return

    print(f"\n找到 {len(results)} 个匹配 '{keyword}' 的项目:")
    print("-" * 80)
    for s in results:
        print_skill(s)


def cmd_categories(data):
    cats = {}
    for s in data["skills"]:
        cats.setdefault(s["category"], []).append(s)

    print("\n按分类统计:")
    print("=" * 60)
    for cat, skills in sorted(cats.items()):
        github_count = sum(1 for s in skills if s.get("github"))
        print(f"  {cat:<20} {len(skills):2d} 个项目 (GitHub: {github_count})")
    print("=" * 60)

    types = {}
    for s in data["skills"]:
        types[s["type"]] = types.get(s["type"], 0) + 1
    print("\n按类型统计:")
    for t, count in sorted(types.items()):
        print(f"  {t:<10} {count} 个")


def cmd_github_list(data):
    print("\n有GitHub链接的项目列表:")
    print("=" * 100)
    count = 0
    for s in data["skills"]:
        if s.get("github"):
            count += 1
            print(f"[{s['id']:02d}] {s['name']:<35} {s['github']}")
    print("=" * 100)
    print(f"共 {count} 个项目有GitHub链接")


def cmd_download_json(json_path):
    url = "https://raw.githubusercontent.com/innate-skills-exp/main/music/phase1-快速验证/skill-collector-task3/ai-music-skills.json"
    env_url = os.environ.get("SKILLS_JSON_URL")
    if env_url:
        url = env_url

    print(f"尝试下载: {url}")
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "ai-music-cli/1.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = resp.read()
            skills_data = json.loads(data)
            with open(json_path, "wb") as f:
                f.write(data)
            print(f"✓ 成功下载并保存到: {json_path}")
            print(f"  包含 {len(skills_data.get('skills', []))} 个项目")
    except Exception as e:
        print(f"下载失败: {e}")
        print("\n提示: 你可以手动下载JSON文件并放在当前目录")
        sys.exit(1)


def print_usage():
    print("""AI Music Skills CLI - 管理AI音乐开源项目的命令行工具

用法: python3 ai_music_cli.py <命令> [选项]

命令:
  list              列出所有30个AI Music项目
  clone <id|name>   克隆指定GitHub项目到当前目录
  clone-all         克隆所有GitHub项目到 ./ai-music-repos/ 目录
  search <keyword>  按关键词搜索项目(名称/描述/标签)
  categories        按分类统计项目
  github-list       只列出有GitHub链接的项目
  download-json     从远程下载最新的JSON数据文件
  version           显示版本信息

选项:
  -f <path>         指定JSON文件路径 (默认: ai-music-skills.json)

示例:
  python3 ai_music_cli.py list
  python3 ai_music_cli.py clone 1
  python3 ai_music_cli.py clone Amphion
  python3 ai_music_cli.py clone-all
  python3 ai_music_cli.py search diffusion
  python3 ai_music_cli.py categories
  python3 ai_music_cli.py github-list
""")


def main():
    json_path = DEFAULT_JSON_PATH
    args = sys.argv[1:]

    # Parse -f option
    if "-f" in args:
        idx = args.index("-f")
        if idx + 1 < len(args):
            json_path = args[idx + 1]
            args = args[:idx] + args[idx + 2:]

    if not args:
        print_usage()
        sys.exit(0)

    cmd = args[0]

    if cmd in ("version", "-v", "--version"):
        print(f"ai-music-skills-cli v{VERSION} (Python)")
        return

    if cmd == "download-json":
        cmd_download_json(json_path)
        return

    data = load_data(json_path)

    if cmd == "list":
        cmd_list(data)
    elif cmd == "clone":
        if len(args) < 2:
            print("用法: python3 ai_music_cli.py clone <id|name>")
            sys.exit(1)
        cmd_clone(data, args[1])
    elif cmd == "clone-all":
        cmd_clone_all(data)
    elif cmd == "search":
        if len(args) < 2:
            print("用法: python3 ai_music_cli.py search <keyword>")
            sys.exit(1)
        cmd_search(data, args[1])
    elif cmd == "categories":
        cmd_categories(data)
    elif cmd == "github-list":
        cmd_github_list(data)
    else:
        print_usage()


if __name__ == "__main__":
    main()
