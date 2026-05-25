# @innate/ui 组件清单

## 基础组件（57 个）

### 表单控件（14 个）

| 组件 | 文件 | 说明 |
|------|------|------|
| Button | button.tsx | 按钮，支持 default/outline/ghost/destructive/secondary/link 变体，sm/default/lg/icon 尺寸 |
| ButtonGroup | button-group.tsx | 按钮组，水平排列多个按钮 |
| Input | input.tsx | 输入框 |
| InputGroup | input-group.tsx | 输入框组，支持前缀/后缀 |
| InputOTP | input-otp.tsx | OTP 验证码输入 |
| Textarea | textarea.tsx | 多行文本 |
| Select | select.tsx | 下拉选择（Radix） |
| Checkbox | checkbox.tsx | 复选框 |
| RadioGroup | radio-group.tsx | 单选组 |
| Switch | switch.tsx | 开关 |
| Slider | slider.tsx | 滑块 |
| Field | field.tsx | 表单字段包装器 |
| Label | label.tsx | 标签 |
| Form | form.tsx | React Hook Form 集成 |

### 布局组件（9 个）

| 组件 | 文件 | 说明 |
|------|------|------|
| Card | card.tsx | 卡片（Card/Header/Content/Footer/Description/Title） |
| Separator | separator.tsx | 分隔线 |
| ScrollArea | scroll-area.tsx | 滚动区域 |
| Resizable | resizable.tsx | 可调整大小面板 |
| AspectRatio | aspect-ratio.tsx | 宽高比容器 |
| Collapsible | collapsible.tsx | 折叠/展开 |
| Sidebar | sidebar.tsx | 侧边栏（完整系统：Provider/Content/Inset/Menu/Group/Trigger 等） |
| Container | — | 容器 |

### 导航组件（6 个）

| 组件 | 文件 | 说明 |
|------|------|------|
| Tabs | tabs.tsx | 标签页（Tabs/List/Trigger/Content） |
| Accordion | accordion.tsx | 手风琴 |
| Breadcrumb | breadcrumb.tsx | 面包屑导航 |
| NavigationMenu | navigation-menu.tsx | 导航菜单 |
| Menubar | menubar.tsx | 菜单栏 |
| Pagination | pagination.tsx | 分页 |

### 数据展示（9 个）

| 组件 | 文件 | 说明 |
|------|------|------|
| Table | table.tsx | 表格（Table/Header/Body/Row/Head/Cell） |
| Badge | badge.tsx | 标签，支持 default/secondary/destructive/outline 变体 |
| Avatar | avatar.tsx | 头像 |
| Progress | progress.tsx | 进度条 |
| Skeleton | skeleton.tsx | 骨架屏 |
| Chart | chart.tsx | Recharts 图表封装 |
| Spinner | spinner.tsx | 加载旋转 |
| Kbd | kbd.tsx | 键盘快捷键展示 |
| Item | item.tsx | 列表项 |

### 反馈组件（6 个）

| 组件 | 文件 | 说明 |
|------|------|------|
| Alert | alert.tsx | 提示框 |
| AlertDialog | alert-dialog.tsx | 确认对话框 |
| Toast | toast.tsx | 提示消息 |
| Sonner | sonner.tsx | Toast 通知（sonner 库） |
| Tooltip | tooltip.tsx | 工具提示 |
| HoverCard | hover-card.tsx | 悬浮卡片 |

### 覆盖层（6 个）

| 组件 | 文件 | 说明 |
|------|------|------|
| Dialog | dialog.tsx | 对话框 |
| Sheet | sheet.tsx | 侧滑面板 |
| Drawer | drawer.tsx | 抽屉（vaul） |
| Popover | popover.tsx | 气泡弹出 |
| DropdownMenu | dropdown-menu.tsx | 下拉菜单 |
| ContextMenu | context-menu.tsx | 右键菜单 |
| Command | command.tsx | 命令面板（cmdk） |

### 其他（4 个）

| 组件 | 文件 | 说明 |
|------|------|------|
| Calendar | calendar.tsx | 日历 |
| Carousel | carousel.tsx | 轮播 |
| Toggle | toggle.tsx | 切换按钮 |
| ToggleGroup | toggle-group.tsx | 切换按钮组 |
| Empty | empty.tsx | 空状态 |

### Hooks（2 个）

| Hook | 文件 | 说明 |
|------|------|------|
| useMobile | use-mobile.tsx | 移动端检测 |
| useToast | use-toast.ts | Toast 状态管理 |

---

## 业务区块组件

### Landing 区块（7 个）

| 组件 | Props | 说明 |
|------|-------|------|
| HeroSection | badge?, title, titleHighlight?, subtitle, primaryCta?, secondaryCta? | 首屏英雄区域 |
| FeaturesSection | title, subtitle?, features: Feature[] | 特性展示网格 |
| PricingSection | title, subtitle?, plans: PricingPlan[] | 价格方案卡片 |
| TestimonialsSection | title, subtitle?, testimonials: Testimonial[] | 用户评价 |
| FaqSection | title, subtitle?, items: FaqItem[] | FAQ 手风琴 |
| StatsSection | title, subtitle?, stats: Stat[] | 数字统计展示 |
| CTASection | title, description?, cta: { text, href } | 行动召唤 |

### Auth 区块（1 个）

| 组件 | 说明 |
|------|------|
| LoginForm | 登录表单（邮箱+密码） |

### Mail 区块（3 个）

| 组件 | 说明 |
|------|------|
| Inbox | 邮件收件箱主界面 |
| MailList | 邮件列表 |
| MailDisplay | 邮件内容展示 |

### Chat 区块（2 个）

| 组件 | 说明 |
|------|------|
| ChatInterface | 聊天界面主组件 |
| MessageList | 消息列表 |
