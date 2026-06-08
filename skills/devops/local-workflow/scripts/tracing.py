#!/usr/bin/env python3
"""Local Task Tracing - 纯本地任务追踪，无需 GitHub Issue。

功能：
1. Task 创建时：记录原始内容和 Agent 解析后的内容
2. Task 完成时：追加实现总结，标记完成状态
3. 文件按 task 文件名命名，保存在 tasks/tracing/ 目录

用法：
    python tracing.py init --task tasks/features/my-task.md [--parsed "..."]
    python tracing.py finish --task tasks/features/my-task.md [--summary "..."]
    python tracing.py status
    python tracing.py show --task tasks/features/my-task.md
"""

import argparse
import hashlib
import json
import sys
from datetime import datetime
from pathlib import Path


TRACING_DIR = Path("tasks/tracing")
STATE_FILE = Path(".local-workflow.state.json")


def _generate_task_id(task_path: str) -> str:
    """生成唯一的任务 ID。"""
    timestamp = datetime.now().strftime("%Y%m%d")
    hash_input = f"{task_path}{datetime.now().isoformat()}"
    short_hash = hashlib.md5(hash_input.encode()).hexdigest()[:8]
    return f"local-{timestamp}-{short_hash}"


def _task_stem(task_path: str) -> str:
    """从 task 文件路径提取不含扩展名的文件名作为 tracing 文件名。"""
    return Path(task_path).stem


def _tracing_file(task_path: str) -> Path:
    """获取对应的 tracing 文件路径。"""
    return TRACING_DIR / f"{_task_stem(task_path)}.md"


def _ensure_dir():
    """确保 tracing 目录存在。"""
    TRACING_DIR.mkdir(parents=True, exist_ok=True)


def _read_task_content(task_path: str) -> str:
    """读取 task 文件原始内容。"""
    p = Path(task_path)
    if not p.exists():
        return f"(task file not found: {task_path})"
    return p.read_text(encoding="utf-8")


def _extract_title(content: str) -> str:
    """从 task 内容提取标题（第一行去除 #）。"""
    lines = content.split("\n")
    if lines:
        return lines[0].lstrip("# ").strip()
    return "Untitled Task"


def cmd_init(args):
    """初始化 tracing 记录：写入原始内容和解析后内容。"""
    _ensure_dir()

    task_path = args.task
    parsed = args.parsed or ""
    task_id = _generate_task_id(task_path)

    original = _read_task_content(task_path)
    title = _extract_title(original)
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    tracing_file = _tracing_file(task_path)

    # 如果文件已存在，追加新的 task 记录
    if tracing_file.exists():
        existing = tracing_file.read_text(encoding="utf-8")
        separator = f"\n\n---\n\n## Task Entry ({now})\n\n"
        content = existing + separator
    else:
        content = f"# Tracing: {_task_stem(task_path)}\n\n"
        content += f"## Task Entry ({now})\n\n"

    content += f"- **Task File**: `{task_path}`\n"
    content += f"- **Task ID**: {task_id}\n"
    content += f"- **Title**: {title}\n"
    content += f"- **Started At**: {now}\n"
    content += f"- **Status**: in_progress\n\n"

    content += "### Original Task Content\n\n"
    content += "```markdown\n"
    content += original.strip() + "\n"
    content += "```\n\n"

    if parsed:
        content += "### Agent Parsed Content\n\n"
        content += parsed.strip() + "\n\n"

    tracing_file.write_text(content, encoding="utf-8")
    
    # Save state for orchestrator
    state = {
        "task_file": str(task_path),
        "task_id": task_id,
        "title": title,
        "started_at": now,
        "status": "in_progress",
        "tracing_file": str(tracing_file)
    }
    STATE_FILE.write_text(json.dumps(state, indent=2), encoding="utf-8")
    
    print(f"Tracing initialized: {tracing_file}")
    print(f"Task ID: {task_id}")
    return task_id


def cmd_finish(args):
    """完成 tracing 记录：追加实现总结，标记完成。"""
    task_path = args.task
    summary = args.summary or ""

    tracing_file = _tracing_file(task_path)

    if not tracing_file.exists():
        print(f"Warning: No tracing file found for {task_path}. Creating new entry.", file=sys.stderr)
        _ensure_dir()
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        task_id = _generate_task_id(task_path)
        original = _read_task_content(task_path)
        title = _extract_title(original)
        
        content = f"# Tracing: {_task_stem(task_path)}\n\n"
        content += f"## Task Entry ({now})\n\n"
        content += f"- **Task File**: `{task_path}`\n"
        content += f"- **Task ID**: {task_id}\n"
        content += f"- **Title**: {title}\n"
        content += f"- **Status**: completed\n"
        content += f"- **Completed At**: {now}\n\n"
        content += "### Original Task Content\n\n"
        content += "```markdown\n"
        content += original.strip() + "\n"
        content += "```\n\n"
        
        tracing_file.write_text(content, encoding="utf-8")
    else:
        content = tracing_file.read_text(encoding="utf-8")
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # Update status from in_progress to completed
        content = content.replace("- **Status**: in_progress", "- **Status**: completed")
        content = content.rstrip() + f"\n- **Completed At**: {now}\n"

        if summary:
            content += f"\n### Implementation Summary\n\n"
            content += summary.strip() + "\n\n"

        tracing_file.write_text(content, encoding="utf-8")

    # Update state file
    if STATE_FILE.exists():
        try:
            state = json.loads(STATE_FILE.read_text(encoding="utf-8"))
            state["status"] = "completed"
            state["completed_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            if summary:
                state["summary"] = summary
            STATE_FILE.write_text(json.dumps(state, indent=2), encoding="utf-8")
        except Exception:
            pass

    print(f"Tracing updated: {tracing_file}")


def cmd_status(_args):
    """显示 tracing 目录中的所有记录。"""
    if not TRACING_DIR.exists():
        print("No tracing directory found.")
        return

    files = sorted(TRACING_DIR.glob("*.md"))
    if not files:
        print("No tracing records found.")
        return

    print(f"Tracing records ({len(files)}):\n")
    for f in files:
        text = f.read_text(encoding="utf-8")
        # Extract status and title
        status = "unknown"
        title = f.stem
        for line in text.split("\n"):
            if "**Status**:" in line:
                status = line.split("**Status**:")[1].strip()
            if "**Title**:" in line:
                title = line.split("**Title**:")[1].strip()
        print(f"  - {f.name}: {title} [{status}]")


def cmd_show(args):
    """显示指定任务的追踪记录内容。"""
    task_path = args.task
    tracing_file = _tracing_file(task_path)
    
    if not tracing_file.exists():
        print(f"No tracing record found for: {task_path}")
        return
    
    content = tracing_file.read_text(encoding="utf-8")
    print(content)


def cmd_list(args):
    """列出所有追踪记录，支持按状态过滤。"""
    if not TRACING_DIR.exists():
        print("No tracing directory found.")
        return

    files = sorted(TRACING_DIR.glob("*.md"))
    if not files:
        print("No tracing records found.")
        return

    filter_status = args.status.lower() if args.status else None
    
    records = []
    for f in files:
        text = f.read_text(encoding="utf-8")
        status = "unknown"
        title = f.stem
        started_at = ""
        completed_at = ""
        
        for line in text.split("\n"):
            if "**Status**:" in line:
                status = line.split("**Status**:")[1].strip()
            if "**Title**:" in line:
                title = line.split("**Title**:")[1].strip()
            if "**Started At**:" in line:
                started_at = line.split("**Started At**:")[1].strip()
            if "**Completed At**:" in line:
                completed_at = line.split("**Completed At**:")[1].strip()
        
        if filter_status and status.lower() != filter_status:
            continue
            
        records.append({
            "file": f.name,
            "title": title,
            "status": status,
            "started": started_at,
            "completed": completed_at
        })
    
    if not records:
        print(f"No tracing records with status '{args.status}' found.")
        return
        
    print(f"Tracing records ({len(records)}):\n")
    for r in records:
        completed_info = f", completed: {r['completed']}" if r["completed"] else ""
        print(f"  - {r['file']}: {r['title']} [{r['status']}]")
        print(f"    started: {r['started']}{completed_info}")


def main():
    parser = argparse.ArgumentParser(description="Local Task Tracing (No GitHub Required)")
    sub = parser.add_subparsers(dest="cmd", help="Available commands")

    # init
    p_init = sub.add_parser("init", help="Initialize tracing record for a task")
    p_init.add_argument("--task", required=True, help="Task file path (e.g. tasks/features/my-task.md)")
    p_init.add_argument("--parsed", help="Agent-parsed task content")

    # finish
    p_finish = sub.add_parser("finish", help="Mark tracing record as completed with summary")
    p_finish.add_argument("--task", required=True, help="Task file path")
    p_finish.add_argument("--summary", help="Implementation summary to append")

    # status
    sub.add_parser("status", help="Show all tracing records")
    
    # show
    p_show = sub.add_parser("show", help="Show tracing content for a specific task")
    p_show.add_argument("--task", required=True, help="Task file path")
    
    # list
    p_list = sub.add_parser("list", help="List all tracing records with details")
    p_list.add_argument("--status", help="Filter by status (in_progress, completed)")

    args = parser.parse_args()

    handlers = {
        "init": cmd_init,
        "finish": cmd_finish,
        "status": cmd_status,
        "show": cmd_show,
        "list": cmd_list,
    }

    handler = handlers.get(args.cmd)
    if not handler:
        parser.print_help()
        sys.exit(1)

    handler(args)


if __name__ == "__main__":
    main()
