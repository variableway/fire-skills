#!/usr/bin/env python3
"""
Repo Analyzer - 克隆并分析代码仓库，归档结构化分析报告。

Usage:
    python analyze_repo.py https://github.com/user/repo
    python analyze_repo.py /path/to/local/repo --output ./analysis
    python analyze_repo.py <repo> --force --no-codegraph
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from urllib.parse import urlparse


DEFAULT_OUTPUT_ROOT = Path.home() / "innate-revisit" / "analysis" / "repo"

LANG_BY_EXT = {
    ".ts": "TypeScript", ".tsx": "TypeScript",
    ".js": "JavaScript", ".jsx": "JavaScript", ".mjs": "JavaScript",
    ".py": "Python",
    ".go": "Go",
    ".rs": "Rust",
    ".java": "Java", ".kt": "Kotlin",
    ".c": "C", ".h": "C",
    ".cpp": "C++", ".cc": "C++", ".hpp": "C++",
    ".cs": "C#",
    ".rb": "Ruby",
    ".php": "PHP",
    ".swift": "Swift",
    ".dart": "Dart",
    ".lua": "Lua",
    ".sh": "Shell", ".bash": "Shell", ".zsh": "Shell",
    ".vue": "Vue", ".svelte": "Svelte",
}

SKIP_DIRS = {".git", "node_modules", "dist", "build", "target", ".next",
             "__pycache__", ".venv", "venv", ".idea", ".vscode", ".cache",
             "coverage", ".turbo", ".nuxt", "out"}

ENTRY_FILES = [
    "main.py", "__main__.py", "manage.py", "app.py", "server.py",
    "index.ts", "index.js", "main.ts", "main.js", "server.ts",
    "main.go", "main.rs", "Main.java", "main.swift",
    "src/main.rs", "src/main.ts", "src/index.ts", "src/cli.ts",
    "cmd/main.go",
]


def log(msg: str) -> None:
    print(msg, flush=True)


def run(cmd: List[str], cwd: Optional[Path] = None, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=cwd, check=check, capture_output=True, text=True)


def is_url(s: str) -> bool:
    return s.startswith(("http://", "https://", "git@"))


def repo_name_from_source(source: str) -> str:
    if is_url(source):
        if source.startswith("git@"):
            tail = source.split(":", 1)[-1]
        else:
            tail = urlparse(source).path
        return Path(tail).stem
    return Path(source).resolve().name


def clone_repo(url: str, depth: int = 1) -> Path:
    tmp = Path(tempfile.mkdtemp(prefix="repo-analyzer-"))
    log(f"📥 Cloning {url} (depth={depth})...")
    run(["git", "clone", "--depth", str(depth), url, str(tmp)])
    return tmp


def get_commit_sha(repo: Path) -> Optional[str]:
    try:
        return run(["git", "rev-parse", "HEAD"], cwd=repo).stdout.strip()
    except Exception:
        return None


def detect_languages(repo: Path) -> Tuple[Dict[str, int], int, int]:
    counts: Dict[str, int] = {}
    total_files = 0
    total_loc = 0
    for root, dirs, files in os.walk(repo):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in files:
            ext = Path(f).suffix.lower()
            lang = LANG_BY_EXT.get(ext)
            if not lang:
                continue
            total_files += 1
            counts[lang] = counts.get(lang, 0) + 1
            try:
                with open(Path(root) / f, "rb") as fh:
                    total_loc += sum(1 for _ in fh)
            except Exception:
                pass
    return counts, total_files, total_loc


def detect_frameworks(repo: Path) -> List[str]:
    found = set()
    pkg = repo / "package.json"
    if pkg.exists():
        try:
            data = json.loads(pkg.read_text(encoding="utf-8", errors="ignore"))
            deps = {**data.get("dependencies", {}), **data.get("devDependencies", {})}
            mapping = {
                "next": "Next.js", "react": "React", "vue": "Vue", "svelte": "Svelte",
                "express": "Express", "fastify": "Fastify", "nestjs": "NestJS",
                "@nestjs/core": "NestJS", "vite": "Vite", "webpack": "Webpack",
                "@modelcontextprotocol/sdk": "MCP",
            }
            for k, v in mapping.items():
                if k in deps:
                    found.add(v)
        except Exception:
            pass
    if (repo / "manage.py").exists() or (repo / "settings.py").exists():
        found.add("Django")
    if (repo / "Cargo.toml").exists():
        found.add("Cargo")
    if (repo / "go.mod").exists():
        found.add("Go modules")
    if (repo / "pyproject.toml").exists():
        found.add("Python (pyproject)")
    if (repo / "pom.xml").exists():
        found.add("Maven")
    if (repo / "build.gradle").exists() or (repo / "build.gradle.kts").exists():
        found.add("Gradle")
    return sorted(found)


def detect_entry_points(repo: Path) -> List[str]:
    hits = []
    for ep in ENTRY_FILES:
        if (repo / ep).exists():
            hits.append(ep)
    pkg = repo / "package.json"
    if pkg.exists():
        try:
            data = json.loads(pkg.read_text(encoding="utf-8", errors="ignore"))
            if "main" in data:
                hits.append(data["main"])
            if "bin" in data:
                bins = data["bin"] if isinstance(data["bin"], dict) else {"_": data["bin"]}
                for v in bins.values():
                    hits.append(v)
        except Exception:
            pass
    return sorted(set(hits))


def read_text_safe(p: Path, limit: int = 4000) -> str:
    try:
        text = p.read_text(encoding="utf-8", errors="ignore")
        return text[:limit]
    except Exception:
        return ""


def top_level_dirs(repo: Path) -> List[str]:
    return sorted(
        d.name for d in repo.iterdir()
        if d.is_dir() and d.name not in SKIP_DIRS and not d.name.startswith(".")
    )


def codegraph_available() -> bool:
    return shutil.which("codegraph") is not None


def run_codegraph(repo: Path, out_dir: Path) -> bool:
    log("✅ CodeGraph found, building index...")
    try:
        run(["codegraph", "init", "--yes"], cwd=repo, check=False)
    except Exception as e:
        log(f"⚠ codegraph init failed: {e}")
        return False
    cg_src = repo / ".codegraph"
    if cg_src.exists():
        cg_dst = out_dir / "codegraph"
        cg_dst.mkdir(parents=True, exist_ok=True)
        for item in cg_src.iterdir():
            if item.is_file() and item.suffix in {".json", ".db", ".sqlite"}:
                shutil.copy2(item, cg_dst / item.name)
        return True
    return False


def render_analysis_md(meta: dict, repo: Path) -> str:
    lang_lines = "\n".join(
        f"| {lang} | {count} files |" for lang, count in
        sorted(meta["language_breakdown"].items(), key=lambda x: -x[1])
    )
    fw = ", ".join(meta["frameworks"]) or "—"
    eps = "\n".join(f"- `{e}`" for e in meta["entry_points"]) or "_未检测到明显入口_"
    dirs = "\n".join(f"- `{d}/`" for d in meta["top_level_dirs"])
    readme = read_text_safe(repo / "README.md", limit=2000) or "_未找到 README.md_"
    return f"""# Analysis: {meta['repo_name']}

> Generated by repo-analyzer · {meta['indexed_at']}

## 元数据

| 字段 | 值 |
|------|------|
| Repo | `{meta.get('repo_url') or meta.get('source')}` |
| Commit | `{meta.get('commit_sha') or 'N/A'}` |
| Primary language | {meta['primary_language']} |
| Files | {meta['file_count']} |
| LOC | {meta['loc']:,} |
| Frameworks | {fw} |
| CodeGraph indexed | {'✅' if meta['codegraph_available'] else '❌ (fallback to static scan)'} |

## 语言分布

| Language | Count |
|----------|-------|
{lang_lines}

## 顶层目录

{dirs}

## 入口点

{eps}

## README 摘录

```
{readme}
```

## CodeGraph 产物

{"- `codegraph/` 目录包含 symbols / routes / call-graph 索引" if meta['codegraph_available'] else "_CodeGraph 未启用。安装：_`curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh`"}

## 下一步建议

1. 阅读上面列出的入口点文件，理解程序启动流程
2. 检查顶层目录的命名约定，识别架构分层（src / app / cmd / internal ...）
3. 若启用了 CodeGraph，可用 `codegraph_context <symbol>` 进一步追踪
4. 关注 `package.json` / `Cargo.toml` / `pyproject.toml` 中的脚本和依赖
"""


def write_outputs(out_dir: Path, meta: dict, repo: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "metadata.json").write_text(
        json.dumps(meta, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    (out_dir / "analysis.md").write_text(render_analysis_md(meta, repo), encoding="utf-8")
    (out_dir / "README.md").write_text(
        f"# {meta['repo_name']} — analysis index\n\n"
        f"- [analysis.md](analysis.md) — 完整报告\n"
        f"- [metadata.json](metadata.json) — 结构化元数据\n"
        f"{'- [codegraph/](codegraph/) — CodeGraph 索引' if meta['codegraph_available'] else ''}\n\n"
        f"Re-run with `--force` to refresh.\n",
        encoding="utf-8",
    )


def already_analyzed(out_dir: Path) -> bool:
    return (out_dir / "metadata.json").exists() and (out_dir / "analysis.md").exists()


def analyze(args: argparse.Namespace) -> int:
    source = args.source
    name = repo_name_from_source(source)
    out_dir = Path(args.output).expanduser() if args.output else DEFAULT_OUTPUT_ROOT / name

    if already_analyzed(out_dir) and not args.force:
        log(f"ℹ Cached analysis at {out_dir} (use --force to re-run)")
        return 0

    cleanup_clone: Optional[Path] = None
    if is_url(source):
        repo_path = clone_repo(source, depth=args.depth)
        cleanup_clone = repo_path
        repo_url = source
    else:
        repo_path = Path(source).expanduser().resolve()
        if not repo_path.exists():
            log(f"❌ Path not found: {repo_path}")
            return 1
        repo_url = None

    try:
        log("🔍 Detecting languages and structure...")
        lang_counts, file_count, loc = detect_languages(repo_path)
        primary = max(lang_counts.items(), key=lambda x: x[1])[0] if lang_counts else "Unknown"

        meta = {
            "repo_name": name,
            "repo_url": repo_url,
            "source": str(source),
            "commit_sha": get_commit_sha(repo_path),
            "indexed_at": datetime.now(timezone.utc).isoformat(),
            "primary_language": primary,
            "language_breakdown": lang_counts,
            "file_count": file_count,
            "loc": loc,
            "frameworks": detect_frameworks(repo_path),
            "entry_points": detect_entry_points(repo_path),
            "top_level_dirs": top_level_dirs(repo_path),
            "codegraph_available": False,
        }

        if args.probe:
            out_dir.mkdir(parents=True, exist_ok=True)
            (out_dir / "metadata.json").write_text(
                json.dumps(meta, indent=2, ensure_ascii=False), encoding="utf-8"
            )
            log(f"✅ Probe written → {out_dir}/metadata.json")
            return 0

        if not args.no_codegraph and codegraph_available():
            meta["codegraph_available"] = run_codegraph(repo_path, out_dir)
        elif not args.no_codegraph:
            log("⚠ codegraph not on PATH — falling back to static scan")
            log("   Install: curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh")

        log("📊 Generating analysis report...")
        write_outputs(out_dir, meta, repo_path)
        log(f"✅ Done → {out_dir}")
        return 0
    finally:
        if cleanup_clone and not args.keep_clone:
            shutil.rmtree(cleanup_clone, ignore_errors=True)


def main() -> int:
    p = argparse.ArgumentParser(description="Analyze a code repository and archive a structured report.")
    p.add_argument("source", help="Repo URL or local path")
    p.add_argument("--output", "-o", help=f"Output dir (default: {DEFAULT_OUTPUT_ROOT}/<repo-name>)")
    p.add_argument("--force", "-f", action="store_true", help="Re-run even if cached")
    p.add_argument("--no-codegraph", action="store_true", help="Skip CodeGraph indexing")
    p.add_argument("--probe", action="store_true", help="Only write metadata.json")
    p.add_argument("--depth", type=int, default=1, help="git clone depth")
    p.add_argument("--keep-clone", action="store_true", help="Keep cloned repo")
    args = p.parse_args()
    return analyze(args)


if __name__ == "__main__":
    sys.exit(main())
