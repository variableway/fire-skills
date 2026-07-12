#!/usr/bin/env bash
# build-install.sh — Build skill-spark and install to ~/.local/bin
#
# Usage:
#   ./scripts/build-install.sh
#
# Description:
#   Runs `bun run build:all`, then copies the compiled executable
#   (or the JS entry point as fallback) to ~/.local/bin so that
#   `skill-spark` is available globally.
#
#   If ~/.local/bin is missing from PATH, a warning with setup
#   instructions is printed.
#
# Examples:
#   ./scripts/build-install.sh          # Build and install
#   bun run build:install               # Same via package.json script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOCAL_BIN="$HOME/.local/bin"
INSTALL_NAME="skill-spark"

# ─── Preconditions ────────────────────────────────────────────────────────────

if ! command -v bun &>/dev/null; then
  echo "Error: bun is required but not found in PATH." >&2
  echo "Please install Bun: https://bun.sh" >&2
  exit 1
fi

# ─── Build ────────────────────────────────────────────────────────────────────

echo "🔨  Building skill-spark (bun run build:all)..."
cd "$PROJECT_DIR"
bun run build:all

# ─── Locate output ────────────────────────────────────────────────────────────

SOURCE_BIN=""
if [ -f "$PROJECT_DIR/dist/skill-spark" ]; then
  SOURCE_BIN="$PROJECT_DIR/dist/skill-spark"
  echo "   Found compiled executable: $SOURCE_BIN"
elif [ -f "$PROJECT_DIR/dist/index.js" ]; then
  SOURCE_BIN="$PROJECT_DIR/dist/index.js"
  echo "   Found JS entry point: $SOURCE_BIN"
else
  echo "Error: Build output not found in dist/" >&2
  exit 1
fi

# ─── Install to ~/.local/bin ──────────────────────────────────────────────────

if [ ! -d "$LOCAL_BIN" ]; then
  echo "📁  Creating $LOCAL_BIN ..."
  mkdir -p "$LOCAL_BIN"
fi

echo "📦  Installing $INSTALL_NAME → $LOCAL_BIN/$INSTALL_NAME"

# Remove existing symlink or file to avoid conflicts
if [ -L "$LOCAL_BIN/$INSTALL_NAME" ] || [ -f "$LOCAL_BIN/$INSTALL_NAME" ]; then
  rm -f "$LOCAL_BIN/$INSTALL_NAME"
fi

cp "$SOURCE_BIN" "$LOCAL_BIN/$INSTALL_NAME"
chmod +x "$LOCAL_BIN/$INSTALL_NAME"

echo "✅  Installed: $LOCAL_BIN/$INSTALL_NAME"

# ─── PATH check ───────────────────────────────────────────────────────────────

if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
  echo ""
  echo "⚠️   Warning: $LOCAL_BIN is not in your PATH."
  echo "    Add the following line to your shell configuration, then restart your terminal:"
  echo ""
  case "${SHELL:-}" in
    */zsh)
      echo "      echo 'export PATH=\"\\$HOME/.local/bin:\\$PATH\"' >> ~/.zshrc"
      ;;
    */bash)
      echo "      echo 'export PATH=\"\\$HOME/.local/bin:\\$PATH\"' >> ~/.bashrc"
      ;;
    *)
      echo "      export PATH=\"\$HOME/.local/bin:\$PATH\""
      ;;
  esac
  echo ""
fi

# ─── Verification ─────────────────────────────────────────────────────────────

echo "🔍  Verifying installation..."

if command -v skill-spark &>/dev/null; then
  INSTALLED_VERSION=$(skill-spark --version 2>/dev/null || echo "unknown")
  echo "✅  skill-spark is available globally."
  echo "    Version: $INSTALLED_VERSION"
else
  echo "⚠️   skill-spark is not yet available in the current shell's PATH."
  echo "    After updating your shell configuration, run: skill-spark --version"
  echo "    Or test directly: $LOCAL_BIN/$INSTALL_NAME --version"
fi
