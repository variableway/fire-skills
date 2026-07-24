# React + Babel 开发参考

## 版本锁定

使用精确锁定的 CDN 版本（含 integrity hash）：

```html
<script src="https://unpkg.com/react@18.3.1/umd/react.development.js"
  integrity="sha384-hD6/rw4ppMLGNu3tX5cjIb+uRZ7UkRJ6BPkLpg4hAu/6onKUg4lLsHAs9EBPT82L"
  crossorigin="anonymous"></script>
<script src="https://unpkg.com/react-dom@18.3.1/umd/react-dom.development.js"
  integrity="sha384-u6aeetuaXnQ38mYT8rp6sbXaQe3NL9t+IBXmnYxwkUI2Hw4bsp2Wvmx4yRQF1uAm"
  crossorigin="anonymous"></script>
<script src="https://unpkg.com/@babel/standalone@7.29.0/babel.min.js"
  integrity="sha384-m08KidiNqLdpJqLq95G/LEi8Qvjl/xUYll3QILypMoQ65QorJ9Lvtp2RXYGBFj1y"
  crossorigin="anonymous"></script>
```

## 多文件加载（Babel 模式）

```html
<script type="text/babel" src="icons.jsx"></script>
<script type="text/babel" src="data.jsx"></script>
<script type="text/babel" src="components-sidebar.jsx"></script>
<script type="text/babel" src="app.jsx"></script>
```

- Babel 转译在浏览器中，无需构建步骤
- 必须通过 HTTP 服务器访问（不能 `file://` 打开）
- 不用 `type="module"`

## 跨文件组件共享

每个 `<script type="text/babel">` 有独立作用域。要共享组件，导出到 `window`：

```js
// 在 components.jsx 末尾：
window.Sidebar = Sidebar;
window.Button = Button;
```

## 样式命名

**全局样式对象必须用唯一名称，否则多组件会冲突：**

```js
// 正确：
const headerStyles = { ... };
const sidebarStyles = { ... };

// 错误（会导致覆盖）：
const styles = { ... };
const styles = { ... };
```

## 静态样式 vs 动态样式

**优先用 CSS 变量 + className，仅动态值用 inline style：**

```css
:root { --bg: #fff; --text: rgba(0,0,0,.85); --accent: #007aff; }
[data-theme="dark"] { --bg: #1e1e1e; --text: rgba(255,255,255,.92); --accent: #0a84ff; }
```

```jsx
// 动态值才用 inline style
<div style={{ width: progress + '%' }} />

// 静态样式用 className
<div className="card-header" />
```

## HTML 规范

- 闭合所有非 void 元素：`<p>...</p>`（不依赖隐式闭合）
- 双引号所有属性值
- 不自闭合非 void 元素：`<div></div>` 不用 `<div/>`
- 每个 `[data-screen-label]` 标记 slide 或高 level 屏幕

## 组件目录命名

当用 CDN + `<script type="text/babel">` 加载时，文件分拆按照依赖顺序。不要把所有东西塞进一个大文件。
