---
name: "tweaks"
description: "可调参模式 + 调参协议 + 低级调参 API"
---
# 可调参模式

让设计支持 Tweaks——用户可以在浏览器里直接调整关键参数。

## 启用调参

在 HTML 中引入 tweaks panel：
```html
<script type="text/babel" src="tweaks-panel.jsx"></script>
```

## 注册可调参数

在 React 组件中：
```jsx
// 注册一个可调的颜色
window.__DESIGN_TWEAKS__ = window.__DESIGN_TWEAKS__ || {};
window.__DESIGN_TWEAKS__["Accent Color"] = {
  type: "color",
  value: "#007aff",
  onChange: (val) => document.documentElement.style.setProperty("--accent", val),
};

// 注册一个可调的数字
window.__DESIGN_TWEAKS__["Border Radius"] = {
  type: "range",
  value: 8,
  min: 0,
  max: 24,
  onChange: (val) => document.documentElement.style.setProperty("--radius", val + "px"),
};

// 注册一个开关
window.__DESIGN_TWEAKS__["Show Sidebar"] = {
  type: "toggle",
  value: true,
  onChange: (val) => { /* show/hide sidebar logic */ },
};
```

## 调参协议

- 调参值存到 `localStorage`，刷新页面后保持
- 面板小而精致，不影响主界面
- 用户没要求调参时不主动加面板
- 只暴露高价值参数：关键颜色、布局变体、功能开关、标题文案
