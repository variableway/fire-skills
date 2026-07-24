---
name: "handoff"
description: "开发者交接 + API 集成指引"
---
# 开发者交接

## 创建交接包

1. 在项目目录创建交接文件夹：
   ```bash
   mkdir -p <project>/design_handoff_<feature>/
   ```

2. 创建 `README.md` 包含：
   - **概述**：功能描述、用户故事
   - **组件清单**：每个组件的名称、用途、props、状态变体
   - **状态模型**：loading / empty / error / success / edge cases
   - **交互流**：关键用户流程（截图 + 步骤说明）
   - **设计 Token**：颜色、字体、间距、圆角、阴影
   - **响应式断点**：mobile / tablet / desktop
   - **无障碍**：键盘导航、屏幕阅读器、焦点管理
   - **依赖**：需要的基础库和组件

3. 截图每个关键屏幕，放到 `screenshots/` 子目录

4. 把交接文件夹路径和 `README.md` 内容概要告诉用户

## API 集成

当原型需要调用 AI API：
- 用 Claude API / Gemini API 做智能功能
- 在原型中包含 loading/error/success 状态
- API key 用浏览器 prompt() 获取，不硬编码
- 提供 mock 数据作为 API 不可用时的 fallback
