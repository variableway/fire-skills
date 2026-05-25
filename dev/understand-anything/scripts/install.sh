#!/usr/bin/env bash
# Understand Anything Skill Installer (macOS / Linux)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_NAME="$(basename "$SKILL_ROOT")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Understand Anything Skill Installer${NC}"
echo ""

INSTALL_TARGET="${1:-project}"

install_skill_link() {
    local target_dir="$1"
    local link_path="$target_dir/$SKILL_NAME"
    
    mkdir -p "$target_dir"
    
    if [ -e "$link_path" ] || [ -L "$link_path" ]; then
        echo -e "${YELLOW}  [SKIP]${NC} $SKILL_NAME already exists at $link_path"
        return 1
    fi
    
    ln -s "$SKILL_ROOT" "$link_path"
    echo -e "${GREEN}  [OK]${NC}   $SKILL_NAME -> $link_path"
    return 0
}

case "$INSTALL_TARGET" in
    project)
        echo -e "${BLUE}Installing to project directories...${NC}"
        install_skill_link "./.agents/skills"
        install_skill_link "./.claude/skills"
        install_skill_link "./.kimi/skills"
        ;;
    system)
        echo -e "${BLUE}Installing to system directories...${NC}"
        install_skill_link "$HOME/.claude/skills"
        install_skill_link "$HOME/.kimi/skills"
        install_skill_link "$HOME/.codex/skills"
        install_skill_link "$HOME/.opencode/skills"
        ;;
    *)
        echo -e "${RED}Unknown target: $INSTALL_TARGET${NC}"
        echo "Usage: $0 [project|system]"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Note: Understand Anything also requires the plugin to be installed:"
echo "  Claude Code: /plugin marketplace add Lum1104/Understand-Anything && /plugin install understand-anything"
echo "  Trae: /plugin marketplace add Lum1104/Understand-Anything && /plugin install understand-anything"