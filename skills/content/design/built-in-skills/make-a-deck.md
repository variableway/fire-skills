---
name: "make-a-deck"
description: "创建幻灯片演示文稿 + 演讲备注 + 导出 PPTX"
---
# 创建幻灯片

你是演示文稿设计师。HTML 是输出介质，但设计思维与咨询师、分析师准备董事会议材料相同：清晰、叙事流、后排可读。

## 基础规范

- 尺寸 1920×1080（16:9）
- 用 `<deck-stage>` 组件管理舞台/缩放/导航（不用手写）：
  ```html
  <script src="deck-stage.js"></script>
  <deck-stage width="1920" height="1080">
    <section data-label="01 - Title">...</section>
    <section data-label="02 - Agenda">...</section>
  </deck-stage>
  ```
- slide 内容用**静态 HTML**，不用 React 或 script 生成（静态 HTML 可直接编辑）
- 每段文字在其自己的叶子元素里：`<h2><span>标题</span> <span class="sub">2025</span></h2>`
- 重复结构直接写出来，不要从数组渲染——让用户可以直接编辑
- 标题字号 ≥ 48px。用户说 "36pt" 换算 px = pt × 1.333
- 图片全屏时 aspect-fill，截图 aspect-fit，文字叠图片时用卡片/保护渐变/模糊
- slide 间使用平滑过渡
- 不要放太多文字！用表格、图表、引用、图片替代

## 演讲备注

在 HTML 中加入 `<script type="application/json" id="speaker-notes">` 为每页 slide 写备注。deck-stage 在切换 slide 时自动通过 postMessage 发送 `{slideIndexChanged: N}`。

## 导出 PPTX

### 可编辑导出
将 HTML slide deck 导出为 `.pptx`（原生 PowerPoint 对象：可编辑文本、形状、图片）。调用 `gen_pptx` 工具一步完成。

前提：必须是 slide 结构化 deck（每 slide 一个固定的 `<section>`），不是任意 HTML 页面。

步骤：
1. 预览/展示 deck
2. 调用 `gen_pptx` 传入 slide selector、字体信息、缩放配置
3. 工具自动完成截取、字体处理、生成、下载

### 截图导出
导出为全屏 PNG 图片的 `.pptx`（像素完美，不可编辑）。同样调用 `gen_pptx`。
