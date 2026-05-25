# OKLCH 主题系统

## 色彩空间

使用 OKLCH 替代传统的 HSL/RGB：

- 更符合人眼感知
- 更好的明度均匀性
- 支持 P3 广色域

格式：`oklch(L C H)` — Lightness(0-1) Chroma(0-0.4) Hue(0-360)

## 语义化变量

### 亮色模式（:root）

```css
:root {
  --background: oklch(1 0 0);            /* 纯白 */
  --foreground: oklch(0.145 0 0);        /* 近黑 */
  --primary: oklch(0.205 0 0);           /* 深黑（主色） */
  --primary-foreground: oklch(0.985 0 0);/* 近白（主色文字） */
  --secondary: oklch(0.97 0 0);          /* 浅灰 */
  --muted: oklch(0.97 0 0);              /* 弱化背景 */
  --muted-foreground: oklch(0.556 0 0);  /* 弱化文字 */
  --accent: oklch(0.97 0 0);             /* 强调背景 */
  --destructive: oklch(0.577 0.245 27.325); /* 红色（危险） */
  --border: oklch(0.922 0 0);            /* 边框 */
  --ring: oklch(0.708 0 0);              /* 焦点环 */
  --radius: 0.625rem;                    /* 基础圆角 */
}
```

### 暗色模式（.dark）

```css
.dark {
  --background: oklch(0.145 0 0);        /* 深色背景 */
  --foreground: oklch(0.985 0 0);        /* 浅色文字 */
  --primary: oklch(0.985 0 0);           /* 白色（主色） */
  --destructive: oklch(0.396 0.141 25.723); /* 暗红 */
}
```

## 圆角系统

```css
--radius: 0.625rem;           /* 基础 */
--radius-sm: calc(var(--radius) - 4px);  /* 0.375rem */
--radius-md: calc(var(--radius) - 2px);  /* 0.5rem */
--radius-lg: var(--radius);              /* 0.625rem */
--radius-xl: calc(var(--radius) + 4px);  /* 1.025rem */
```

## 图表配色

```css
--chart-1: oklch(0.646 0.222 41.116);   /* 橙色 */
--chart-2: oklch(0.6 0.118 184.704);    /* 青色 */
--chart-3: oklch(0.398 0.07 227.392);   /* 深蓝 */
--chart-4: oklch(0.828 0.189 84.429);   /* 黄色 */
--chart-5: oklch(0.769 0.188 70.08);    /* 金色 */
```

## 侧边栏变量

```css
--sidebar: oklch(0.985 0 0);
--sidebar-foreground: oklch(0.145 0 0);
--sidebar-primary: oklch(0.205 0 0);
--sidebar-accent: oklch(0.97 0 0);
--sidebar-border: oklch(0.922 0 0);
```

## 字体

```css
--font-sans: 'Geist', 'Geist Fallback';
--font-mono: 'Geist Mono', 'Geist Mono Fallback';
```

## 使用方式

### Tailwind 中使用

```tsx
// 直接使用语义化 class
<div className="bg-background text-foreground">
  <div className="bg-card border border-border rounded-lg p-4">
    <h2 className="text-primary">标题</h2>
    <p className="text-muted-foreground">描述文字</p>
  </div>
</div>
```

### 自定义颜色

```css
/* 使用 OKLCH 格式添加自定义色 */
:root {
  --my-brand: oklch(0.65 0.25 280);  /* 紫色品牌色 */
}
```

```tsx
// 在 Tailwind 中引用
<div className="bg-[var(--my-brand)]" />
```
