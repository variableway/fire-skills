---
name: "interactive-prototype"
description: "交互原型 + 移动端原型"
---
# 交互原型

## 桌面端交互原型

创建功能完整的交互原型，含真实状态管理和过渡。

- 用 React `useState`/`useEffect` 处理动态行为
- 包含 hover 状态、点击交互、表单验证、动画过渡、多步骤导航
- 感觉像真正的应用，不是静态 mockup
- 超过单屏用多文件 JSX：`<script type="text/babel" src="...jsx">`
- 跨文件组件通过 `window.MyComponent = MyComponent` 共享

## 移动端原型

用户要在 iPhone 上打开并 pin 到主屏幕。默认产出单文件 HTML。

**必需的 `<head>` 标签：**
```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
```

- 使用 `starter-components/ios-frame.jsx` 包裹内容做 iPhone 外壳
- 如果有 Android 需求，用 `starter-components/android-frame.jsx`
- 触控友好：按钮 ≥ 44px、足够的间距
- 处理安全区域：`env(safe-area-inset-*)`
