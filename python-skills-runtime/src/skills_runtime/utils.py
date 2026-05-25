"""Utility functions for skills runtime."""

import subprocess
import sys
from pathlib import Path
from typing import Optional


def run_script(script_path: Path, args: Optional[list[str]] = None) -> int:
    """Run a Python script with uv."""
    cmd = ["uv", "run", str(script_path)]
    if args:
        cmd.extend(args)
    result = subprocess.run(cmd, cwd=script_path.parent)
    return result.returncode


def ensure_uv() -> bool:
    """Check if uv is installed."""
    try:
        subprocess.run(["uv", "--version"], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def get_skills_dir() -> Path:
    """Get the skills directory."""
    return Path(__file__).parent.parent.parent.parent / "dev"
