---
name: "animated-video"
description: "动画视频 + 音效"
---
# 动画视频

创建动画视频或带有时间线内容的设计。使用 CSS 动画、JS 驱动的 timeline、requestAnimationFrame 实现。

- 持久化播放位置：存到 `localStorage`，加载时恢复位置
- 音效：使用 Web Audio API 或 `<audio>` 元素
- 不要在 deck 里用持久化播放——deck-stage 已处理 slide 位置
