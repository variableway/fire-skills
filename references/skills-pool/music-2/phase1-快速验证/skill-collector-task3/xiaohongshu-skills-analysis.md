# 小红书维护/运营 Skills 分析报告 - Task 4

## 数据概览

| 指标 | 数值 |
|------|------|
| 总计 Skills | 30个 |
| GitHub开源项目 | 15个 |
| ClawHub Skills | 14个 |
| 其他平台 | 1个 (skills.rest) |
| 小红书自动发帖Top 10 | 10个 (见下表) |

---

## Top 10 小红书自动发帖 GitHub 项目

| 排名 | 项目 | Stars | 语言 | 核心能力 |
|------|------|-------|------|----------|
| 1 | [xiaohongshu-mcp](https://github.com/xpzouying/xiaohongshu-mcp) | 9700+ | Go | 最成熟MCP工具，登录/发帖/评论/搜索/推荐流 |
| 2 | [RedBookC](https://github.com/brettinhere/redbookc) | N/A | Node.js | AI全自动Agent，10分钟抓取→Claude生成→Playwright发帖 |
| 3 | [xiaohongshu (AI Web)](https://github.com/YYH211/xiaohongshu) | N/A | Python/FastAPI | FastAPI+MCP，4步自动生成发布，支持批量 |
| 4 | [xhs-mcp](https://github.com/FrancoSbaffi/xhs-mcp) | N/A | Python | Playwright浏览器自动化，Session持久化 |
| 5 | [openclaw-xhs-workflow](https://github.com/magichanks/openclaw-xhs-workflow) | N/A | Python | OpenClaw插件，research→copy→image→review→publisher |
| 6 | [Autoxhs](https://github.com/Gikiman/Autoxhs) | N/A | Python/Streamlit | OpenAI API，主题+图片生成，Streamlit界面 |
| 7 | [xiaohongshu.publish](https://github.com/wsmshcnfdc/xiaohongshu.publish) | N/A | Python | Firefox WebDriver，Cookie/验证码登录，图文视频 |
| 8 | [xiaohongshu-skill](https://github.com/ibreez3/xiaohongshu-skill) | N/A | JavaScript | 基于xiaohongshu-mcp的Agent Skill，OpenClaw/Claude/Cursor |
| 9 | [xiaohongshu-longpost-auto](https://github.com/openclaw/skills/tree/main/skills/openlark/xiaohongshu-longpost-auto) | N/A | Markdown | OpenClaw官方Skill，长文自动发布，AI生成图片+标签 |
| 10 | [xiaohongshu-recruiter](https://skills.rest/skill/xiaohongshu-recruiter) | N/A | Node.js/Python | 自动发布AI招聘内容，生成极客风格视觉图 |

---

## 技术路线分类

### 1. MCP协议路线 (推荐)
- **核心项目**: xiaohongshu-mcp (Go), xhs-mcp (Python)
- **原理**: 通过MCP (Model Context Protocol) 将小红书操作标准化为API接口
- **优势**: 与Claude/Cursor/OpenClaw等AI工具无缝集成，一句话完成操作
- **工具接口**:
  - `check_login_status` - 检查登录状态
  - `publish_content` - 发布图文内容
  - `publish_with_video` - 发布视频
  - `search_feeds` - 搜索内容
  - `list_feeds` - 抓取首页推荐
  - `get_feed_detail` - 获取帖子详情
  - `post_comment_to_feed` - 自动评论
  - `user_profile` - 获取用户信息

### 2. 浏览器自动化路线
- **核心项目**: RedBookC, xiaohongshu.publish, FrancoSbaffi/xhs-mcp
- **原理**: Playwright/Puppeteer/WebDriver 控制真实浏览器操作
- **优势**: 最接近真人操作，反检测能力强
- **注意**: 需要保持浏览器环境一致，Cookie管理关键

### 3. AI Agent全自动化路线
- **核心项目**: RedBookC, openclaw-xhs-workflow
- **原理**: AI自动抓取→生成文案→配图→发布
- **优势**: 完全无人值守，定时自动运行
- **风险**: 需控制频率防封号，内容质量需审核

### 4. 纯内容生成路线
- **核心项目**: Autoxhs, ClawHub内容创作类Skill
- **原理**: 只负责生成文案/标题/封面，不直接发布
- **优势**: 安全无风险，适合人工审核后发布

---

## ClawHub 小红书 Skills 分类统计

| 分类 | 数量 | 代表项目 |
|------|------|----------|
| 综合运营 | 23个 | xiaohongshu-mcp (18,265下载) |
| 内容发布自动化 | 26个 | xiaohongshu-publisher (2,477下载) |
| 内容创作辅助 | 27个 | xhs-note-creator (1,659下载) |
| 图片与卡片生成 | 14个 | baoyu-xhs-images (386下载) |
| 数据采集与分析 | 18个 | xiaohongshutools (3,876下载) |
| 互动管理与评论 | 5个 | xiaohongshu-comment (133下载) |
| 视频下载与分析 | 4个 | xiaohongshu-downloader (395下载) |
| MCP/CLI/登录 | 19个 | xiaohongshu-mcp-skill (1,053下载) |

**总计**: 136个专项skills + 55个多平台skills = **191个**

---

## 快速入门推荐

### 方案A: 最成熟的MCP方案 (推荐)
```bash
# 1. 安装xiaohongshu-mcp
git clone https://github.com/xpzouying/xiaohongshu-mcp.git
cd xiaohongshu-mcp
npm start

# 2. 在Claude/Cursor中配置MCP
# 3. 说一句话即可发帖: "帮我发一篇关于AI工具的小红书笔记"
```

### 方案B: 全自动AI Agent
```bash
# 1. 安装RedBookC
git clone https://github.com/brettinhere/redbookc.git
cd redbookc
npm install
npx playwright install chromium

# 2. 配置.env (CLAUDE_API_KEY等)
# 3. 启动: 每10分钟自动抓取→生成→发布
```

### 方案C: 批量生成+手动发布
```bash
# 1. 安装Autoxhs
git clone https://github.com/Gikiman/Autoxhs.git
cd Autoxhs
pip install -r requirements.txt
streamlit run app.py

# 2. 输入主题，AI生成文案和图片
# 3. 人工审核后手动发布
```

---

## 风险提示

1. **封号风险**: 小红书反作弊机制非常严格
   - 建议每日评论不超过30条
   - 避免短时间内高频操作
   - 使用真实浏览器环境比Cookie注入更安全

2. **内容合规**: AI生成内容需符合社区规范
   - 避免批量刷数据
   - 确保内容原创性声明
   - 合理使用，提高运营效率而非违规操作

3. **Cookie管理**: 不要把登录凭证提交到GitHub
   - `.gitignore` 中排除 `session/auth.json`
   - 使用环境变量管理API Key
