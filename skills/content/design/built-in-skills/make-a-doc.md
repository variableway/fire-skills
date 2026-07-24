---
name: "make-a-doc"
description: "创建文档（简历/报告/备忘录）+ 导出 PDF/独立 HTML + 发送到 Canva/Figma"
---
# 创建文档

## 文档规范

做文档（简历、一页纸、备忘录、信函、报告）时，在 Web 上渲染为纸页并完美打印。

### 屏幕展示
- 页面容器：max-width 816px (US Letter @ 96dpi)，居中，白色背景，~64-72px padding，微妙阴影，2-4px 圆角
- body 背景用柔和中性色（如 `#F0EEE6`），营造"桌面上的纸"的阅读感
- 多页文档：每个 `.page` 容器之间留可见间距
- 文档排版非网页排版：14-16px body、清晰层级、真正内边距，不全文宽

### 打印
```css
@media print {
  body { background: none; }
  .page { width: auto; margin: 0; padding: 0; box-shadow: none; border: none; }
  @page { margin: 0.75in; }
  .page { break-after: page; }
  section, h1+p, li, tr { break-inside: avoid; }
}
```

## 导出独立 HTML

产出单文件自包含 HTML，所有资源内联。供离线打开。
- 将外部 CSS/JS 内联到 `<style>`/`<script>` 标签中
- 用 `save-as-standalone-html` 工具流程

## 导出 PDF

利用 `@media print` 规则，通过浏览器的 Print → Save as PDF 即可产出干净 PDF。确保打印样式表完整。

## 发送到 Canva/Figma

如需导入 Canva 或 Figma：
- 导出为独立 HTML 文件
- 指导用户：Canva 用 "Import" → HTML；Figma 用插件或手动对照
- 提供关键设计 token（颜色、字体、间距）清单
