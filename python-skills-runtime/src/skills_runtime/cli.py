"""CLI entry point for skills runtime."""

import sys
from pathlib import Path


def main():
    """Main entry point."""
    print("Skills Runtime v0.1.0")
    print(f"Python: {sys.version}")
    print(f"Location: {Path(__file__).parent.parent.parent}")


if __name__ == "__main__":
    main()
