#!/usr/bin/env python3
"""Local Task Workflow 编排器 - 纯本地工作流，无需 GitHub。

支持 AI Agent Protocol：自动捕获和记录 AI Agent 的输出。

用法：
    python orchestrate.py init tasks/login.md "使用 JWT 实现"
    python orchestrate.py status
    python orchestrate.py finish [--auto-capture] [--commit] [--push]
    python orchestrate.py abort
"""

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from tracing import cmd_init as tracing_init, cmd_finish as tracing_finish


STATE_FILE = Path(".local-workflow.state.json")
AGENT_OUTPUT_FILE = Path(".task-output.md")


class _TracingArgs:
    """Minimal args namespace for tracing calls."""
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)


def _get_git_info():
    """获取 git 相关信息用于执行总结。"""
    info = {
        "changed_files": [],
        "commit_hash": None,
        "branch": None
    }
    
    # 获取修改的文件
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only", "HEAD"],
            capture_output=True, text=True, check=False
        )
        if result.returncode == 0:
            info["changed_files"] = [f for f in result.stdout.strip().split("\n") if f]
    except Exception:
        pass
    
    # 获取当前 branch
    try:
        result = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True, text=True, check=False
        )
        if result.returncode == 0:
            info["branch"] = result.stdout.strip()
    except Exception:
        pass
    
    return info


def _read_agent_output():
    """读取 AI Agent 的输出文件（如果存在）。"""
    if AGENT_OUTPUT_FILE.exists():
        content = AGENT_OUTPUT_FILE.read_text(encoding="utf-8")
        return content
    return None


def _generate_auto_summary(state, git_info):
    """自动生成执行总结。"""
    lines = ["## Task Execution Summary", ""]
    
    # 任务信息
    lines.append("### Task Information")
    lines.append(f"- **Task ID**: {state.get('task_id', 'N/A')}")
    lines.append(f"- **Title**: {state.get('title', 'N/A')}")
    if state.get("instructions"):
        lines.append(f"- **Instructions**: {state['instructions']}")
    lines.append("")
    
    # Git 信息
    if git_info["branch"]:
        lines.append(f"- **Branch**: {git_info['branch']}")
    lines.append("")
    
    # 文件变更
    if git_info["changed_files"]:
        lines.append("### Files Changed")
        for f in git_info["changed_files"]:
            lines.append(f"- `{f}`")
        lines.append("")
    
    # 状态
    lines.append("### Execution Status")
    lines.append("- ✅ Task completed successfully")
    lines.append("")
    
    return "\n".join(lines)


def _setup_agent_environment(task_file, task_id):
    """设置 AI Agent 环境变量。"""
    env = os.environ.copy()
    env["TASK_WORKFLOW_MODE"] = "local"
    env["TASK_FILE"] = str(task_file)
    env["TASK_ID"] = task_id
    env["TASK_CAPTURE_OUTPUT"] = "true"
    env["TASK_OUTPUT_FILE"] = str(AGENT_OUTPUT_FILE.absolute())
    env["TASK_TRACING_DIR"] = "tasks/tracing"
    return env


def cmd_init(args):
    task_path = Path(args.task_file)
    if not task_path.exists():
        print(f"Error: Task file not found: {task_path}", file=sys.stderr)
        sys.exit(1)

    if STATE_FILE.exists():
        old = json.loads(STATE_FILE.read_text())
        print(f"Warning: Existing workflow found for task '{old.get('title')}'. Abort it first if stale.", file=sys.stderr)

    # 设置 AI Agent 环境变量
    env = _setup_agent_environment(task_path, "pending")
    
    # Initialize local tracing
    try:
        tracing_args = _TracingArgs(
            task=str(task_path),
            parsed=args.instructions or ""
        )
        task_id = tracing_init(tracing_args)
        
        # 更新环境变量中的 task_id
        env["TASK_ID"] = task_id
        
        # 保存环境变量到 state 文件供后续使用
        state = json.loads(STATE_FILE.read_text())
        state["env"] = {
            "TASK_WORKFLOW_MODE": "local",
            "TASK_FILE": str(task_path),
            "TASK_CAPTURE_OUTPUT": "true",
            "TASK_OUTPUT_FILE": str(AGENT_OUTPUT_FILE.absolute())
        }
        STATE_FILE.write_text(json.dumps(state, indent=2), encoding="utf-8")
        
    except Exception as e:
        print(f"Tracing init error: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"\nTask ID: {task_id}")
    print(f"State saved to: {STATE_FILE}")
    print(f"\nAI Agent Environment:")
    print(f"  TASK_WORKFLOW_MODE=local")
    print(f"  TASK_CAPTURE_OUTPUT=true")
    print(f"  TASK_OUTPUT_FILE={AGENT_OUTPUT_FILE}")
    print("\n=== NEXT STEP ===")
    print("Please implement the task now.")
    print(f"AI Agent should write output to: {AGENT_OUTPUT_FILE}")
    print(f"After implementation, run: python3 .agents/skills/local-workflow/scripts/orchestrate.py finish")


def cmd_status(_args):
    if not STATE_FILE.exists():
        print("No active local workflow found.")
        return

    state = json.loads(STATE_FILE.read_text())
    print(f"Active local workflow:")
    print(f"  Task ID:   {state.get('task_id', 'N/A')}")
    print(f"  Title:     {state.get('title', 'N/A')}")
    print(f"  Task file: {state.get('task_file', 'N/A')}")
    print(f"  Status:    {state.get('status', 'N/A')}")
    print(f"  Started:   {state.get('started_at', 'N/A')}")
    if state.get("completed_at"):
        print(f"  Completed: {state.get('completed_at')}")
    if state.get("instructions"):
        print(f"  Instructions: {state['instructions']}")
    if state.get("tracing_file"):
        print(f"  Tracing:   {state['tracing_file']}")
    
    # 检查 AI Agent 输出文件
    if AGENT_OUTPUT_FILE.exists():
        print(f"\n  AI Agent Output: {AGENT_OUTPUT_FILE} (found)")
        content = AGENT_OUTPUT_FILE.read_text(encoding="utf-8")
        lines = content.strip().split("\n")
        print(f"  Output size: {len(content)} chars, {len(lines)} lines")
    else:
        print(f"\n  AI Agent Output: {AGENT_OUTPUT_FILE} (not found)")
        print("  Tip: AI Agent can write output to this file for automatic capture")


def cmd_finish(args):
    if not STATE_FILE.exists():
        print("Error: No active workflow found. Run 'init' first.", file=sys.stderr)
        sys.exit(1)

    state = json.loads(STATE_FILE.read_text())
    task_file = state.get("task_file", "")
    
    # 获取 git 信息
    git_info = _get_git_info()
    
    # 构建 summary
    summary_parts = []
    
    # 1. 如果有 AI Agent 输出文件，优先使用
    agent_output = _read_agent_output()
    if agent_output:
        summary_parts.append("### AI Agent Output")
        summary_parts.append(agent_output)
        summary_parts.append("")
    
    # 2. 如果有手动提供的 summary，添加它
    if args.summary:
        summary_parts.append("### Additional Notes")
        summary_parts.append(args.summary)
        summary_parts.append("")
    
    # 3. 自动生成的基础 summary
    if args.auto_capture or not agent_output:
        auto_summary = _generate_auto_summary(state, git_info)
        summary_parts.append(auto_summary)
    
    summary = "\n".join(summary_parts)

    # Doc update check — uses shared doc_checker from git-workflow
    try:
        doc_checker = Path(__file__).resolve().parent.parent.parent / "git-workflow" / "scripts" / "doc_checker.py"
        if doc_checker.exists():
            result = subprocess.run(
                [sys.executable, str(doc_checker), "--markdown"],
                capture_output=True, text=True, check=False,
            )
            if result.returncode == 0 and result.stdout.strip():
                doc_suggestion = result.stdout.strip()
                print(doc_suggestion)
                summary += "\n\n" + doc_suggestion
    except Exception:
        pass

    # Update local tracing
    try:
        tracing_args = _TracingArgs(
            task=task_file,
            summary=summary
        )
        tracing_finish(tracing_args)
        print(f"Tracing updated for task: {state.get('title', task_file)}")
    except Exception as e:
        print(f"Tracing finish warning: {e}")

    if args.push and not args.commit:
        print("Error: --push requires --commit. Re-run finish with both flags after reviewing changes.", file=sys.stderr)
        sys.exit(1)

    if args.commit:
        task_title = state.get("title", "task")
        commit_message = args.commit_message or f"Complete: {task_title}"

        try:
            if AGENT_OUTPUT_FILE.exists():
                subprocess.run(["git", "add", str(AGENT_OUTPUT_FILE)], check=False)

            print("Committing requested by --commit. Review staged changes before relying on this automation.")
            subprocess.run(["git", "add", "-A"], check=False)
            commit_result = subprocess.run(
                ["git", "commit", "-m", commit_message],
                capture_output=True, text=True, check=False
            )
            if commit_result.returncode == 0:
                print("Commit created.")
            else:
                print("Commit was not created. Check git status and commit manually if needed.")
                if commit_result.stderr.strip():
                    print(commit_result.stderr.strip())

            if args.push:
                push_result = subprocess.run(["git", "push"], capture_output=True, text=True, check=False)
                if push_result.returncode == 0:
                    print("Code pushed.")
                else:
                    print("Push needs attention. Run git push manually after review.")
                    if push_result.stderr.strip():
                        print(push_result.stderr.strip())
        except Exception as e:
            print(f"Git operation warning: {e}")
    else:
        print("No commit or push was performed. Review changes, run tests, scan secrets, then commit manually or re-run finish with --commit.")

    # 清理
    if AGENT_OUTPUT_FILE.exists() and not args.keep_output:
        AGENT_OUTPUT_FILE.unlink()
        print(f"Cleaned up: {AGENT_OUTPUT_FILE}")

    # Clean up state file
    STATE_FILE.unlink()
    print("Local workflow complete.")


def cmd_abort(_args):
    if not STATE_FILE.exists():
        print("No active workflow to abort.")
        return

    state = json.loads(STATE_FILE.read_text())
    task_file = state.get("task_file", "")
    
    STATE_FILE.unlink()
    
    # 清理 AI Agent 输出文件
    if AGENT_OUTPUT_FILE.exists():
        AGENT_OUTPUT_FILE.unlink()
        print(f"Cleaned up: {AGENT_OUTPUT_FILE}")
    
    print(f"Aborted workflow for task: {state.get('title', task_file)}")


def main():
    parser = argparse.ArgumentParser(
        description="Local Task Workflow Orchestrator (No GitHub Required)",
        epilog="Supports AI Agent Protocol for automatic output capture."
    )
    sub = parser.add_subparsers(dest="cmd", help="Available commands")

    p_init = sub.add_parser("init", help="Create local tracing from task file and save state")
    p_init.add_argument("task_file", help="Path to the task markdown file")
    p_init.add_argument("instructions", nargs="?", default="", help="Additional implementation instructions")

    sub.add_parser("status", help="Show active workflow state")
    
    p_finish = sub.add_parser("finish", help="Update tracing with summary; commit/push only when explicitly requested")
    p_finish.add_argument("--summary", help="Additional summary to append")
    p_finish.add_argument("--auto-capture", action="store_true", help="Auto-generate summary even if agent output exists")
    p_finish.add_argument("--keep-output", action="store_true", help="Keep the .task-output.md file after finish")
    p_finish.add_argument("--commit", action="store_true", help="Create a git commit after updating tracing")
    p_finish.add_argument("--push", action="store_true", help="Push the commit; requires --commit")
    p_finish.add_argument("--commit-message", help="Commit message to use with --commit")
    
    sub.add_parser("abort", help="Remove active workflow state without updating tracing")

    args = parser.parse_args()

    handlers = {
        "init": cmd_init,
        "status": cmd_status,
        "finish": cmd_finish,
        "abort": cmd_abort,
    }

    handler = handlers.get(args.cmd)
    if not handler:
        parser.print_help()
        sys.exit(1)

    handler(args)


if __name__ == "__main__":
    main()
