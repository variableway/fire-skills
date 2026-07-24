---
name: "design-system"
description: "创建、编译、预览设计系统（合并 authoring + components + compiler + preview）"
---
# 设计系统

## 创建流程

当用户要求创建新的设计系统或 UI kit 时：

### 1. 项目结构

```
designs/<ds-name>/
├── styles.css              # 全局 CSS + @import 链
├── <Component>.d.ts        # 组件 Props 类型声明
├── <Component>.jsx/.tsx    # 组件实现（PascalCase）
├── <card>.html             # @dsCard 标记的预览卡片
├── _ds_bundle.js           # 编译产物（不手改）
├── _ds_manifest.json       # 编译产物（不手改）
├── _adherence.oxlintrc.json
├── preview.html            # 编译后的预览页
└── README.md
```

### 2. 全局 CSS
- 根目录的 `styles.css`（或 `index.css`/`globals.css`/`tokens.css`）
- 所有 `@import` 都被 include
- Token 和 `@font-face` 从闭包中读取

### 3. 组件
- PascalCase `.d.ts` + 同目录下对应 `.jsx`/`.tsx`
- 没有 `.d.ts` 的 `.jsx` 仍然会被打包，但无 props 合约

### 4. 预览卡片
在任何 `.html` 第一行加：
```html
<!-- @dsCard group="<Group>" viewport="<WxH>" name="<Label>" subtitle="..." -->
```

### 5. 起始点（可选）
- Screen：`.html` 第一行 `<!-- @startingPoint section="<Group>" ... -->`
- Component：在 `.d.ts` 的 Props JSDoc 中加 `@startingPoint`

### 6. 编译
每次编辑完运行：
```bash
node <skill>/agents/compile-design-system.mjs designs/<project>
```

### 7. 校验
```bash
node <skill>/agents/check-design-system.mjs designs/<project>
```
报告 namespace、组件、卡片、起始点、token、字体和问题。

### 8. 生成预览页
```bash
node <skill>/agents/build-preview.mjs designs/<project>
```
产出 `designs/<project>/preview.html`（自包含交互式页面，含 README + 所有卡片）。

## 设计系统预览

编译完成后，`preview.html` 是一个独立的预览页：
- 加载 `_ds_bundle.js`，通过 `window.<Namespace>.<Component>` 读取组件
- 显示所有 `@dsCard` 标记的卡片
- 可交互浏览所有组件

## 组件规范

- 组件必须用 TypeScript，提供完整 Props 类型
- 用 CSS 变量做主题 token
- 支持 light/dark 主题切换
- 遵循 shadcn/ui 的 `cn()` + `class-variance-authority` 模式
