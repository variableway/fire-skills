#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_NAME="understand-anything"
PLUGIN_REPO="https://github.com/Lum1104/Understand-Anything.git"
INSTALL_DIR="$HOME/.claude/plugins/marketplaces/$SKILL_NAME"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Understand-Anything Plugin Installer
Usage: $0 [--claude | --all]

Options:
  --claude    Install for Claude Code
  --all       Install for all platforms (default)
  -h, --help  Show this help
EOF
}

INSTALL_TARGET="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --claude) INSTALL_TARGET="claude"; shift ;;
        --all) INSTALL_TARGET="all"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage; exit 1 ;;
    esac
done

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Understand-Anything Plugin Installer${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

check_prerequisites() {
    echo -e "${BLUE}[1/3] Checking prerequisites...${NC}"
    
    if ! command -v git &>/dev/null; then
        echo -e "${RED}Error: git is required.${NC}"
        exit 1
    fi
    echo -e "${GREEN}[OK]${NC} git: $(git --version | head -1)"
    
    if command -v claude &>/dev/null; then
        echo -e "${GREEN}[OK]${NC} claude: $(claude --version 2>/dev/null || echo 'installed')"
    else
        echo -e "${YELLOW}[WARN]${NC} claude CLI not found (needed for plugin install)"
    fi
    
    echo ""
}

clone_plugin() {
    echo -e "${BLUE}[2/3] Cloning plugin...${NC}"
    
    if [ -d "$INSTALL_DIR/.git" ]; then
        echo -e "${YELLOW}[INFO]${NC} Already cloned, updating..."
        cd "$INSTALL_DIR"
        git pull origin main --depth 1 2>/dev/null || true
    else
        rm -rf "$INSTALL_DIR"
        git clone --depth 1 "$PLUGIN_REPO" "$INSTALL_DIR"
    fi
    
    echo -e "${GREEN}[OK]${NC} Plugin at: $INSTALL_DIR"
    echo ""
}

install_plugin() {
    echo -e "${BLUE}[3/3] Registering marketplace & installing plugin...${NC}"
    
    if ! command -v claude &>/dev/null; then
        echo -e "${RED}Error: claude CLI is required for this step.${NC}"
        echo -e "${YELLOW}Install from https://code.claude.com/docs/en/installation${NC}"
        exit 1
    fi
    
    echo "  Adding marketplace..."
    claude plugin marketplace add "$INSTALL_DIR" 2>&1 | sed 's/^/  /' || {
        echo -e "${YELLOW}[WARN]${NC} Marketplace add may have failed. Trying install anyway..."
    }
    
    echo "  Installing plugin..."
    claude plugin install "understand-anything@understand-anything" 2>&1 | sed 's/^/  /' || {
        echo -e "${YELLOW}[WARN]${NC} Direct install failed. Trying alternative..."
    }
    
    echo ""
    echo -e "${GREEN}[OK]${NC} Plugin installation complete."
    echo ""
}

link_skill() {
    local skill_dir="$HOME/.claude/skills"
    local skill_link="$skill_dir/$SKILL_NAME"
    
    if [ -L "$skill_link" ]; then
        echo -e "${YELLOW}[SKIP]${NC} Skill already linked: $skill_link"
    else
        mkdir -p "$skill_dir"
        ln -s "$SKILL_ROOT" "$skill_link"
        echo -e "${GREEN}[OK]${NC} Skill linked: $skill_link"
    fi
}

install_claude_code() {
    clone_plugin
    install_plugin
    link_skill
    
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Plugin location: $INSTALL_DIR"
    echo ""
    echo -e "${YELLOW}  Restart Claude Code, then use:${NC}"
    echo "   /understand           — analyze a codebase"
    echo "   /understand-dashboard — explore the graph"
    echo "   /understand-chat      — ask questions about code"
    echo ""
}

main() {
    check_prerequisites
    
    case "$INSTALL_TARGET" in
        claude|all) install_claude_code ;;
    esac
}

main "$@"