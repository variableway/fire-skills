# baoyu-design Skill 分析报告

> **GitHub 仓库：** https://github.com/JimLiu/baoyu-design
> **本地路径：** `content-creation/skills/baoyu-design/`
> **作者：** Jim Liu（宝玉）
> **许可协议：** MIT
> **派生自：** Anthropic 的 Claude Design（[claude.ai/design](https://claude.ai/design)）
> **报告日期：** 2026-06-16
> **分析对象版本：** HEAD = `96104cc Guard gen_pptx capture calls with per-call timeouts`

---

## 一、概述

`baoyu-design` 是一个把 Anthropic 旗下 `claude.ai/design` 的设计能力"反编译"成本地 Agent Skill 的开源项目。它的核心理念是：**把云端的设计工作流打包成纯 Markdown + 少量 JSX/JS 脚手架**，让任何具备文件读写能力的编码 Agent（Claude Code / Cursor / Codex 等）都能在本地完成 UI 设计、原型、线框、PPT、移动端原型等工作，产物以自包含 HTML 落到 `designs/<project>/` 下。

完整仓库结构：

```
baoyu-design/
├── README.md / README.zh-CN.md      # 双语文档
├── CHANGELOG.md                     # 25K+ 变更日志
├── package.json                     # 测试入口（私有）
├── assets/                          # README 用截图与流程图 SVG
├── .github/workflows/               # CI（占位）
└── skills/baoyu-design/
    ├── SKILL.md                     # 入口：编排整个流程
    ├── system-prompt.md             # 设计方法论与工艺标准（≈40K 字，事实来源）
    ├── references/{claude,cursor,codex}.md   # 三种 harness 的工具映射
    ├── built-in-skills/             # 33 个专项子技能（decks / mobile / figma / pptx / …）
    ├── starter-components/          # 10 个起步组件（设备外壳、画布、动画引擎…）
    └── agents/                      # CLI 工具 + 测试
        ├── import-design-system.mjs
        ├── import-figma.mjs         # Figma .fig 离线解码
        ├── compile-design-system.mjs
        ├── check-design-system.mjs
        ├── record-asset.mjs
        ├── build-preview.mjs
        ├── design-system-checker.md # 子 Agent 提示词
        ├── fork-verifier-agent.md
        ├── vendor/                  # react / babel / fflate / fig-materialize
        ├── gen-pptx/                # Playwright + PptxGenJS 本地 PPTX 导出
        └── tests/                   # 9 个测试文件
```

---

## 二、好的地方（优点）

### 2.1 架构层面

1. **Harness-agnostic 的分层设计**
   `SKILL.md`（编排） → `system-prompt.md`（方法论，与环境无关） → `references/<harness>.md`（工具映射）。同一套方法论被三种环境共用，工艺规则不需要为每个 Agent 重写。

2. **"Single source of truth" 原则执行到位**
   - 工艺规则只在 `system-prompt.md` 写一遍。
   - 工具调用只在每份 `references/<harness>.md` 写一遍。
   - 子技能只在 `built-in-skills/<name>.md` 写一遍。
   这种拆分让维护成本明显低于"每改一处工艺，要同步 4 份文档"的方案。

3. **模块化子技能体系**
   `built-in-skills/` 下 33 个 `.md` 文件覆盖了所有常见场景：hi-fi / wireframe / interactive-prototype / mobile-prototype / make-a-deck / speaker-notes / design-system-authoring / use-design-system / import-from-figma / import-from-github / import-from-html / export-as-pptx-editable / export-as-pptx-screenshots / save-as-standalone-html / save-as-pdf / send-to-figma / send-to-canva / handoff-to-claude-code / gemini-image / claude-api-in-prototypes / read-pdf / sound-effects / animated-video / something-cool / tweaks-protocol / low-level-tweaks-api / make-tweakable 等。SKILL.md 像一个"路由器"，按用户意图只 `Read` 必要的子技能，**不一次性吞掉所有 context**。

4. **产物即代码**
   所有设计稿都是 `designs/<project>/<file>.html`，可纳入版本控制、fork、导出、CI 校验。彻底摆脱云端锁定。

### 2.2 工程实现

5. **零构建/零运行时（核心路径）**
   仅靠 `<script src="https://unpkg.com/.../babel.min.js">` 在浏览器里即时转译 JSX；不需要 webpack / vite / next 等构建链。React、Babel 都**带 SRI 哈希 + 固定版本**（`react@18.3.1` / `@babel/standalone@7.29.0`），供应链可控。

6. **PPTX 导出思路极其实用**
   `gen-pptx` 的核心是"**不解析 HTML，而是在真实浏览器里渲染它，再把渲染结果翻译成 PowerPoint**"：
   - 用 Playwright 起无头 Chromium，加载 `http://...` 上的 deck；
   - 注入 capture bundle 暴露 `window.__genpptx`；
   - 通过 `page.evaluate()` 让浏览器完成布局/计算样式/字体度量/图片解码；
   - 序列化为 `{tag, rect, style, children}` 的 JSON 树；
   - Node 端 `renderNodeToPptx` 翻译为 PptxGenJS 原生对象（`addShape`/`addText`/`addImage`）；
   - 坐标换算 `px ÷ 96 = in`、字号 `px × 0.75 = pt`；
   - 最后 djb2 哈希校验相邻页、核对尺寸与 speaker-notes 数量。
   这套"渲染-翻译-校验"链路既保证可编辑模式保真度（文字真的能改），又避开"HTML→PPTX"转换器普遍面临的 CSS 兼容地雷。

7. **离线 Figma 解码**
   内置 `fig-materialize.mjs` + `fflate.mjs`，把 `.fig` 当 zip 解压解析，**完全不依赖 Figma 账号、API token 或 MCP**。28 个组件 / 400+ token 一次导入即可成为可复用的设计系统。

8. **设计系统作为"绑定契约"而非建议**
   `_d_meta.json` 记录每个项目绑定的设计系统，导入时同步 `_ds/<slug>/_ds_prompt.md`。系统 prompt 被明确要求作为**视觉契约**严格执行："the agent won't invent off-system colors or styles"。同时支持多系统并存，primary 系统拥有 token 冲突仲裁权。

### 2.3 工程治理

9. **测试覆盖**
   `agents/tests/` 下 9 个 `.test.mjs` 文件，覆盖 asset-store、ds-core、ds-prompt、import-design-system、import-figma、check-design-system、compile-design-system、build-preview 等关键节点。`package.json` 暴露 `npm test` 入口。

10. **清晰的双语文档**
    README 同时提供英文/简体中文两版，顶部用 badges 标明 License、最佳模型（Opus 4.8）、支持的 harness。截图矩阵展示"同一 prompt 在 Cursor / Codex / Claude / Claude Design 四种环境下的输出"。

11. **细节友好的人机约定**
    - 用 `[data-screen-label]` 标注屏幕/幻灯片，便于"指哪改哪"。
    - 明确"slide 5 = 第 5 张（label 05），不是 array[4]"，对齐人类直觉。
    - 持久化视频播放位置到 localStorage，方便反复预览。
    - 文档里写"never write `const styles = { ... }`"——把容易踩的坑提前喊出来。

12. **MVP 友好**
    起步组件（`starter-components/`）覆盖 iOS / Android / macOS / 浏览器外壳、deck-stage、design-canvas、animation engine、tweaks-panel、image-slot，让 Agent 不必从零手搓基础件。

13. **可验收的"something-cool" 子技能**
    默认走 hi-fi + interactive-prototype；当用户明确说"surprise me"时，路由到 `something-cool.md`，避免默认路径误入歧途。

14. **诚实的免责说明**
    README 末尾主动声明：这是社区独立项目，**不隶属于 Anthropic**，仅是对 `claude.ai/design` 的重新打包。这种透明度对长尾信任很关键。

---

## 三、不好的地方（缺点 / 风险）

### 3.1 使用门槛与依赖

1. **重度依赖单一模型**
   README 直接写"Best with Opus 4.8"。在能力较弱的模型上，40K 字的 `system-prompt.md` 很容易出现指令遗忘或工艺妥协，质量断崖式下降。

2. **PPT 路径的"零安装"叙事不成立**
   README 强调"no build step, no runtime"，但要用 PPTX 导出必须：
   ```
   cd skills/baoyu-design/agents/gen-pptx
   npm install
   npx playwright install chromium   # ~150 MB
   npm run build
   ```
   任何一步失败都会卡住首次使用，且错误信息对非前端用户不友好。

3. **CDN 单点**
   自包含 HTML 仍通过 `unpkg.com` 拉 React/Babel。虽配了 SRI，但离线 / 弱网 / unpkg 故障会直接让原型空白——与"自包含 HTML 拷贝带走"的承诺有冲突。

4. **Magic port 4311**
   `python3 -m http.server 4311 --directory designs` 是文档唯一写法。端口被占时 Agent 没有标准 fallback，会让用户感到困惑。

### 3.2 设计陷阱（写给 Agent 的脚手架）

5. **全局 `const styles` 命名陷阱**
   system-prompt.md 里有 CRITICAL 标记，要求每个组件的 styles 对象必须**独有命名**（如 `terminalStyles`），否则多组件引入时会撞名崩溃。这条规则既重要又脆弱，全靠 Agent 自觉。

6. **多 Babel 文件不共享作用域**
   每个 `<script type="text/babel">` 各自独立作用域，跨文件共享必须显式 `window.X = X`。容易踩坑，且调试栈不直观。

7. **SKILL.md 入口依赖复杂**
   `SKILL.md` 描述看起来是一份 Markdown，实际依赖 `agents/import-design-system.mjs`、`compile-design-system.mjs`、`build-preview.mjs` 等脚本以及三个 `references/<harness>.md` 才能跑通完整流程。Skill 的实际"代码量"远超 SKILL.md 自身。

### 3.3 文档与多语言

8. **i18n 仅覆盖 README**
   双语只是 README。`built-in-skills/*.md`、`system-prompt.md`、`references/*.md` 全部英文。中文 README 末尾说"全套文档齐备"，但子文档并未翻译。

9. **系统 prompt 里有大量 web 残留术语**
   `questions_v2` / `gen_pptx` / `done` / `fork_verifier_agent` 等是上游 claude.ai 工具名。每份 `references/<harness>.md` 都得做一次映射表。这种"翻译层"既占 token 又增加心智负担。

10. **CHANGELOG.md 25K 字 + 缺乏稳定承诺**
    高速迭代但没有 semver 标签，`package.json` 也只是个壳。无稳定版本线 → 用户难以锁版。

### 3.4 治理与安全

11. **`designs/` 被默认 .gitignore 掉**
    ```
    # .gitignore 末尾
    designs/
    ```
    与 README 里"Everything is yours / version, fork, export, ship"形成强烈反差。用户必须手动改 `.gitignore` 才能把成果纳入版本控制，否则 `npx skills add` 之后他们的工作就被默默屏蔽了。

12. **`import-from-github` 没有显式安全说明**
    该子技能会用 `gh api` 浏览任意仓库 + sparse-checkout 任意路径，但文档没有给出"仅限公开仓库、避免私有敏感数据、不要写入项目目录"的明确警告。如果 Agent 拿到的 URL 是私有 repo，可能造成凭证/源码意外落地。

13. **Figma `.fig` 解码器的合法性灰色**
    `.fig` 是 Figma 专有格式，自带解码器是否触及 DMCA / 逆向工程边界，仓库没有任何说明（虽然这是社区普遍做法）。

14. **没有任何安全/审计 Hook**
    仓库无 `.claude/settings.json`、无 SCAN 提示词、无扫描 secrets 的策略。skill 大量使用 WebFetch / Bash / Write，理论上能执行任意命令，却没有 audit trail。

### 3.5 其他可改进点

15. **上下文预算高**
    `system-prompt.md` ≈ 40K 字 + 3 份 references ≈ 10K 字 + 必要的子技能 ≈ 5K 字。开启一次设计任务就吃掉 ~55K token，再加用户 prompt 与产物生成，频繁长会话容易触顶。

16. **`package.json` 几乎是占位**
    只暴露一个 `test` 脚本。没有 `bin`、没有 `lint`、没有 `format`，安装到本机后没有可用 CLI。

17. **截图没有 prompt/模型版本元数据**
    `assets/screenshots/` 的 README 截图矩阵很具说服力，但每张图背后用的 prompt、模型、温度都没有 metadata，未来无法复现。

18. **README 缺少 social proof / 兼容性矩阵**
    没有 GitHub stars/forks badges；没有"哪些 harness 已验证 / 哪些 harness 已知有问题" 的明确矩阵。

19. **`description` 字段被刻意裁剪**
    最近一次提交"Trim skill description under 1024 chars"——description 是 Agent 是否激活 skill 的关键字段。1024 字限制会迫使 SKILL frontmatter 反复优化措辞，潜在影响命中。

20. **`content-creation/skills/baoyu-design/skills/baoyu-design/` 嵌套**
    仓库里两层 `skills/baoyu-design/` 嵌套，外层是 npm 包元数据，内层才是真正的 skill。install 后链接路径是 `skills/baoyu-design/SKILL.md`，对阅读与 FAQ 不友好。

---

## 四、改进建议

### 4.1 降低门槛
1. **提供 "lite mode"**：默认不安装 PPTX/Figma 子能力，使核心 hi-fi + interactive-prototype 路径**零 npm 依赖、零 Playwright**，与 README 的"zero install"叙事对齐。
2. **本地化 React/Babel**：把 `vendor/react-18.3.1.production.min.js`、`react-dom`、`babel.min.js` 复制到 `starter-components/vendor/`，让自包含 HTML 在断网下也能渲染。
3. **加 `doctor.mjs` CLI**：检查 Node 版本、端口 4311、Playwright 是否就绪、`gh auth status`、CDN 可达性，给出明确修复指引。
4. **`npx skills add` 之后自动启动**：`designs/` 一次性 demo 设计（如"Sample Landing Page"），让新用户 30 秒看到成品。

### 4.2 解决工程陷阱
5. **把 `styles` 命名陷阱做成默认机制**：提供 `defineStyles('Terminal', {...})` helper，或在文档里强制用 `<style>` block + `className`（已有强推，但仍非默认）。
6. **自动 Babel 文件作用域共享**：把"每个文件末尾 `window.X = X`"模式封装为 Babel 插件，或直接改用 esm.sh + `import`。
7. **提供端口自动协商**：检测 4311 被占时自动 +1 并通过子 Agent 输出最终 URL。

### 4.3 文档与多语言
8. **中英子文档双轨**：至少给 `system-prompt.md` 和最常用的 5 个 built-in-skill（hi-fi、interactive-prototype、make-a-deck、use-design-system、import-from-figma）出中文版。
9. **公开版本策略**：在 README 加 "Stability & Releases" 段，semver → CHANGELOG 节选，给企业用户锁版的依据。
10. **新增 `references/` 兼容性矩阵**：在 README 中列出 harness × 已验证功能的勾叉矩阵，避免"声称支持 70+ agent 实际只有 3 个一等公民"的认知错位。

### 4.4 治理与安全
11. **`designs/` 改为 opt-out 而不是 opt-in**：默认不要 `.gitignore designs/`，或在 README 给出"如果你想把成果纳入版本控制，删除 .gitignore 这一行"的明确指引。
12. **加 `import-from-github` 安全条款**：显式声明"仅访问公开 repo / sparse-checkout 到 tmpdir / 不写入项目目录 / 不持久化 token"。
13. **加 scanning-for-secrets / 不写 .env 类文件的硬约束**：在 `system-prompt.md` 加一节 Safety，把"不要尝试读取 .env / .ssh / credentials"显式写进去。
14. **加 npm scripts `lint`、`format`、`build:gen-pptx`**：把分散在文档里的手工命令全部脚本化。

### 4.5 体验增强
15. **把 `system-prompt.md` 拆分压缩**：把"output creation guidelines"中正交的小节（颜色、emoji、字体、文件命名……）抽到一份小型的 `craft-rules.md`，并允许 Agent 按任务只载入相关部分，能省 20~30K token。
16. **`something-cool` 加上"展示既有 designs/"开关**：让用户能基于自己之前的成果做 remix，而不是每次都从 0 生成。
17. **为 `_d_meta.json` 写一份 JSON Schema**：放在 `docs/d-meta.schema.json`，让外部工具能稳定消费设计系统绑定记录。

### 4.6 工程实践
18. **CI 增加 reference-doc lint**：检查 `references/<harness>.md` 中提到的 MCP / 工具是否真的存在，避免文档漂移。
19. **加 `examples/` 工作示例**：把 README 中提到的 Reader Mac App 真正提交为 `examples/reader-mac-app/`，新用户 clone 即跑。
20. **截图加 frontmatter 元数据**：`<prompt>...</prompt> <model>opus-4.8</model> <seed>...</seed>`，可机器读取。

---

## 五、其他问题（容易被忽略的小细节）

1. **`description` 字段 1024 字符限制**与日俱增。最近的 commit "Trim skill description under 1024 chars" 表明这是一个长期摩擦点。建议把常用关键词放在最前面（Agent 匹配是按 description 的）。

2. **`git remote` 指向 GitHub，但 README 没有 social proof**（star / fork badges）。在 npm 时代，缺乏社交证据会拉低信任。

3. **`designs/` 目录无 git 模板**——用户首次 `git status` 看到的是完全陌生的目录，里面什么都没有，第一印象不够友好。

4. **CI workflows/ 几乎是空的**：仓库目前没有自动化测试运行。`npm test` 要靠用户本地执行。

5. **缺少 CONTRIBUTING.md / CODE_OF_CONDUCT.md / 模板 PR 描述**。对希望贡献的开发者门槛偏高。

6. **依赖 `unpkg.com` + `fonts.googleapis.com` 的外部资源**：
   - `system-prompt.md` 里要求 deck 用 Google Fonts；
   - 设计系统导入可能拉第三方字体；
   - 在 GFW / 企业代理下，整套体验会显著退化。建议在 README 加一个"在中国大陆使用"的简短提示。

7. **`starter-components/deck-stage.js`** 是普通 JS 而非 JSX，且 patch 通过 markdown（`deck-stage-patch.md`）维护——风格不统一，reviewer 容易误判。

8. **README 没有 `Acknowledgements`**：除了末尾对 Anthropic 的声明，没有提到 `npx skills`（Vercel Labs）、PptxGenJS、Playwright、fflate 等关键依赖。这对法律/合规审查不利。

9. **未提供离线包**：没有 release artifacts（如 `baoyu-design-v0.x.zip`），企业内网用户只能 `git clone`。

10. **没有 `examples/` 子目录**，新人无法在 5 分钟内跑出一个真实工作。

---

## 六、结论

`baoyu-design` 是一个**思路极其清晰、架构层面优雅、文档/测试/CLI 都做到中等偏上**的本地化设计 Skill。它最有价值的部分是把"工艺规则"与"harness 工具"完全分离，让一份核心方法论同时支撑 Claude Code / Cursor / Codex 三个生态；它的 `gen-pptx` 与 `import-figma` 是少有的真正解决"用 LLM 做设计"痛点的工程实现。

但它也面临三类典型问题：

- **门槛问题**：PPT/Figma 子能力拉高了首次使用成本，与"零安装"的承诺不匹配。
- **本地化完整性**：CDN 字体、CDN React、断网时 `gen-pptx` 的 http server，破坏"自包含 HTML 拷贝带走"叙事。
- **治理透明度**：`designs/` 被默认 `.gitignore`、没有 safety hook、`description` 被刻意裁剪、CHANGELOG 25K 但没有 semver。

如果团队准备把这种 skill 模板批量复制到 `content-creation/skills/` 下其他技能，作者建议优先采纳以下 4 项改进，能以最少投入获得最大稳定性：

1. **Lite mode + 零 npm 依赖的核心路径**（建议 4.1.1 / 4.1.2）。
2. **`doctor.mjs` 健康检查 CLI**（建议 4.1.3）。
3. **`designs/` 改为 opt-out + 显式 safety 条款**（建议 4.4.1 / 4.4.2）。
4. **`system-prompt.md` 拆分压缩 + `_d_meta.json` JSON Schema**（建议 4.5.1 / 4.5.2）。

---

## 附录：相关链接

- **GitHub：** https://github.com/JimLiu/baoyu-design
- **本地路径：** `content-creation/skills/baoyu-design/`
- **Claude Design（上游）：** https://claude.ai/design
- **安装方式：** `npx skills add JimLiu/baoyu-design`
- **关键文档：**
  - `skills/baoyu-design/SKILL.md` — 入口
  - `skills/baoyu-design/system-prompt.md` — 方法论事实来源
  - `skills/baoyu-design/references/{claude,cursor,codex}.md` — harness 工具映射
  - `skills/baoyu-design/built-in-skills/` — 33 个子技能
  - `skills/baoyu-design/agents/gen-pptx/` — 本地 PPTX 导出
  - `skills/baoyu-design/agents/import-figma.mjs` — Figma `.fig` 离线解码
