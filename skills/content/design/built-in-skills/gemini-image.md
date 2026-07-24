---
name: "gemini-image"
description: "用 Gemini AI 生成图片"
---
# Gemini 图片生成

在原型中用 Gemini 生成图片。提供 prompt → 调用 API → 展示结果。

- API key 用浏览器 prompt() 获取，不硬编码
- 展示 loading 状态（spinner/progress）
- 错误时显示友好提示
- 生成结果缓存到 localStorage 避免重复调用
