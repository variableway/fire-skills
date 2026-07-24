---
name: "use-design-system"
description: "在项目中消费现有设计系统"
---
# 消费设计系统

在设计项目中使用已编译的设计系统。

## 发现可用系统

```bash
# 列出所有已编译的设计系统
glob designs/*/_ds_manifest.json
```

## 导入到项目

```bash
node <skill>/agents/import-design-system.mjs <dsDir> designs/<project>
```

这会在 `designs/<project>/_ds/<slug>/` 创建自包含副本，并在 `_d_meta.json` 记录绑定。

## 加载系统 Prompt

每个绑定的系统都要读其 prompt：

```bash
read designs/<project>/_ds/<slug>/_ds_prompt.md
```

该 prompt 是**绑定的视觉约束**——只从它的 token 和 component 构建。

## 接入 HTML

```html
<!-- 加载 bundle -->
<script src="_ds/<slug>/_ds_bundle.js"></script>

<!-- 加载基础样式（主系统的 link 放最后） -->
<link rel="stylesheet" href="_ds/<slug>/styles.css">
<link rel="stylesheet" href="_ds/<slug>/theme.css">
```

## 起始点种子

如果用户选了起始点，复制对应的 seed screen 到项目根，重写 `<link>` 和 `<script src>` 指向 `_ds/<slug>/` 副本。

## 续作已有项目

先读 `_d_meta.json`：
- 如有 `designSystems` 列表 → 项目已绑定，读取每个 `_ds/<slug>/_ds_prompt.md`
- 不要重新询问要用哪个系统

## 记录交付物

每个交付物创建后用 `record-asset.mjs` 记录：
```bash
node <skill>/agents/record-asset.mjs designs/<project> "<file>"
```
- 自动创建/更新 `_d_meta.json`
- 删除或重命名时用 `--remove`
- 审核后更新状态：`--status approved` / `--status changes-requested`
