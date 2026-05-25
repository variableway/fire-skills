#!/bin/bash
# Claude Code + GLM 配置脚本
# 用法: source ai-config/templates/claude-code/glm.sh
#
# 将 Claude Code 的请求重定向到智谱 GLM API
# 模型映射: Opus/Sonnet -> GLM-5.1, Haiku -> GLM-4.5-Air

export ANTHROPIC_BASE_URL="https://open.bigmodel.cn/api/anthropic"

echo "✅ Claude Code 已配置使用 GLM"
echo "   ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL"
echo ""
echo "请确保已设置 API Key:"
echo '  export ANTHROPIC_API_KEY="your-zhipu-api-key"'
echo ""
echo "启动命令:"
echo "  claude"
echo ""
echo "启动后输入 /status 确认模型状态"
echo ""
echo "💡 如不想覆盖原有 Claude 配置，可在 ~/.zshrc 中添加 alias:"
echo '  alias glm-cc='"'"'ANTHROPIC_BASE_URL=https://open.bigmodel.cn/api/anthropic ANTHROPIC_API_KEY="your-key" claude'"'"
