#!/bin/bash
# Claude Code + Anthropic 原始配置
# 用法: source ai-config/templates/claude-code/anthropic.sh
# 恢复使用 Anthropic 原始 API

unset ANTHROPIC_BASE_URL

echo "✅ Claude Code 已恢复使用 Anthropic 原始 API"
echo ""
echo "请确保已设置:"
echo '  export ANTHROPIC_API_KEY="your-anthropic-key"'
echo ""
echo "⚠️  国内用户可能需要配置代理:"
echo '  export HTTP_PROXY="http://your-proxy:port"'
echo '  export HTTPS_PROXY="http://your-proxy:port"'
echo ""
echo "启动命令:"
echo "  claude"
