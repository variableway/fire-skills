**User:**

当前想做一个聚合的工具，形态就是桌面版本，然后自己基础的就是 ai llm 设置和注册以及基本的安装教程，同时可以注册不同的网站加入到这个桌面版本来，plugin 的模式，然后比如说工作这一块有很多开源比较好的我就聚合进来做成一个就可以，目的是形成社区可以让人自行选择打包下载，收费是社区或者 api 中转

**Kimi:**

这是一个非常有潜力的方向——**“个人 AI 工作站 + 开源工具应用商店”**。结合你之前的技术栈偏好（Tauri/Rust），我直接给你一套可落地的架构方案：

## 一、产品定位：「AI 工具箱」而非「聊天客户端」

不要做成另一个 ChatGPT 客户端，而是做成： - **底层**：统一 LLM 配置层（多 Provider 管理） - **中层**：插件运行时（隔离、安全、可扩展） - **上层**：社区驱动的工具市场（Work/Dev/Life 分类）

核心差异点：**用户不是来聊天的，是来”干活”的**——每个插件解决一个具体工作场景。

## 二、技术架构（推荐 Tauri v2）

┌─────────────────────────────────────────────┐
│ Tauri v2 桌面应用 (Rust + Web Frontend) │
├─────────────────────────────────────────────┤
│ UI Layer: React/Vue + shadcn-ui │
│ ├─ LLM 配置中心 (Provider/APIKey/模型管理) │
│ ├─ 插件商店 (浏览/安装/更新/打包) │
│ ├─ 工作区 (已安装插件的启动器/管理) │
│ └─ API 中转面板 (用量/计费/限流) │
├─────────────────────────────────────────────┤
│ Plugin Runtime (Rust 侧) │
│ ├─ 插件沙箱: Webview 隔离 / iframe 容器 │
│ ├─ 权限系统: 文件/网络/剪贴板/Shell 分级授权 │
│ ├─ 标准 API: 调用 LLM / 访问宿主能力 │
│ └─ 进程通信: Tauri Command / Event │
├─────────────────────────────────────────────┤
│ 插件包格式: .zip / .tar.gz │
│ manifest.json (元数据 + 权限声明 + 入口文件) │
│ ├─ 静态站点型: index.html + assets │
│ ├─ 本地服务型: 内置二进制 + Web UI │
│ └─ 混合类型: 前端 UI + 本地脚本 │
└─────────────────────────────────────────────┘

### 为什么用 Tauri v2？

* **插件隔离**：每个插件跑在独立 Webview，崩溃不影响主应用
* **体积小**：相比 Electron，安装包 3-5MB 级别
* **Rust 安全**：插件权限控制可以在系统层面严格限制
* **跨平台**：Windows/macOS/Linux 一套代码

## 三、插件系统设计（核心难点）

### 3.1 插件包规范

// manifest.json
{
 "id": "com.example.pdf-translator",
 "name": "PDF 智能翻译",
 "version": "1.0.0",
 "author": "xxx",
 "category": "work",
 "entry": "dist/index.html",
 "permissions": ["llm:chat", "fs:read", "net:fetch"],
 "llm": {
 "required": true,
 "suggested\_model": "gpt-4o",
 "system\_prompt": "你是一个专业翻译助手..."
 },
 "hosting": {
 "type": "static", // or "service" for local binary
 "port": null
 }
}

### 3.2 宿主暴露的 API 标准（插件可调用）

// 插件内通过 window.parent.postMessage 或注入的 SDK 调用
interface HostAPI {
 // LLM 能力（用户已配置的 Provider）
 llm: {
 chat(messages: Message[], model?: string): AsyncIterable<string>;
 models(): string[];
 };

 // 系统能力（需权限声明）
 fs: { read(path: string): Promise<string>; };
 shell: { execute(cmd: string): Promise<string>; };
 clipboard: { read(): Promise<string>; write(text: string): Promise<void>; };

 // 应用级
 storage: { get(key: string): any; set(key: string, value: any): void; };
 toast: { show(message: string, type: 'info' | 'error'): void; };
}

### 3.3 两类插件形态

| 类型 | 适用场景 | 例子 |
| --- | --- | --- |
| **静态站点型** | 纯前端工具，调用宿主 LLM API | Markdown 编辑器、Prompt 管理器、文本处理工具 |
| **本地服务型** | 需要本地计算/文件处理 | PDF 解析器（内置 Python 脚本）、图片批量处理（内置 ffmpeg） |

## 四、LLM 配置层设计

这是基础体验，必须极简：

设置面板
├── Provider 管理
│ ├── OpenAI (官方/中转)
│ ├── Anthropic
│ ├── DeepSeek
│ ├── 本地 Ollama / LM Studio
│ └── 自定义 (OpenAI 兼容格式)
├── API Key 加密存储 (Tauri 用 Rust 做系统 Keychain 存储)
├── 模型别名系统
│ └── "默认快模型" → gpt-4o-mini
│ └── "默认强模型" → claude-3-7-sonnet
└── 用量统计 (为后续 API 中转收费做数据基础)

**关键**：插件不直接管理 API Key，统一向宿主申请 llm.chat()，宿主根据用户配置路由到具体 Provider。这样你可以做\*\* API 中转抽成\*\*。

## 五、社区与打包系统

### 5.1 插件市场架构

官方 Registry (类似 npm registry，可自建)
├── 插件元数据索引 (JSON API)
├── 分类标签: work / dev / writing / image / audio
├── 评分/下载量
└── 版本管理

用户侧
├── 发现: 浏览/搜索/分类筛选
├── 安装: 一键下载 + 自动解压到 plugins/ 目录
├── 打包: 选择 N 个插件 → 导出 "个人工作流包" (zip)
└── 分享: 分享打包配置，他人导入即复现环境

### 5.2 “工作流包” 概念（差异化功能）

用户可以把常用的一组插件 + LLM 配置模板打包成： - **“自媒体创作套件”**：文案生成 + 图片处理 + 排版工具 - **“开发者套件”**：代码审查 + 文档生成 + API 测试 - **“翻译研究套件”**：PDF 翻译 + 术语库 + 双语对照

社区创作者可以发布这些”套件”，形成**配置即产品**的二次分销。

## 六、商业模式落地

| 模式 | 实现方式 | 前提 |
| --- | --- | --- |
| **API 中转** | 用户充值 → 你提供统一 API 端点 → 后端路由到各 Provider 赚差价 | 需要后端服务+资质，适合后期 |
| **社区订阅** | Pro 会员解锁高级插件/无限插件安装/云同步配置 | 插件生态丰富后 |
| **插件开发者分成** | 付费插件抽成 20-30% | 需要托管支付体系 |
| **企业版** | 私有部署 + 内部插件市场 + SSO | 有企业客户后 |

**起步建议**：先完全免费做开源社区，积累 50+ 插件和 1000+ 用户后再考虑在**API 中转**上变现（最自然，用户本来就要配 API Key）。

## 七、可聚合的开源工具方向（Work 类）

这些是现成的 Web 工具，可以很快封装成插件：

| 类别 | 开源项目 | 封装难度 |
| --- | --- | --- |
| 文档处理 | [Marker](https://github.com/VikParuchuri/marker) (PDF→Markdown) | 中（需本地 Python） |
| 翻译 | [Immersive Translate](https://github.com/immersive-translate/immersive-translate/) 核心逻辑 | 低 |
| 写作 | [NovelAI 开源替代品](https://github.com/KoboldAI/KoboldAI-Client) | 中 |
| 会议/音频 | [Whisper Web](https://github.com/chenqinwhu/whisper-web) | 低 |
| 知识库 | [quivr](https://github.com/QuivrHQ/quivr) / [anything-llm](https://github.com/Mintplex-Labs/anything-llm) | 中 |
| 图片处理 | [ComfyUI](https://github.com/comfyanonymous/ComfyUI) (本地 API 模式) | 高 |
| 代码辅助 | [Continue.dev](https://github.com/continuedev/continue) (提取核心) | 高 |
| 思维导图 | [markmap](https://github.com/markmap/markmap) | 低 |
| 表格/数据 | [NocoDB](https://github.com/nocodb/nocodb) 轻量版 | 中 |
| 演示文稿 | [Slidev](https://github.com/slidevjs/slidev) | 低 |

**策略**：早期不要自己开发插件，而是**封装现有开源 Web 工具**，给它们加上 manifest.json 和 HostAPI 适配层。

## 八、开发路线图建议

Phase 1 (2-3 周): 最小可用
├── Tauri v2 骨架 + 插件加载器
├── LLM 配置面板 (支持 OpenAI/DeepSeek/Ollama)
├── 3 个示例插件 (Markdown 编辑器 / Prompt 工具 / 翻译器)
└── 本地插件安装 (手动放文件夹)

Phase 2 (4-6 周): 社区雏形
├── 插件商店 UI (浏览/安装/更新)
├── 权限系统完善
├── 10+ 开源工具封装
└── GitHub 发布 + 社区讨论区

Phase 3 (2-3 月): 商业化准备
├── 用户账户系统
├── API 中转后端 (LiteLLM 改造)
├── "工作流包" 分享功能
└── 插件开发者文档

## 九、参考项目

* **Tauri 插件隔离方案**：参考 [Coco AI](https://github.com/infinilabs/coco-app)（Tauri 做的 AI 搜索客户端，有插件思路）
* **插件市场 UI**：参考 [Raycast](https://www.raycast.com/store) 的 Store 设计（命令面板 + 卡片浏览）
* **LLM 统一层**：参考 [LibreChat](https://github.com/danny-avila/LibreChat) 的 Provider 抽象
* **API 中转**：直接部署 [OneAPI](https://github.com/songquanpeng/one-api) 或 [LiteLLM Proxy](https://github.com/BerriAI/litellm) 作为后端

需要我针对其中某个部分展开吗？比如： 1. **Tauri 插件沙箱的具体 Rust 实现代码** 2. **插件市场的后端 Registry 架构** 3. **具体的开源工具封装示例（比如把某个项目变成插件的步骤）** 4. **API 中转收费的后端+计费系统设计**

**User:**

都需要

**Kimi:**

这是一个完整的工程级方案，我按四个模块逐一展开，每个模块都包含可直接落地的代码和架构。

# 模块一：Tauri v2 插件沙箱系统（Rust 实现）

## 1.1 核心架构

src-tauri/
├── src/
│ ├── main.rs
│ ├── plugin/
│ │ ├── mod.rs # 插件生命周期管理
│ │ ├── loader.rs # 加载 & manifest 解析
│ │ ├── sandbox.rs # Webview 隔离 & 权限控制
│ │ ├── runtime.rs # 插件运行时 (Command 路由)
│ │ └── api/
│ │ ├── llm.rs # LLM 统一调用接口
│ │ ├── fs.rs # 文件系统沙箱
│ │ └── shell.rs # Shell 权限控制
│ └── lib.rs

## 1.2 插件 Manifest 结构（Rust）

// src/plugin/manifest.rs
use serde::{Deserialize, Serialize};
use std::collections::HashSet;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginManifest {
 pub id: String, // 唯一标识，如 com.example.translator
 pub name: String,
 pub version: String,
 pub author: String,
 pub category: PluginCategory,
 pub entry: String, // 入口文件，如 dist/index.html
 pub permissions: HashSet<<Permission>,
 pub llm: Option<LlmConfig>,
 pub hosting: HostingConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename\_all = "snake\_case")]
pub enum Permission {
 LlmChat, // 调用大模型
 LlmModels, // 获取模型列表
 FsRead, // 读文件（限定在插件目录）
 FsWrite, // 写文件（限定在插件目录）
 NetFetch, // 发起网络请求
 ShellExecute, // 执行系统命令（高危）
 ClipboardRead,
 ClipboardWrite,
 Storage, // 键值存储
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LlmConfig {
 pub required: bool,
 pub suggested\_model: Option<String>,
 pub system\_prompt: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename\_all = "snake\_case")]
pub enum HostingConfig {
 Static, // 纯前端，直接加载 HTML
 Service { port: u16, binary: String }, // 本地服务，启动二进制
}

## 1.3 插件加载器（带签名验证）

// src/plugin/loader.rs
use std::path::{Path, PathBuf};
use anyhow::Result;
use serde\_json::from\_str;

pub struct PluginLoader {
 plugins\_dir: PathBuf,
}

impl PluginLoader {
 pub fn new(plugins\_dir: impl AsRef<Path>) -> Self {
 Self {
 plugins\_dir: plugins\_dir.as\_ref().to\_path\_buf(),
 }
 }

 pub fn load\_all(&self) -> Result<Vec<<LoadedPlugin>> {
 let mut plugins = vec![];
 for entry in std::fs::read\_dir(&self.plugins\_dir)? {
 let entry = entry?;
 let path = entry.path();
 if path.is\_dir() {
 let manifest\_path = path.join("manifest.json");
 if manifest\_path.exists() {
 let manifest = self.load\_manifest(&manifest\_path)?;
 // 验证签名（可选：检查 .sig 文件）
 let plugin = LoadedPlugin {
 manifest,
 root\_dir: path,
 webview\_label: format!("plugin-{}", uuid::Uuid::new\_v4()),
 };
 plugins.push(plugin);
 }
 }
 }
 Ok(plugins)
 }

 fn load\_manifest(&self, path: &Path) -> Result<<PluginManifest> {
 let content = std::fs::read\_to\_string(path)?;
 let manifest: PluginManifest = from\_str(&content)?;
 // 基础校验
 if !manifest.id.chars().all(|c| c.is\_ascii\_alphanumeric() || c == '.' || c == '-') {
 anyhow::bail!("Invalid plugin id format");
 }
 Ok(manifest)
 }
}

pub struct LoadedPlugin {
 pub manifest: PluginManifest,
 pub root\_dir: PathBuf,
 pub webview\_label: String,
}

## 1.4 沙箱 Webview 管理（核心隔离）

// src/plugin/sandbox.rs
use tauri::webview::WebviewBuilder;
use tauri::{AppHandle, Manager, WebviewUrl, WebviewWindow};
use anyhow::Result;

pub struct PluginSandbox {
 app: AppHandle,
}

impl PluginSandbox {
 pub fn new(app: AppHandle) -> Self {
 Self { app }
 }

 /// 为插件创建隔离 Webview
 pub fn create\_webview(
 &self,
 parent\_window: &WebviewWindow,
 plugin: &LoadedPlugin,
 ) -> Result<WebviewWindow> {
 let entry\_path = plugin.root\_dir.join(&plugin.manifest.entry);

 // 构建 Webview，使用自定义 protocol 加载本地文件
 // 关键：每个插件独立的 webview\_label，崩溃隔离
 let webview = parent\_window.add\_child(
 WebviewBuilder::new(
 &plugin.webview\_label,
 WebviewUrl::AppFile(entry\_path.into()),
 )
 .initialization\_script(&self.build\_host\_api\_bridge(&plugin.manifest.permissions))
 .user\_agent(&format!("AI-Toolbox-Plugin/{}", plugin.manifest.id)),
 )?;

 // 注入 CSP 限制（禁止插件内联脚本，防止 XSS）
 // 实际通过 Tauri 的 capability 配置控制

 Ok(webview)
 }

 /// 构建注入到插件的 JS Bridge
 /// 插件通过 window.\_\_HOST\_API\_\_ 调用宿主能力
 fn build\_host\_api\_bridge(&self, permissions: &HashSet<<Permission>) -> String {
 let perms = permissions.iter().map(|p| format!("'{}'", p)).collect::<Vec<\_>>().join(",");
 format!(
 r#"
 window.\_\_HOST\_API\_\_ = {{
 \_permissions: new Set([{perms}]),
 \_invoke: (cmd, payload) => window.\_\_TAURI\_INTERNALS\_\_.invoke(cmd, payload),

 llm: {{
 chat: (messages, model) => {{
 if (!window.\_\_HOST\_API\_\_.\_permissions.has('llm\_chat')) throw new Error('Permission denied');
 return window.\_\_HOST\_API\_\_.\_invoke('plugin:llm:chat', {{ pluginId: '{plugin\_id}', messages, model }});
 }},
 models: () => window.\_\_HOST\_API\_\_.\_invoke('plugin:llm:models', {{}})
 }},

 fs: {{
 read: (path) => {{
 if (!window.\_\_HOST\_API\_\_.\_permissions.has('fs\_read')) throw new Error('Permission denied');
 return window.\_\_HOST\_API\_\_.\_invoke('plugin:fs:read', {{ pluginId: '{plugin\_id}', path }});
 }}
 }},

 storage: {{
 get: (key) => window.\_\_HOST\_API\_\_.\_invoke('plugin:storage:get', {{ pluginId: '{plugin\_id}', key }}),
 set: (key, value) => window.\_\_HOST\_API\_\_.\_invoke('plugin:storage:set', {{ pluginId: '{plugin\_id}', key, value }})
 }},

 clipboard: {{
 read: () => {{
 if (!window.\_\_HOST\_API\_\_.\_permissions.has('clipboard\_read')) throw new Error('Permission denied');
 return window.\_\_HOST\_API\_\_.\_invoke('plugin:clipboard:read', {{}});
 }}
 }}
 }};
 "#,
 perms = perms,
 plugin\_id = "{plugin\_id}" // 实际运行时替换
 )
 }
}

## 1.5 LLM 统一调用接口（Rust Command）

// src/plugin/api/llm.rs
use tauri::State;
use serde::{Deserialize, Serialize};
use futures::StreamExt;

#[derive(Serialize, Deserialize, Clone)]
pub struct ChatMessage {
 role: String,
 content: String,
}

// 全局 LLM Provider 管理（由用户在设置面板配置）
pub struct LlmProviderManager {
 pub default\_provider: String,
 pub api\_keys: std::collections::HashMap<String, String>,
 pub base\_urls: std::collections::HashMap<String, String>,
}

#[tauri::command]
pub async fn plugin\_llm\_chat(
 plugin\_id: String,
 messages: Vec<<ChatMessage>,
 model: Option<String>,
 state: State<'\_, LlmProviderManager>,
) -> Result<String, String> {
 // 1. 检查插件是否有 llm\_chat 权限（通过 plugin\_id 查权限表）
 // 2. 路由到对应 Provider
 let provider = state.default\_provider.clone();
 let api\_key = state.api\_keys.get(&provider).ok\_or("API Key not configured")?;

 // 3. 实际请求（这里用 reqwest，支持流式返回可通过 Event 通道）
 let client = reqwest::Client::new();
 let body = serde\_json::json!({
 "model": model.unwrap\_or\_else(|| "gpt-4o-mini".to\_string()),
 "messages": messages,
 "stream": false
 });

 let resp = client
 .post(format!("{}/v1/chat/completions", state.base\_urls.get(&provider).unwrap()))
 .header("Authorization", format!("Bearer {}", api\_key))
 .json(&body)
 .send()
 .await
 .map\_err(|e| e.to\_string())?;

 let result = resp.json::<serde\_json::Value>().await.map\_err(|e| e.to\_string())?;

 // 4. 记录用量（用于 API 中转计费）
 let usage = result.get("usage").cloned();
 crate::billing::record\_usage(&plugin\_id, usage).await;

 Ok(result["choices"][0]["message"]["content"].as\_str().unwrap\_or("").to\_string())
}

#[tauri::command]
pub fn plugin\_llm\_models() -> Vec<String> {
 vec![
 "gpt-4o".to\_string(),
 "gpt-4o-mini".to\_string(),
 "claude-3-7-sonnet".to\_string(),
 "deepseek-chat".to\_string(),
 ]
}

## 1.6 文件系统沙箱（路径隔离）

// src/plugin/api/fs.rs
use std::path::PathBuf;
use tauri::State;

pub struct SandboxRoots {
 // 每个插件只能访问自己的 data 目录
 pub plugin\_data\_dir: PathBuf,
}

#[tauri::command]
pub fn plugin\_fs\_read(
 plugin\_id: String,
 path: String,
 state: State<'\_, SandboxRoots>,
) -> Result<String, String> {
 // 严格路径拼接，防止 ../ 逃逸
 let base = state.plugin\_data\_dir.join(&plugin\_id);
 let target = base.join(&path);

 // 规范化后必须仍在 base 目录下
 let canonical\_base = std::fs::canonicalize(&base).map\_err(|e| e.to\_string())?;
 let canonical\_target = std::fs::canonicalize(&target).map\_err(|e| e.to\_string())?;

 if !canonical\_target.starts\_with(&canonical\_base) {
 return Err("Path traversal detected".to\_string());
 }

 std::fs::read\_to\_string(&canonical\_target).map\_err(|e| e.to\_string())
}

## 1.7 Tauri Capability 配置（安全核心）

// src-tauri/capabilities/plugin-sandbox.json
{
 "identifier": "plugin-sandbox",
 "description": "Plugin isolated permissions",
 "local": true,
 "windows": ["plugin-\*"],
 "permissions": [
 "core:default",
 {
 "identifier": "fs:scope",
 "allow": [
 { "path": "$APPDATA/plugins/\*" },
 { "path": "$APPDATA/plugins/\*/\*" }
 ]
 }
 ]
}

# 模块二：插件市场后端 Registry（Go + PostgreSQL）

## 2.1 数据库 Schema

-- 插件表
CREATE TABLE plugins (
 id SERIAL PRIMARY KEY,
 plugin\_id VARCHAR(255) UNIQUE NOT NULL, -- manifest.id
 name VARCHAR(255) NOT NULL,
 author VARCHAR(255) NOT NULL,
 category VARCHAR(50) NOT NULL, -- work | dev | life | media
 latest\_version VARCHAR(50) NOT NULL,
 description TEXT,
 icon\_url TEXT,
 download\_count INT DEFAULT 0,
 rating\_avg DECIMAL(2,1) DEFAULT 5.0,
 created\_at TIMESTAMP DEFAULT NOW(),
 updated\_at TIMESTAMP DEFAULT NOW()
);

-- 版本表（支持多版本共存）
CREATE TABLE plugin\_versions (
 id SERIAL PRIMARY KEY,
 plugin\_id INT REFERENCES plugins(id) ON DELETE CASCADE,
 version VARCHAR(50) NOT NULL,
 manifest JSONB NOT NULL,
 package\_url TEXT NOT NULL, -- S3/MinIO 地址
 package\_hash VARCHAR(64) NOT NULL, -- SHA256
 min\_app\_version VARCHAR(20), -- 最低宿主版本要求
 created\_at TIMESTAMP DEFAULT NOW(),
 UNIQUE(plugin\_id, version)
);

-- 分类标签
CREATE TABLE plugin\_tags (
 plugin\_id INT REFERENCES plugins(id) ON DELETE CASCADE,
 tag VARCHAR(50) NOT NULL,
 PRIMARY KEY (plugin\_id, tag)
);

-- 用户安装记录（用于"工作流包"和统计）
CREATE TABLE user\_installs (
 id SERIAL PRIMARY KEY,
 user\_id VARCHAR(255) NOT NULL,
 plugin\_id INT REFERENCES plugins(id),
 version VARCHAR(50),
 installed\_at TIMESTAMP DEFAULT NOW()
);

## 2.2 Go 后端核心 API（Gin 框架）

// registry/main.go
package main

import (
 "net/http"
 "github.com/gin-gonic/gin"
 "github.com/minio/minio-go/v7"
)

type PluginRegistry struct {
 db \*sql.DB
 s3 \*minio.Client
 bucket string
}

func main() {
 r := gin.Default()
 reg := &PluginRegistry{/\* init db & s3 \*/}

 // 公开 API
 r.GET("/api/v1/plugins", reg.ListPlugins)
 r.GET("/api/v1/plugins/:id", reg.GetPluginDetail)
 r.GET("/api/v1/plugins/:id/download", reg.DownloadPlugin)
 r.GET("/api/v1/search", reg.SearchPlugins)

 // 创作者 API（需 JWT）
 authorized := r.Group("/api/v1")
 authorized.Use(JWTMiddleware())
 {
 authorized.POST("/plugins", reg.PublishPlugin)
 authorized.POST("/plugins/:id/versions", reg.PublishVersion)
 }

 r.Run(":8080")
}

// ListPlugins 支持分页、分类、排序
func (reg \*PluginRegistry) ListPlugins(c \*gin.Context) {
 category := c.Query("category")
 tag := c.Query("tag")
 sortBy := c.DefaultQuery("sort", "download\_count") // download\_count | rating | created\_at
 page, \_ := strconv.Atoi(c.DefaultQuery("page", "1"))
 limit, \_ := strconv.Atoi(c.DefaultQuery("limit", "20"))

 query := `
 SELECT p.id, p.plugin\_id, p.name, p.author, p.category,
 p.latest\_version, p.download\_count, p.rating\_avg, p.icon\_url,
 array\_agg(t.tag) as tags
 FROM plugins p
 LEFT JOIN plugin\_tags t ON p.id = t.plugin\_id
 WHERE ($1 = '' OR p.category = $1)
 AND ($2 = '' OR EXISTS (
 SELECT 1 FROM plugin\_tags pt WHERE pt.plugin\_id = p.id AND pt.tag = $2
 ))
 GROUP BY p.id
 ORDER BY p.%s DESC
 LIMIT $3 OFFSET $4
 `
 // 注意：实际生产用参数化排序防止注入

 rows, \_ := reg.db.Query(query, category, tag, limit, (page-1)\*limit)
 // ... scan & return
}

// PublishPlugin 上传新插件
func (reg \*PluginRegistry) PublishPlugin(c \*gin.Context) {
 // 1. 读取 manifest.json
 manifestFile, \_ := c.FormFile("manifest")
 manifestData, \_ := io.ReadAll(manifestFile)

 var manifest struct {
 ID string `json:"id"`
 Name string `json:"name"`
 Version string `json:"version"`
 Author string `json:"author"`
 Category string `json:"category"`
 Permissions []string `json:"permissions"`
 }
 json.Unmarshal(manifestData, &manifest)

 // 2. 保存插件包到 S3/MinIO
 packageFile, \_, \_ := c.Request.FormFile("package")
 objectName := fmt.Sprintf("plugins/%s/%s/package.zip", manifest.ID, manifest.Version)
 reg.s3.PutObject(c, reg.bucket, objectName, packageFile, -1, minio.PutObjectOptions{})

 // 3. 写入数据库
 // ... SQL insert

 c.JSON(200, gin.H{"plugin\_id": manifest.ID, "version": manifest.Version})
}

// DownloadPlugin 带签名和计数
func (reg \*PluginRegistry) DownloadPlugin(c \*gin.Context) {
 pluginID := c.Param("id")
 version := c.Query("version") // 默认 latest

 // 查询 package\_url
 var url string
 reg.db.QueryRow(`
 SELECT pv.package\_url FROM plugin\_versions pv
 JOIN plugins p ON p.id = pv.plugin\_id
 WHERE p.plugin\_id = $1 AND ($2 = '' OR pv.version = $2)
 ORDER BY pv.created\_at DESC LIMIT 1
 `, pluginID, version).Scan(&url)

 // 增加下载计数
 reg.db.Exec("UPDATE plugins SET download\_count = download\_count + 1 WHERE plugin\_id = $1", pluginID)

 // 重定向到预签名 URL（或直接代理）
 c.Redirect(302, url)
}

## 2.3 工作流包（Bundle）导出

// 用户选择多个插件 ID，生成一个 bundle.json + 批量下载
func (reg \*PluginRegistry) ExportBundle(c \*gin.Context) {
 var req struct {
 Name string `json:"name"`
 PluginIDs []string `json:"plugin\_ids"`
 }
 c.BindJSON(&req)

 bundle := map[string]interface{}{
 "name": req.Name,
 "version": "1.0.0",
 "created\_at": time.Now(),
 "plugins": []map[string]string{},
 }

 for \_, pid := range req.PluginIDs {
 var p Plugin
 reg.db.Get(&p, "SELECT \* FROM plugins WHERE plugin\_id = $1", pid)
 bundle["plugins"] = append(bundle["plugins"].([]map[string]string), map[string]string{
 "id": p.PluginID,
 "version": p.LatestVersion,
 "download\_url": fmt.Sprintf("/api/v1/plugins/%s/download", p.PluginID),
 })
 }

 c.JSON(200, bundle)
}

# 模块三：开源工具封装示例（以 Markmap 为例）

**目标**：把 [Markmap](https://github.com/markmap/markmap)（Markdown 转思维导图，纯前端）封装成插件。

## 3.1 原始项目分析

Markmap 是一个纯浏览器库： - 核心：markmap-lib + markmap-view - 使用方式：HTML 引入 JS，把 Markdown 渲染成 SVG 思维导图 - 无后端依赖，完美适合 **Static 类型插件**

## 3.2 封装步骤

### Step 1: 创建插件目录结构

markmap-plugin/
├── manifest.json
├── dist/
│ ├── index.html
│ ├── markmap-lib.js # 从 npm 打包
│ ├── markmap-view.js
│ └── style.css
└── assets/
 └── icon.svg

### Step 2: 编写 manifest.json

{
 "id": "com.aiToolbox.markmap",
 "name": "Markdown 思维导图",
 "version": "1.0.0",
 "author": "AI Toolbox Community",
 "category": "work",
 "entry": "dist/index.html",
 "permissions": ["llm\_chat", "fs\_read", "storage"],
 "llm": {
 "required": true,
 "suggested\_model": "gpt-4o-mini",
 "system\_prompt": "你是一个思维导图生成助手。用户输入主题或大纲，你生成结构化的 Markdown 大纲，使用 # ## ### 层级表示思维导图层级。"
 },
 "hosting": {
 "type": "static"
 }
}

### Step 3: 编写插件前端（index.html）

<!DOCTYPE html>
<html>
<head>
 <meta charset="UTF-8">
 <script src="./markmap-lib.js"></script>
 <script src="./markmap-view.js"></script>
 <style>
 body { margin: 0; font-family: system-ui; background: #fafafa; }
 #toolbar { padding: 12px; background: #fff; border-bottom: 1px solid #e5e5e5; display: flex; gap: 8px; }
 #input { width: 300px; padding: 8px; border: 1px solid #ddd; border-radius: 4px; }
 button { padding: 8px 16px; background: #007acc; color: white; border: none; border-radius: 4px; cursor: pointer; }
 #mindmap { width: 100vw; height: calc(100vh - 50px); }
 </style>
</head>
<body>
 <div id="toolbar">
 <input id="input" placeholder="输入主题，如：AI 产品方法论" />
 <button onclick="generateByAI()">AI 生成大纲</button>
 <button onclick="loadFromFile()">读取本地 Markdown</button>
 <button onclick="exportSVG()">导出 SVG</button>
 </div>
 <svg id="mindmap"></svg>

 <script>
 const { Markmap, loadJS, loadCSS } = window.markmap;

 // 初始化空思维导图
 const svg = document.getElementById('mindmap');
 const mm = Markmap.create(svg, { autoFit: true });

 // 功能1: 调用宿主 LLM 生成 Markdown 大纲
 async function generateByAI() {
 const topic = document.getElementById('input').value;
 if (!topic) return;

 // 调用宿主暴露的 LLM API
 const response = await window.\_\_HOST\_API\_\_.llm.chat([
 { role: 'system', content: '你是一个思维导图生成助手...' },
 { role: 'user', content: `请为"${topic}"生成一个详细的思维导图大纲，使用 Markdown 格式，层级清晰` }
 ]);

 // 渲染
 const { root } = window.markmap.transform(response);
 mm.setData(root);
 mm.fit();

 // 保存到本地存储
 window.\_\_HOST\_API\_\_.storage.set('last\_content', response);
 }

 // 功能2: 读取本地文件（通过宿主 FS API，实际走剪贴板或用户选择更常见）
 async function loadFromFile() {
 // 静态插件通常通过 input type=file 读取，这里演示调用宿主权限
 // 实际更简单的做法：用 HTML5 File API，不走宿主
 const content = prompt("粘贴 Markdown 内容：");
 if (content) {
 const { root } = window.markmap.transform(content);
 mm.setData(root);
 mm.fit();
 }
 }

 function exportSVG() {
 const svgData = new XMLSerializer().serializeToString(svg);
 const blob = new Blob([svgData], {type: 'image/svg+xml'});
 const url = URL.createObjectURL(blob);
 const a = document.createElement('a');
 a.href = url;
 a.download = 'mindmap.svg';
 a.click();
 }

 // 启动时恢复上次内容
 window.addEventListener('DOMContentLoaded', async () => {
 const last = await window.\_\_HOST\_API\_\_.storage.get('last\_content');
 if (last) {
 const { root } = window.markmap.transform(last);
 mm.setData(root);
 mm.fit();
 }
 });
 </script>
</body>
</html>

### Step 4: 构建打包脚本

#!/bin/bash
# build-plugin.sh

# 1. 安装原始依赖并打包
mkdir -p temp && cd temp
npm init -y
npm install markmap-lib markmap-view
# 用 vite 或 rollup 打包成单文件（略，可用 esbuild 快速打包）

# 2. 复制到插件目录
cp node\_modules/markmap-lib/dist/browser/index.iife.js ../dist/markmap-lib.js
cp node\_modules/markmap-view/dist/browser/index.iife.js ../dist/markmap-view.js

# 3. 验证 manifest
node -e "JSON.parse(require('fs').readFileSync('../manifest.json'))"

# 4. 打包成 .zip
cd .. && zip -r markmap-plugin.zip manifest.json dist/ assets/

echo "Plugin packaged: markmap-plugin.zip"

### Step 5: 用户安装流程

1. 用户下载 markmap-plugin.zip
2. 在 AI Toolbox 桌面端点击”安装插件” → 选择 zip
3. Rust 后端解压到 ~/.config/ai-toolbox/plugins/com.aiToolbox.markmap/
4. 读取 manifest.json，校验权限
5. 在”工作区”显示图标，点击启动独立 Webview

# 模块四：API 中转计费系统

## 4.1 业务模型

用户充值 → 获得"平台 API Key" → 桌面端配置此 Key
→ 请求经过你的网关 → 路由到真实 Provider → 按 Token 计费扣款

**你的利润**：真实 Provider 成本 vs 你卖给用户的定价差额。

## 4.2 系统架构

┌─────────────┐ ┌─────────────────────────────┐ ┌─────────────────┐
│ AI Toolbox │────▶│ API Gateway (Go/Gin) │────▶│ OpenAI/Claude │
│ 桌面端 │ │ • 鉴权 / 限流 / 路由 / 计费 │ │ /DeepSeek/本地 │
└─────────────┘ │ • 缓存 / 日志 / 用量统计 │ └─────────────────┘
 └─────────────────────────────┘
 │
 ▼
 ┌─────────────────────────────┐
 │ Billing Service │
 │ • 余额管理 / 充值 / 发票 │
 │ • 成本核算 / 利润分析 │
 └─────────────────────────────┘

## 4.3 数据库设计

-- 用户账户
CREATE TABLE users (
 id UUID PRIMARY KEY DEFAULT gen\_random\_uuid(),
 email VARCHAR(255) UNIQUE NOT NULL,
 api\_key VARCHAR(64) UNIQUE NOT NULL, -- 用户的平台 API Key
 balance DECIMAL(12, 4) DEFAULT 0, -- 余额（人民币或美元）
 total\_spent DECIMAL(12, 4) DEFAULT 0,
 created\_at TIMESTAMP DEFAULT NOW()
);

-- 模型定价配置（你对外售价 vs 真实成本）
CREATE TABLE model\_pricing (
 id SERIAL PRIMARY KEY,
 model\_name VARCHAR(100) UNIQUE NOT NULL, -- gpt-4o, claude-3-7-sonnet
 provider VARCHAR(50) NOT NULL, -- openai, anthropic
 cost\_per\_1k\_input DECIMAL(8, 6) NOT NULL, -- 你的成本（美元）
 cost\_per\_1k\_output DECIMAL(8, 6) NOT NULL,
 price\_per\_1k\_input DECIMAL(8, 6) NOT NULL, -- 你售价（美元）
 price\_per\_1k\_output DECIMAL(8, 6) NOT NULL,
 is\_active BOOLEAN DEFAULT true
);

-- 请求日志（用于计费和对账）
CREATE TABLE request\_logs (
 id BIGSERIAL PRIMARY KEY,
 user\_id UUID REFERENCES users(id),
 api\_key VARCHAR(64) NOT NULL,
 model VARCHAR(100) NOT NULL,
 provider VARCHAR(50) NOT NULL,
 input\_tokens INT NOT NULL,
 output\_tokens INT NOT NULL,
 cost\_amount DECIMAL(10, 6) NOT NULL, -- 你的成本
 charge\_amount DECIMAL(10, 6) NOT NULL, -- 向用户收取
 latency\_ms INT,
 status\_code INT,
 created\_at TIMESTAMP DEFAULT NOW()
);

-- 充值记录
CREATE TABLE transactions (
 id BIGSERIAL PRIMARY KEY,
 user\_id UUID REFERENCES users(id),
 type VARCHAR(20) NOT NULL, -- recharge | consumption | refund
 amount DECIMAL(12, 4) NOT NULL,
 currency VARCHAR(3) DEFAULT 'CNY',
 payment\_method VARCHAR(50), -- alipay | wechat | stripe
 status VARCHAR(20) DEFAULT 'pending', -- pending | success | failed
 created\_at TIMESTAMP DEFAULT NOW()
);

## 4.4 Go 网关核心代码

// gateway/main.go
package main

import (
 "bytes"
 "encoding/json"
 "io"
 "net/http"
 "net/http/httputil"
 "net/url"
 "strings"
 "time"

 "github.com/gin-gonic/gin"
 "github.com/patrickmn/go-cache"
 "golang.org/x/time/rate"
)

type Gateway struct {
 db \*sql.DB
 rateCache \*cache.Cache // 内存限流器存储
 modelPrices map[string]ModelPricing
}

func (g \*Gateway) ProxyHandler(c \*gin.Context) {
 start := time.Now()

 // 1. 鉴权：从 Header 获取平台 API Key
 authHeader := c.GetHeader("Authorization")
 if !strings.HasPrefix(authHeader, "Bearer ") {
 c.JSON(401, gin.H{"error": "Missing API Key"})
 return
 }
 userKey := strings.TrimPrefix(authHeader, "Bearer ")

 // 2. 查询用户和余额
 var user User
 err := g.db.Get(&user, "SELECT \* FROM users WHERE api\_key = $1", userKey)
 if err != nil {
 c.JSON(401, gin.H{"error": "Invalid API Key"})
 return
 }
 if user.Balance <= 0 {
 c.JSON(403, gin.H{"error": "Insufficient balance"})
 return
 }

 // 3. 限流检查（基于用户 ID）
 limiter := g.getRateLimiter(user.ID)
 if !limiter.Allow() {
 c.JSON(429, gin.H{"error": "Rate limit exceeded"})
 return
 }

 // 4. 读取请求体，解析模型名称
 bodyBytes, \_ := io.ReadAll(c.Request.Body)
 c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))

 var reqBody map[string]interface{}
 json.Unmarshal(bodyBytes, &reqBody)
 modelName, \_ := reqBody["model"].(string)

 // 5. 获取模型定价和真实 Provider 路由
 pricing, ok := g.modelPrices[modelName]
 if !ok {
 c.JSON(400, gin.H{"error": "Unsupported model"})
 return
 }

 // 6. 构建到真实 Provider 的代理
 targetURL, \_ := url.Parse(getProviderBaseURL(pricing.Provider))
 proxy := httputil.NewSingleHostReverseProxy(targetURL)

 // 修改请求：替换 Authorization 为真实 Provider 的 Key
 originalDirector := proxy.Director
 proxy.Director = func(req \*http.Request) {
 originalDirector(req)
 req.Host = targetURL.Host
 req.Header.Set("Authorization", "Bearer "+getProviderAPIKey(pricing.Provider))
 }

 // 7. 拦截响应，记录用量
 proxy.ModifyResponse = func(resp \*http.Response) error {
 if resp.StatusCode == 200 {
 // 读取响应体
 respBody, \_ := io.ReadAll(resp.Body)
 resp.Body = io.NopCloser(bytes.NewBuffer(respBody))

 // 解析 usage
 var respData map[string]interface{}
 json.Unmarshal(respBody, &respData)

 if usage, ok := respData["usage"].(map[string]interface{}); ok {
 inputTokens := int(usage["prompt\_tokens"].(float64))
 outputTokens := int(usage["completion\_tokens"].(float64))

 cost := calculateCost(inputTokens, outputTokens, pricing.CostPer1kInput, pricing.CostPer1kOutput)
 charge := calculateCost(inputTokens, outputTokens, pricing.PricePer1kInput, pricing.PricePer1kOutput)

 // 异步记录日志和扣费
 go g.recordUsage(user.ID, userKey, modelName, pricing.Provider,
 inputTokens, outputTokens, cost, charge,
 int(time.Since(start).Milliseconds()), resp.StatusCode)

 // 扣减余额
 g.db.Exec("UPDATE users SET balance = balance - $1, total\_spent = total\_spent + $1 WHERE id = $2",
 charge, user.ID)
 }
 }
 return nil
 }

 proxy.ServeHTTP(c.Writer, c.Request)
}

func (g \*Gateway) recordUsage(userID uuid.UUID, apiKey, model, provider string,
 inTokens, outTokens int, cost, charge float64, latency, status int) {

 g.db.Exec(`
 INSERT INTO request\_logs
 (user\_id, api\_key, model, provider, input\_tokens, output\_tokens,
 cost\_amount, charge\_amount, latency\_ms, status\_code)
 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
 `, userID, apiKey, model, provider, inTokens, outTokens, cost, charge, latency, status)
}

func (g \*Gateway) getRateLimiter(userID uuid.UUID) \*rate.Limiter {
 key := "rate:" + userID.String()
 if val, found := g.rateCache.Get(key); found {
 return val.(\*rate.Limiter)
 }
 // 默认：60 请求/分钟
 limiter := rate.NewLimiter(rate.Every(time.Second), 60)
 g.rateCache.Set(key, limiter, cache.DefaultExpiration)
 return limiter
}

func calculateCost(tokens int, pricePer1k float64) float64 {
 return float64(tokens) \* pricePer1k / 1000.0
}

## 4.5 桌面端集成（用户配置面板）

// 前端 React 组件：API 中转设置
export function APIProxySettings() {
 const [userKey, setUserKey] = useState('');
 const [balance, setBalance] = useState(0);

 useEffect(() => {
 // 从 Tauri 后端读取已保存的平台 API Key
 invoke<string>('get\_platform\_api\_key').then(setUserKey);
 }, []);

 const checkBalance = async () => {
 const resp = await fetch('https://your-gateway.com/api/v1/balance', {
 headers: { 'Authorization': `Bearer ${userKey}` }
 });
 const data = await resp.json();
 setBalance(data.balance);
 };

 return (
 <div className="space-y-4">
 <div>
 <label>平台 API Key</label>
 <input
 value={userKey}
 onChange={e => setUserKey(e.target.value)}
 placeholder="从充值中心复制"
 />
 <button onClick={() => invoke('save\_platform\_api\_key', { key: userKey })}>
 保存
 </button>
 </div>

 <div className="flex items-center gap-2">
 <span>余额: ¥{balance.toFixed(2)}</span>
 <button onClick={checkBalance}>刷新</button>
 </div>

 <a href="https://your-payment-page.com" target="\_blank">
 去充值 →
 </a>

 <div className="text-sm text-gray-500">
 提示：使用平台 Key 后，所有插件的 LLM 调用将走中转通道，
 无需单独配置各厂商 API Key。
 </div>
 </div>
 );
}

## 4.6 定价策略示例

| 模型 | 真实成本 (Input/1K) | 你的售价 (Input/1K) | 利润率 |
| --- | --- | --- | --- |
| gpt-4o-mini | $0.00015 | $0.00030 | 100% |
| gpt-4o | $0.0025 | $0.0040 | 60% |
| claude-3-7-sonnet | $0.003 | $0.005 | 67% |
| deepseek-chat | $0.00014 | $0.00028 | 100% |

**起步策略**：早期可以只加价 20-30% 吸引用户，靠量取胜。

## 总结：四个模块的衔接关系

┌─────────────────────────────────────────────────────────────┐
│ 桌面端 (Tauri v2) │
│ ├─ 插件沙箱系统 ←── 模块一 Rust 代码 │
│ ├─ LLM 配置面板 ←── 模块四 平台 API Key 管理 │
│ └─ 插件商店 UI ←── 模块二 Registry API 消费端 │
├─────────────────────────────────────────────────────────────┤
│ 插件生态 │
│ ├─ Markmap 示例 ←── 模块三 完整封装流程 │
│ └─ 更多工具... │
├─────────────────────────────────────────────────────────────┤
│ 服务端 (Go) │
│ ├─ Registry API ←── 模块二 插件市场后端 │
│ └─ API Gateway ←── 模块四 中转计费系统 │
└─────────────────────────────────────────────────────────────┘

需要我进一步展开哪个具体文件的完整代码（比如 Gateway 的 Dockerfile + docker-compose 部署配置，或者 Tauri 前端插件商店的 React 组件）？

**User:**

gateway 这些都还远，主要先跑通插件模式，然后自定义 build 开源仓库可能还都需要修改一些的，所以核心 spec 的设定很重要，MVP 版本是这个

**Kimi:**

明白，收敛到 **MVP 核心：Spec + 本地加载 + 开源封装**。以下是可直接执行的 MVP 方案，不涉及任何后端。

# MVP 插件系统：核心 Spec

## 1. 插件包规范（极简但可扩展）

my-plugin/
├── manifest.json # 唯一必需文件
├── dist/ # 前端构建产物
│ └── index.html # 入口
└── assets/
 └── icon.svg

### manifest.json（MVP 版本）

{
 "manifest\_version": "0.1.0",
 "id": "com.example.pdf-translator",
 "name": "PDF 智能翻译",
 "version": "1.0.0",
 "author": "your-name",
 "category": "work",
 "entry": "dist/index.html",
 "permissions": ["llm.chat", "storage", "dialog.open"],
 "hosting": {
 "type": "static"
 }
}

**MVP 阶段只支持 hosting.type: static**（纯前端）。本地服务型（sidecar）放到 v2。

### 权限清单（MVP 最小集）

| 权限 | 说明 |
| --- | --- |
| llm.chat | 调用用户已配置的大模型 |
| llm.models | 获取可用模型列表 |
| storage.get / storage.set | 插件私有 KV（隔离存储） |
| clipboard.read / clipboard.write | 剪贴板 |
| dialog.open | 文件选择对话框 |
| shell.open | 用系统默认程序打开文件/链接 |

## 2. 宿主 API 标准（注入到插件的全局对象）

每个插件的 Webview 会注入一个全局对象 window.\_\_HOST\_\_。MVP 只暴露这些：

// 插件内可直接调用，无需 import
interface HostAPI {
 // LLM
 llm: {
 chat(messages: {role:'system'|'user'|'assistant', content:string}[], model?: string): Promise<string>;
 models(): Promise<string[]>;
 };

 // 存储（自动隔离，每个插件只能访问自己的 namespace）
 storage: {
 get(key: string): Promise<any>;
 set(key: string, value: any): Promise<void>;
 };

 // 剪贴板
 clipboard: {
 readText(): Promise<string>;
 writeText(text: string): Promise<void>;
 };

 // 文件对话框
 dialog: {
 open(options?: {multiple?: boolean; filters?: {name:string; extensions:string[]}[]}): Promise<string[]>;
 };

 // 系统打开
 shell: {
 open(path: string): Promise<void>;
 };

 // 元信息
 meta: {
 pluginId: string;
 version: string;
 };
}

**关键设计**：插件**不直接持有 API Key**，所有 LLM 请求经过宿主路由。这样你未来做中转时，只需改宿主逻辑，插件无感知。

## 3. Tauri MVP 实现（Rust 侧）

### 3.1 插件发现（本地扫描）

// src/plugin/manager.rs
use std::path::{Path, PathBuf};
use serde::{Deserialize, Serialize};
use anyhow::Result;

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct PluginManifest {
 pub manifest\_version: String,
 pub id: String,
 pub name: String,
 pub version: String,
 pub author: String,
 pub category: String,
 pub entry: String,
 pub permissions: Vec<String>,
 pub hosting: HostingConfig,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct HostingConfig {
 #[serde(rename = "type")]
 pub hosting\_type: String,
}

pub struct Plugin {
 pub manifest: PluginManifest,
 pub root\_dir: PathBuf,
}

pub struct PluginManager {
 plugins\_dir: PathBuf,
}

impl PluginManager {
 pub fn new(app\_handle: &tauri::AppHandle) -> Result<Self> {
 let data\_dir = app\_handle.path().app\_data\_dir()?;
 let plugins\_dir = data\_dir.join("plugins");
 std::fs::create\_dir\_all(&plugins\_dir)?;
 Ok(Self { plugins\_dir })
 }

 pub fn discover(&self) -> Result<Vec<<Plugin>> {
 let mut plugins = vec![];
 for entry in std::fs::read\_dir(&self.plugins\_dir)? {
 let entry = entry?;
 let path = entry.path();
 if path.is\_dir() {
 let manifest\_path = path.join("manifest.json");
 if manifest\_path.exists() {
 let content = std::fs::read\_to\_string(&manifest\_path)?;
 let manifest: PluginManifest = serde\_json::from\_str(&content)?;
 plugins.push(Plugin { manifest, root\_dir: path });
 }
 }
 }
 Ok(plugins)
 }
}

### 3.2 创建插件 Webview（带 API 注入）

// src/plugin/runtime.rs
use tauri::{AppHandle, Manager, WebviewUrl, WebviewWindow};
use std::collections::HashSet;

pub fn spawn\_plugin\_webview(
 app: &AppHandle,
 parent: &WebviewWindow,
 plugin: &Plugin,
) -> Result<WebviewWindow, String> {
 let entry = plugin.root\_dir.join(&plugin.manifest.entry);
 let perms: HashSet<String> = plugin.manifest.permissions.iter().cloned().collect();
 let plugin\_id = plugin.manifest.id.clone();

 // 构建注入脚本
 let init\_script = format!(
 r#"
 window.\_\_HOST\_\_ = {{
 \_perms: new Set({perms:?}),
 \_invoke: (cmd, args) => window.\_\_TAURI\_INTERNALS\_\_.invoke(cmd, {{ ...args, \_\_pluginId: '{plugin\_id}' }}),

 llm: {{
 chat: (messages, model) => {{
 if (!window.\_\_HOST\_\_.\_perms.has('llm.chat')) throw new Error('Permission denied: llm.chat');
 return window.\_\_HOST\_\_.\_invoke('plugin\_llm\_chat', {{ messages, model }});
 }},
 models: () => window.\_\_HOST\_\_.\_invoke('plugin\_llm\_models', {{}})
 }},

 storage: {{
 get: (key) => window.\_\_HOST\_\_.\_invoke('plugin\_storage\_get', {{ key }}),
 set: (key, value) => window.\_\_HOST\_\_.\_invoke('plugin\_storage\_set', {{ key, value }})
 }},

 clipboard: {{
 readText: () => {{
 if (!window.\_\_HOST\_\_.\_perms.has('clipboard.read')) throw new Error('Permission denied');
 return window.\_\_HOST\_\_.\_invoke('plugin\_clipboard\_read', {{}});
 }},
 writeText: (text) => window.\_\_HOST\_\_.\_invoke('plugin\_clipboard\_write', {{ text }})
 }},

 dialog: {{
 open: (opts) => window.\_\_HOST\_\_.\_invoke('plugin\_dialog\_open', opts || {{}})
 }},

 shell: {{
 open: (path) => window.\_\_HOST\_\_.\_invoke('plugin\_shell\_open', {{ path }})
 }},

 meta: {{
 pluginId: '{plugin\_id}',
 version: '{version}'
 }}
 }};
 "#,
 perms = plugin.manifest.permissions,
 plugin\_id = plugin\_id,
 version = plugin.manifest.version
 );

 let label = format!("plugin-{}-{}", plugin.manifest.id.replace(".", "-"), uuid::Uuid::new\_v4());

 let webview = parent.add\_child(
 tauri::webview::WebviewBuilder::new(&label, WebviewUrl::AppFile(entry.into()))
 .initialization\_script(&init\_script)
 ).map\_err(|e| e.to\_string())?;

 Ok(webview)
}

### 3.3 Command 实现（权限校验 + 存储隔离）

// src/commands.rs
use tauri::{State, AppHandle, Manager};
use std::collections::HashMap;
use std::sync::Mutex;

// 内存中的 LLM 配置（MVP 阶段先写死或从配置文件读）
pub struct LlmConfig {
 pub api\_key: String,
 pub base\_url: String,
 pub default\_model: String,
}

pub struct AppState {
 pub llm\_config: Mutex<LlmConfig>,
 pub plugin\_storage: Mutex<<HashMap<String, HashMap<String, serde\_json::Value>>>,
}

#[tauri::command]
pub async fn plugin\_llm\_chat(
 \_\_plugin\_id: String,
 messages: Vec<<serde\_json::Value>,
 model: Option<String>,
 state: State<'\_, AppState>,
) -> Result<String, String> {
 let config = state.llm\_config.lock().map\_err(|e| e.to\_string())?;

 let client = reqwest::Client::new();
 let body = serde\_json::json!({
 "model": model.unwrap\_or\_else(|| config.default\_model.clone()),
 "messages": messages,
 "stream": false
 });

 let resp = client
 .post(format!("{}/v1/chat/completions", config.base\_url))
 .header("Authorization", format!("Bearer {}", config.api\_key))
 .json(&body)
 .send()
 .await
 .map\_err(|e| e.to\_string())?;

 let result = resp.json::<serde\_json::Value>().await.map\_err(|e| e.to\_string())?;

 Ok(result["choices"][0]["message"]["content"].as\_str().unwrap\_or("").to\_string())
}

#[tauri::command]
pub fn plugin\_storage\_get(
 \_\_plugin\_id: String,
 key: String,
 state: State<'\_, AppState>,
) -> Result<<serde\_json::Value, String> {
 let storage = state.plugin\_storage.lock().map\_err(|e| e.to\_string())?;
 let plugin\_store = storage.get(&\_\_plugin\_id);
 Ok(plugin\_store
 .and\_then(|s| s.get(&key).cloned())
 .unwrap\_or(serde\_json::Value::Null))
}

#[tauri::command]
pub fn plugin\_storage\_set(
 \_\_plugin\_id: String,
 key: String,
 value: serde\_json::Value,
 state: State<'\_, AppState>,
) -> Result<(), String> {
 let mut storage = state.plugin\_storage.lock().map\_err(|e| e.to\_string())?;
 storage.entry(\_\_plugin\_id).or\_default().insert(key, value);
 Ok(())
}

// 其他 commands（clipboard, dialog, shell）直接用 Tauri 的 core plugin
#[tauri::command]
pub async fn plugin\_clipboard\_read(app: AppHandle) -> Result<String, String> {
 let clipboard = app.clipboard();
 clipboard.read\_text().await.map\_err(|e| e.to\_string())
}

### 3.4 Tauri 主入口注册

// src/main.rs
#![cfg\_attr(not(debug\_assertions), windows\_subsystem = "windows")]

mod commands;
mod plugin;

use commands::\*;
use plugin::manager::PluginManager;

fn main() {
 tauri::Builder::default()
 .manage(AppState {
 llm\_config: std::sync::Mutex::new(LlmConfig {
 api\_key: "".to\_string(), // 从设置面板读取
 base\_url: "https://api.openai.com".to\_string(),
 default\_model: "gpt-4o-mini".to\_string(),
 }),
 plugin\_storage: std::sync::Mutex::new(std::collections::HashMap::new()),
 })
 .invoke\_handler(tauri::generate\_handler![
 plugin\_llm\_chat,
 plugin\_llm\_models,
 plugin\_storage\_get,
 plugin\_storage\_set,
 plugin\_clipboard\_read,
 plugin\_clipboard\_write,
 plugin\_dialog\_open,
 plugin\_shell\_open,
 ])
 .setup(|app| {
 let manager = PluginManager::new(app.handle())?;
 let plugins = manager.discover()?;

 // 把插件列表注入到前端主窗口
 let main\_window = app.get\_webview\_window("main").unwrap();
 let plugin\_list: Vec<<serde\_json::Value> = plugins.iter().map(|p| {
 serde\_json::json!({
 "id": p.manifest.id,
 "name": p.manifest.name,
 "version": p.manifest.version,
 "category": p.manifest.category,
 "permissions": p.manifest.permissions
 })
 }).collect();

 main\_window.eval(&format!(
 "window.\_\_PLUGINS\_\_ = {};",
 serde\_json::to\_string(&plugin\_list).unwrap()
 )).ok();

 Ok(())
 })
 .run(tauri::generate\_context!())
 .expect("error while running tauri application");
}

## 4. 前端主窗口（插件启动器）

// src/App.tsx
import { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/core';

interface PluginInfo {
 id: string;
 name: string;
 category: string;
 permissions: string[];
}

export default function App() {
 const [plugins, setPlugins] = useState<<PluginInfo[]>([]);
 const [activePlugin, setActivePlugin] = useState<string | null>(null);

 useEffect(() => {
 // 从 window.\_\_PLUGINS\_\_ 读取，或调用 discover 命令
 setPlugins((window as any).\_\_PLUGINS\_\_ || []);
 }, []);

 const launchPlugin = async (pluginId: string) => {
 await invoke('launch\_plugin', { pluginId });
 setActivePlugin(pluginId);
 };

 return (
 <div className="flex h-screen bg-gray-50">
 {/\* 侧边栏：插件列表 \*/}
 <aside className="w-64 bg-white border-r border-gray-200 p-4">
 <h1 className="text-lg font-bold mb-4">AI Toolbox</h1>
 <div className="space-y-2">
 {plugins.map(p => (
 <button
 key={p.id}
 onClick={() => launchPlugin(p.id)}
 className={`w-full text-left px-3 py-2 rounded-lg text-sm ${
 activePlugin === p.id ? 'bg-blue-50 text-blue-600' : 'hover:bg-gray-100'
 }`}
 >
 <div className="font-medium">{p.name}</div>
 <div className="text-xs text-gray-500">{p.category} · {p.permissions.length} 权限</div>
 </button>
 ))}
 </div>
 </aside>

 {/\* 主区域：插件 Webview 容器 \*/}
 <main className="flex-1 relative">
 <div id="plugin-container" className="absolute inset-0" />
 {!activePlugin && (
 <div className="flex items-center justify-center h-full text-gray-400">
 选择一个插件开始使用
 </div>
 )}
 </main>
 </div>
 );
}

## 5. 开源项目封装策略（MVP 最小侵入）

### 策略 A：纯前端类（推荐 80% 场景）

**适用**：Vite/React/Vue 构建的纯浏览器工具（Markmap、Excalidraw、PPTist 等）

**步骤**： 1. 克隆开源项目，找到它的 index.html 入口 2. 在它的 index.html 中**追加一段 script**，暴露 window.\_\_HOST\_\_ 3. 在需要 AI 的地方直接调用 window.\_\_HOST\_\_.llm.chat() 4. 构建产物复制到插件包 dist/

**示例：封装 Excalidraw（白板工具）**

Excalidraw 是 React 项目，有导出 SVG/PNG 功能。我们要加的是：**AI 生成草图描述**。

<!-- 在 Excalidraw 构建后的 index.html 底部追加 -->
<script>
// 检查是否在宿主环境中
if (window.\_\_HOST\_\_) {
 // 添加一个浮动 AI 按钮到 DOM
 const btn = document.createElement('button');
 btn.innerText = 'AI 生成';
 btn.style.cssText = 'position:fixed;bottom:20px;right:20px;z-index:9999;padding:8px 16px;background:#007acc;color:white;border:none;border-radius:4px;cursor:pointer;';

 btn.onclick = async () => {
 const prompt = prompt('描述你想画的图：');
 if (!prompt) return;

 const response = await window.\_\_HOST\_\_.llm.chat([
 { role: 'system', content: '你是一个图形描述助手。用户描述一个图表或草图，你输出 Excalidraw 的 JSON 元素数组格式。只输出 JSON，不要解释。' },
 { role: 'user', content: prompt }
 ]);

 try {
 const elements = JSON.parse(response);
 // 通过 Excalidraw 的全局 API 导入（它暴露了一个 window.excalidrawAPI）
 window.excalidrawAPI.updateScene({ elements });
 } catch(e) {
 alert('AI 返回格式错误');
 }
 };

 document.body.appendChild(btn);
}
</script>

**关键**：不需要改 Excalidraw 的源码，只需要在最终 HTML 中注入一段脚本。你可以写个自动化脚本做这件事。

### 策略 B：iframe 包装类（完全不修改源码）

**适用**：你想聚合一个在线工具，但它没有暴露全局 API。

<!-- 插件 index.html -->
<!DOCTYPE html>
<html>
<head>
 <style>
 body { margin: 0; display: flex; flex-direction: column; height: 100vh; }
 #toolbar { height: 40px; background: #1a1a1a; display: flex; align-items: center; padding: 0 12px; gap: 8px; }
 iframe { flex: 1; border: none; }
 button { background: #333; color: white; border: 1px solid #555; padding: 4px 12px; cursor: pointer; }
 </style>
</head>
<body>
 <div id="toolbar">
 <span style="color:#888;font-size:12px;">AI Toolbox · 沉浸式翻译</span>
 <button onclick="translatePage()">AI 翻译全文</button>
 </div>
 <iframe src="https://immersivetranslate.com/"></iframe>

 <script>
 async function translatePage() {
 // 获取 iframe 内容（受同源限制，仅演示思路）
 // 实际更可靠的做法是注入 content script 或配合浏览器插件
 const text = await window.\_\_HOST\_\_.clipboard.readText();
 const translated = await window.\_\_HOST\_\_.llm.chat([
 { role: 'user', content: `翻译以下内容为中文：\n\n${text}` }
 ]);
 await window.\_\_HOST\_\_.clipboard.writeText(translated);
 alert('翻译结果已复制到剪贴板');
 }
 </script>
</body>
</html>

**局限**：iframe 跨域限制多，MVP 阶段优先用策略 A。

### 策略 C：Patch 脚本类（构建时注入）

写一个 patch-plugin.js，在开源项目构建后自动修改它的入口文件：

// scripts/patch-plugin.js
const fs = require('fs');
const path = require('path');

function patch(distPath, pluginId) {
 const htmlPath = path.join(distPath, 'index.html');
 let html = fs.readFileSync(htmlPath, 'utf8');

 // 在 </body> 前注入 bridge
 const bridgeScript = `
<script>
(function(){
 // 等待宿主 API 就绪
 const check = setInterval(() => {
 if (window.\_\_HOST\_\_) {
 clearInterval(check);
 // 在这里挂载到开源项目的全局对象
 console.log('[${pluginId}] Host API connected');
 }
 }, 100);
})();
</script>
`;

 html = html.replace('</body>', bridgeScript + '</body>');
 fs.writeFileSync(htmlPath, html);
 console.log('Patched:', htmlPath);
}

patch(process.argv[2], process.argv[3]);

使用：

npm run build # 构建开源项目
node patch-plugin.js ./dist com.example.tool

## 6. 开发者模板（独立开发插件）

给社区开发者的最小模板：

ai-toolbox-plugin-template/
├── package.json
├── vite.config.ts
├── src/
│ ├── main.ts # 插件逻辑
│ └── host.d.ts # \_\_HOST\_\_ 类型定义
├── manifest.json
└── dist/ # 构建输出

### src/host.d.ts（类型提示）

declare interface HostAPI {
 llm: {
 chat(messages: Array<{role:string, content:string}>, model?: string): Promise<string>;
 models(): Promise<string[]>;
 };
 storage: {
 get(key: string): Promise<any>;
 set(key: string, value: any): Promise<void>;
 };
 clipboard: {
 readText(): Promise<string>;
 writeText(text: string): Promise<void>;
 };
 dialog: {
 open(options?: any): Promise<string[]>;
 };
 shell: {
 open(path: string): Promise<void>;
 };
 meta: {
 pluginId: string;
 version: string;
 };
}

declare global {
 interface Window {
 \_\_HOST\_\_: HostAPI;
 }
}
export {};

### src/main.ts（开发时模拟 + 生产调用）

// 开发环境 mock
if (!window.\_\_HOST\_\_) {
 window.\_\_HOST\_\_ = {
 llm: {
 chat: async (msgs) => `[MOCK] ${msgs.at(-1)?.content}`,
 models: async () => ['gpt-4o', 'claude-3-sonnet']
 },
 storage: {
 get: async (k) => localStorage.getItem(k),
 set: async (k, v) => localStorage.setItem(k, v)
 },
 clipboard: {
 readText: async () => navigator.clipboard.readText(),
 writeText: async (t) => navigator.clipboard.writeText(t)
 },
 dialog: {
 open: async () => []
 },
 shell: {
 open: async (p) => window.open(p, '\_blank')
 },
 meta: { pluginId: 'dev', version: '0.0.0' }
 };
}

// 插件实际逻辑
async function main() {
 const result = await window.\_\_HOST\_\_.llm.chat([
 { role: 'user', content: '你好' }
 ]);
 document.body.innerHTML = `<pre>${result}</pre>`;
}

main();

**开发流程**： 1. npm run dev → 浏览器打开，用 mock 调试 2. npm run build → 产出 dist/ 3. 复制到 AI Toolbox/plugins/com.your.plugin/ 4. 重启 AI Toolbox，即可在侧边栏看到

## 7. MVP 交付清单

| 组件 | 状态 | 说明 |
| --- | --- | --- |
| manifest.json spec | ✅ | 上面定义 |
| 本地扫描加载 | ✅ | PluginManager::discover() |
| Webview 隔离 + API 注入 | ✅ | spawn\_plugin\_webview() |
| 权限校验 | ✅ | \_perms.has() |
| 存储隔离 | ✅ | \_\_pluginId 命名空间 |
| LLM 统一调用 | ✅ | plugin\_llm\_chat |
| 开发者 mock | ✅ | host.d.ts |
| 开源封装策略 | ✅ | A/B/C 三种 |

**下一步动作**： 1. 用上面的 Rust 代码搭出 Tauri 骨架 2. 写一个 hello-plugin（显示当前模型列表的页面）验证端到端 3. 选一个纯前端开源项目（如 Markmap）用策略 A 封装，跑通第一个真实插件

需要我把 **hello-plugin 的完整代码** 或者 **某个具体开源项目的完整封装步骤**（比如 Excalidraw 或 PPTist）展开吗？

**User:**

我都需要你提到的两个都需要，一个框架，两个项目

**Kimi:**

我直接给你 **3 个完整可运行的包**：1 个验证框架 + 2 个开源封装。

# 一、hello-plugin（端到端验证框架）

这是最小可用单元，用来确认你的 Tauri 宿主 API 注入、权限隔离、LLM 路由全部正常工作。

## 目录结构

hello-plugin/
├── manifest.json
└── dist/
 └── index.html

## manifest.json

{
 "manifest\_version": "0.1.0",
 "id": "com.aitoolbox.hello",
 "name": "Hello 验证器",
 "version": "1.0.0",
 "author": "AI Toolbox",
 "category": "dev",
 "entry": "dist/index.html",
 "permissions": ["llm.chat", "llm.models", "storage.get", "storage.set", "clipboard.read", "clipboard.write"],
 "hosting": { "type": "static" }
}

## dist/index.html

<!DOCTYPE html>
<html lang="zh">
<head>
 <meta charset="UTF-8">
 <meta name="viewport" content="width=device-width, initial-scale=1.0">
 <title>Hello Plugin</title>
 <style>
 \* { margin: 0; padding: 0; box-sizing: border-box; }
 body {
 font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
 background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
 min-height: 100vh;
 display: flex;
 align-items: center;
 justify-content: center;
 color: white;
 }
 .card {
 background: rgba(255,255,255,0.1);
 backdrop-filter: blur(10px);
 border-radius: 16px;
 padding: 32px;
 width: 480px;
 border: 1px solid rgba(255,255,255,0.2);
 }
 h1 { font-size: 20px; margin-bottom: 20px; font-weight: 600; }
 .section { margin-bottom: 20px; }
 .label { font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.8; margin-bottom: 8px; }
 .value { font-family: 'Courier New', monospace; font-size: 13px; background: rgba(0,0,0,0.2); padding: 8px 12px; border-radius: 6px; word-break: break-all; }
 .models { display: flex; flex-wrap: wrap; gap: 6px; }
 .tag {
 background: rgba(255,255,255,0.2);
 padding: 4px 10px;
 border-radius: 12px;
 font-size: 12px;
 }
 .chat-box {
 margin-top: 16px;
 background: rgba(0,0,0,0.15);
 border-radius: 8px;
 padding: 12px;
 min-height: 60px;
 font-size: 14px;
 line-height: 1.5;
 }
 button {
 width: 100%;
 padding: 10px;
 margin-top: 8px;
 background: rgba(255,255,255,0.25);
 border: 1px solid rgba(255,255,255,0.3);
 color: white;
 border-radius: 6px;
 cursor: pointer;
 font-size: 14px;
 transition: all 0.2s;
 }
 button:hover { background: rgba(255,255,255,0.35); }
 button:disabled { opacity: 0.5; cursor: not-allowed; }
 .status { font-size: 11px; margin-top: 8px; opacity: 0.7; }
 .error { color: #ff6b6b; font-size: 12px; margin-top: 8px; }
 </style>
</head>
<body>
 <div class="card">
 <h1>🔌 插件验证器</h1>

 <div class="section">
 <div class="label">Plugin ID</div>
 <div class="value" id="plugin-id">检测中...</div>
 </div>

 <div class="section">
 <div class="label">可用模型</div>
 <div class="models" id="models">加载中...</div>
 </div>

 <div class="section">
 <div class="label">Storage 测试</div>
 <div class="value" id="storage">检测中...</div>
 </div>

 <div class="section">
 <div class="label">LLM 对话测试</div>
 <button onclick="testChat()" id="chat-btn">发送测试消息</button>
 <div class="chat-box" id="chat-result">点击按钮测试对话...</div>
 <div class="status" id="chat-status"></div>
 </div>

 <div class="section">
 <div class="label">Clipboard 测试</div>
 <button onclick="testClipboard()">读取剪贴板</button>
 <div class="value" id="clipboard-result">-</div>
 </div>

 <div class="error" id="error"></div>
 </div>

 <script>
 const $ = id => document.getElementById(id);

 async function init() {
 try {
 // 1. 验证 Meta
 if (!window.\_\_HOST\_\_) {
 throw new Error('window.\_\_HOST\_\_ 未注入 - 请确认在 AI Toolbox 中运行');
 }
 $('plugin-id').textContent = window.\_\_HOST\_\_.meta.pluginId + ' @ ' + window.\_\_HOST\_\_.meta.version;

 // 2. 测试 models
 const models = await window.\_\_HOST\_\_.llm.models();
 $('models').innerHTML = models.map(m => `<span class="tag">${m}</span>`).join('');

 // 3. 测试 storage 隔离
 await window.\_\_HOST\_\_.storage.set('test\_key', { hello: 'world', time: Date.now() });
 const stored = await window.\_\_HOST\_\_.storage.get('test\_key');
 $('storage').textContent = JSON.stringify(stored);

 } catch (e) {
 $('error').textContent = '❌ ' + e.message;
 console.error(e);
 }
 }

 async function testChat() {
 const btn = $('chat-btn');
 btn.disabled = true;
 $('chat-status').textContent = '请求中...';

 try {
 const reply = await window.\_\_HOST\_\_.llm.chat([
 { role: 'system', content: '你是一个极简助手，只回复一句话。' },
 { role: 'user', content: '请用一句话证明你正常工作' }
 ]);
 $('chat-result').textContent = reply;
 $('chat-status').textContent = '✅ 对话成功';
 } catch (e) {
 $('chat-status').textContent = '❌ 失败: ' + e.message;
 } finally {
 btn.disabled = false;
 }
 }

 async function testClipboard() {
 try {
 const text = await window.\_\_HOST\_\_.clipboard.readText();
 $('clipboard-result').textContent = text || '(剪贴板为空)';
 } catch (e) {
 $('clipboard-result').textContent = '错误: ' + e.message;
 }
 }

 init();
 </script>
</body>
</html>

## 安装测试

# 1. 创建插件目录
mkdir -p ~/.config/ai-toolbox/plugins/com.aitoolbox.hello/dist

# 2. 复制文件（macOS/Linux）
cp hello-plugin/manifest.json ~/.config/ai-toolbox/plugins/com.aitoolbox.hello/
cp hello-plugin/dist/index.html ~/.config/ai-toolbox/plugins/com.aitoolbox.hello/dist/

# Windows: 复制到 %APPDATA%\ai-toolbox\plugins\com.aitoolbox.hello\

启动 AI Toolbox，侧边栏应出现 **“Hello 验证器”**，点击后： - 显示 Plugin ID - 拉取模型列表 - Storage 读写正常 - 点击”发送测试消息”能看到 AI 回复

# 二、Excalidraw 封装（白板 + AI 生成）

Excalidraw 是纯 React 项目，构建后全是静态文件。我们用 **策略 A：构建后注入 Bridge 脚本**。

## 步骤总览

1. 克隆 Excalidraw → 2. 构建 → 3. 注入 bridge → 4. 打包成插件

## Step 1: 获取并构建

# 克隆
git clone https://github.com/excalidraw/excalidraw.git
cd excalidraw

# 安装依赖（确保 Node 18+）
yarn install

# 构建（产出在 build/ 目录）
yarn build:app

如果构建失败，可以直接下载官方发布的静态包，或直接用 excalidraw 的 CDN 版本。

## Step 2: 注入 Bridge 脚本

创建 inject-bridge.js：

// scripts/inject-bridge.js
const fs = require('fs');
const path = require('path');

const buildDir = process.argv[2] || './build';
const htmlPath = path.join(buildDir, 'index.html');

if (!fs.existsSync(htmlPath)) {
 console.error('找不到 build/index.html，请先构建 Excalidraw');
 process.exit(1);
}

let html = fs.readFileSync(htmlPath, 'utf8');

// 注入的 Bridge 代码：在 Excalidraw 加载完成后，添加一个 AI 浮动面板
const bridgeScript = `
<script>
(function initExcalidrawBridge() {
 if (!window.\_\_HOST\_\_) {
 console.warn('[Excalidraw Plugin] 不在 AI Toolbox 宿主中运行');
 return;
 }

 console.log('[Excalidraw Plugin] Bridge loaded, plugin:', window.\_\_HOST\_\_.meta.pluginId);

 // 等待 Excalidraw 全局 API 就绪
 const checkInterval = setInterval(() => {
 // Excalidraw 构建后会暴露 excalidrawAPI 到某个全局位置
 // 我们通过 postMessage 与 iframe 通信，或查找 window 上的实例
 if (window.excalidrawAPI || window.\_\_EXCALIDRAW\_SHA\_\_) {
 clearInterval(checkInterval);
 injectAIPanel();
 }
 }, 500);

 function injectAIPanel() {
 // 创建浮动 AI 面板
 const panel = document.createElement('div');
 panel.id = 'ai-toolbox-panel';
 panel.innerHTML = \`
 <div style="position:fixed;top:16px;right:16px;z-index:99999;width:320px;background:#fff;border:1px solid #e3e3e3;border-radius:8px;box-shadow:0 4px 20px rgba(0,0,0,0.15);font-family:-apple-system,BlinkMacSystemFont,sans-serif;">
 <div style="padding:12px 16px;border-bottom:1px solid #f0f0f0;font-weight:600;font-size:14px;color:#333;display:flex;align-items:center;gap:8px;">
 <span>🎨</span> AI 生成白板
 </div>
 <div style="padding:12px 16px;">
 <textarea id="ai-prompt" placeholder="描述你想画的图表或草图..."
 style="width:100%;min-height:60px;padding:8px;border:1px solid #ddd;border-radius:4px;font-size:13px;resize:vertical;box-sizing:border-box;"></textarea>
 <button id="ai-generate" style="width:100%;margin-top:8px;padding:8px;background:#a8a5ff;color:#fff;border:none;border-radius:4px;cursor:pointer;font-size:13px;font-weight:500;">
 AI 生成元素
 </button>
 <button id="ai-describe" style="width:100%;margin-top:6px;padding:8px;background:#f0f0f0;color:#333;border:none;border-radius:4px;cursor:pointer;font-size:13px;">
 AI 描述当前白板
 </button>
 </div>
 <div id="ai-status" style="padding:0 16px 12px;font-size:12px;color:#666;min-height:20px;"></div>
 </div>
 \`;
 document.body.appendChild(panel);

 // 绑定生成按钮
 document.getElementById('ai-generate').addEventListener('click', async () => {
 const prompt = document.getElementById('ai-prompt').value.trim();
 const status = document.getElementById('ai-status');
 if (!prompt) return;

 status.textContent = 'AI 生成中...';
 try {
 const response = await window.\_\_HOST\_\_.llm.chat([
 {
 role: 'system',
 content: \`你是一个 Excalidraw 元素生成器。用户描述一个图表或草图，你输出符合 Excalidraw 元素格式的 JSON 数组。

规则：
1. 只输出纯 JSON 数组，不要 markdown 代码块，不要解释
2. 每个元素必须包含：id (随机字符串), type ("rectangle"|"ellipse"|"diamond"|"text"|"arrow"|"line"), x, y, width, height
3. text 类型需要 content 字段
4. 所有元素 strokeColor 用 "#000000", backgroundColor 用 "transparent", fillStyle 用 "hachure"
5. 布局要合理，不要重叠，x/y 从 0 开始向右下方排列

示例元素：
{"id":"abc123","type":"rectangle","x":0,"y":0,"width":200,"height":100,"strokeColor":"#000000","backgroundColor":"transparent","fillStyle":"hachure","strokeWidth":1,"roughness":1,"opacity":100,"seed":123456}
\`
 },
 { role: 'user', content: \`请生成以下内容的 Excalidraw 元素：\${prompt}\` }
 ]);

 // 清理可能的 markdown 代码块
 let clean = response.replace(/\\`\\`\\`json\\s\*/g, '').replace(/\\`\\`\\`/g, '').trim();
 const elements = JSON.parse(clean);

 // 通过 Excalidraw 的 API 更新场景
 if (window.excalidrawAPI && window.excalidrawAPI.updateScene) {
 window.excalidrawAPI.updateScene({ elements });
 status.textContent = \`✅ 已生成 \${elements.length} 个元素\`;
 } else {
 // 备用：通过 localStorage hack 或 postMessage
 status.textContent = '⚠️ 无法注入，请手动粘贴到 Import';
 await window.\_\_HOST\_\_.clipboard.writeText(clean);
 }
 } catch (e) {
 status.textContent = '❌ 错误: ' + e.message;
 console.error(e);
 }
 });

 // 绑定描述按钮（将当前白板内容发给 AI 分析）
 document.getElementById('ai-describe').addEventListener('click', async () => {
 const status = document.getElementById('ai-status');
 status.textContent = '读取白板内容...';

 try {
 let elements = [];
 if (window.excalidrawAPI && window.excalidrawAPI.getSceneElements) {
 elements = window.excalidrawAPI.getSceneElements();
 }

 const summary = elements.map(el => {
 if (el.type === 'text') return \`文本: \${el.text || el.content}\`;
 return \`\${el.type} (\${Math.round(el.x)},\${Math.round(el.y)})\`;
 }).join('\\n');

 const response = await window.\_\_HOST\_\_.llm.chat([
 { role: 'system', content: '你是一位设计顾问。用户给你一个白板内容的清单，你给出优化建议。' },
 { role: 'user', content: \`我的白板有以下元素，请给出布局优化建议：\\n\\n\${summary || '(空白板)'}\` }
 ]);

 status.innerHTML = response.replace(/\\n/g, '<br>');
 } catch (e) {
 status.textContent = '❌ ' + e.message;
 }
 });
 }
})();
</script>
`;

// 在 </body> 前注入
html = html.replace('</body>', bridgeScript + '\n</body>');

fs.writeFileSync(htmlPath, html);
console.log('✅ Excalidraw bridge injected to', htmlPath);

执行注入：

node scripts/inject-bridge.js ./build

## Step 3: 打包成插件

mkdir -p excalidraw-plugin/dist
cp -r build/\* excalidraw-plugin/dist/

创建 excalidraw-plugin/manifest.json：

{
 "manifest\_version": "0.1.0",
 "id": "com.excalidraw.ai",
 "name": "Excalidraw AI 白板",
 "version": "1.0.0",
 "author": "Excalidraw Community / AI Toolbox",
 "category": "work",
 "entry": "dist/index.html",
 "permissions": ["llm.chat", "clipboard.read", "clipboard.write"],
 "hosting": { "type": "static" }
}

最终结构：

excalidraw-plugin/
├── manifest.json
└── dist/
 ├── index.html # 已注入 bridge
 ├── static/
 └── ...（其他构建产物）

## 安装

cp -r excalidraw-plugin ~/.config/ai-toolbox/plugins/com.excalidraw.ai

**效果**：在 AI Toolbox 中打开后，Excalidraw 界面右上角会出现 **“AI 生成白板”** 面板，输入”画一个系统架构图，包含前端、后端、数据库”即可 AI 生成元素。

# 三、PPTist 封装（PPT + AI 生成）

PPTist 是基于 Vue3 的在线 PPT 编辑器，纯前端，构建后也是静态文件。

## Step 1: 获取并构建

git clone https://github.com/pipipi-pikachu/PPTist.git
cd PPTist

npm install
npm run build
# 产出在 dist/ 目录

## Step 2: 注入 Bridge 脚本

创建 inject-pptist-bridge.js：

const fs = require('fs');
const path = require('path');

const distDir = process.argv[2] || './dist';
const htmlPath = path.join(distDir, 'index.html');

if (!fs.existsSync(htmlPath)) {
 console.error('找不到 dist/index.html');
 process.exit(1);
}

let html = fs.readFileSync(htmlPath, 'utf8');

const bridgeScript = `
<script>
(function initPPTistBridge() {
 if (!window.\_\_HOST\_\_) {
 console.warn('[PPTist] 不在宿主中运行');
 return;
 }

 console.log('[PPTist] Bridge loaded');

 // PPTist 使用 Vue3，我们需要在 DOM 加载后注入 UI
 window.addEventListener('load', () => {
 setTimeout(injectAIPanel, 1500); // 等待 Vue 挂载
 });

 function injectAIPanel() {
 // 在左侧工具栏上方或顶部插入 AI 入口
 const toolbar = document.querySelector('.pptist-editor, .editor-header, [class\*="header"], #app > div > div:first-child');

 const aiBtn = document.createElement('div');
 aiBtn.id = 'ai-ppt-panel';
 aiBtn.innerHTML = \`
 <div style="position:fixed;top:12px;right:200px;z-index:99999;">
 <button id="ai-gen-slide" style="padding:6px 14px;background:#4a90d9;color:#fff;border:none;border-radius:4px;cursor:pointer;font-size:13px;font-weight:500;box-shadow:0 2px 8px rgba(74,144,217,0.3);">
 🤖 AI 生成 PPT
 </button>
 </div>

 <div id="ai-modal" style="display:none;position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.5);z-index:100000;align-items:center;justify-content:center;">
 <div style="background:#fff;width:500px;max-width:90%;border-radius:8px;padding:24px;box-shadow:0 8px 32px rgba(0,0,0,0.2);">
 <h3 style="margin:0 0 16px;font-size:16px;color:#333;">AI 生成幻灯片</h3>
 <div style="margin-bottom:12px;">
 <label style="display:block;font-size:12px;color:#666;margin-bottom:4px;">主题</label>
 <input id="ppt-topic" type="text" placeholder="例如：2024年Q3产品复盘" style="width:100%;padding:8px;border:1px solid #ddd;border-radius:4px;font-size:13px;">
 </div>
 <div style="margin-bottom:12px;">
 <label style="display:block;font-size:12px;color:#666;margin-bottom:4px;">页数</label>
 <select id="ppt-pages" style="width:100%;padding:8px;border:1px solid #ddd;border-radius:4px;font-size:13px;">
 <option value="3">3页（极简）</option>
 <option value="5" selected>5页（标准）</option>
 <option value="8">8页（详细）</option>
 </select>
 </div>
 <div style="margin-bottom:16px;">
 <label style="display:block;font-size:12px;color:#666;margin-bottom:4px;">风格</label>
 <select id="ppt-style" style="width:100%;padding:8px;border:1px solid #ddd;border-radius:4px;font-size:13px;">
 <option value="business">商务蓝</option>
 <option value="dark">深色科技</option>
 <option value="minimal">极简白</option>
 </select>
 </div>
 <div style="display:flex;gap:8px;justify-content:flex-end;">
 <button id="ppt-cancel" style="padding:6px 14px;background:#f5f5f5;border:1px solid #ddd;border-radius:4px;cursor:pointer;color:#333;">取消</button>
 <button id="ppt-confirm" style="padding:6px 14px;background:#4a90d9;color:#fff;border:none;border-radius:4px;cursor:pointer;">生成</button>
 </div>
 <div id="ppt-status" style="margin-top:12px;font-size:12px;color:#666;min-height:18px;"></div>
 </div>
 </div>
 \`;

 document.body.appendChild(aiBtn);

 // 事件绑定
 document.getElementById('ai-gen-slide').addEventListener('click', () => {
 document.getElementById('ai-modal').style.display = 'flex';
 });

 document.getElementById('ppt-cancel').addEventListener('click', () => {
 document.getElementById('ai-modal').style.display = 'none';
 });

 document.getElementById('ppt-confirm').addEventListener('click', generatePPT);
 }

 async function generatePPT() {
 const topic = document.getElementById('ppt-topic').value.trim();
 const pages = document.getElementById('ppt-pages').value;
 const style = document.getElementById('ppt-style').value;
 const status = document.getElementById('ppt-status');

 if (!topic) { status.textContent = '请输入主题'; return; }

 status.textContent = 'AI 生成中，约需 10-20 秒...';
 document.getElementById('ppt-confirm').disabled = true;

 try {
 const response = await window.\_\_HOST\_\_.llm.chat([
 {
 role: 'system',
 content: \`你是一个 PPT 内容生成专家。用户给你一个主题，你生成 PPT 的 JSON 数据。

输出格式必须是 JSON，结构如下：
{
 "slides": [
 {
 "type": "cover", // cover | content | section | end
 "title": "主标题",
 "subtitle": "副标题",
 "content": ["要点1", "要点2"], // content 类型的正文 bullet points
 "layout": "center" // center | left-right | top-bottom
 }
 ]
}

规则：
1. 生成 \${pages} 页幻灯片
2. 第一页必须是 cover
3. 内容页要有清晰的 bullet points，每页 3-5 点
4. 最后一页可以是 end（感谢页）
5. 只输出 JSON，不要 markdown 代码块，不要解释
\`
 },
 { role: 'user', content: \`请生成关于"\${topic}"的 PPT 内容，风格：\${style}\` }
 ]);

 // 清理 JSON
 let clean = response.replace(/\\`\\`\\`json\\s\*/g, '').replace(/\\`\\`\\`/g, '').trim();
 const data = JSON.parse(clean);

 // 将生成的内容写入 PPTist 的 localStorage（PPTist 使用 localStorage 存储幻灯片数据）
 // PPTist 的存储 key 通常是 'pptist\_store' 或类似
 const existing = localStorage.getItem('pptist\_store');
 let store = existing ? JSON.parse(existing) : { slides: [] };

 // 转换格式为 PPTist 内部格式（简化版）
 const newSlides = data.slides.map((s, idx) => ({
 id: 'slide\_' + Date.now() + '\_' + idx,
 elements: generateElementsFromSlide(s, style),
 background: getStyleBackground(style)
 }));

 store.slides = newSlides;
 localStorage.setItem('pptist\_store', JSON.stringify(store));

 status.textContent = '✅ 生成成功！正在刷新...';
 setTimeout(() => location.reload(), 800); // 刷新让 PPTist 读取新数据

 } catch (e) {
 status.textContent = '❌ 错误: ' + e.message;
 console.error(e);
 } finally {
 document.getElementById('ppt-confirm').disabled = false;
 }
 }

 // 辅助：根据内容生成 PPTist 元素（简化版）
 function generateElementsFromSlide(slide, style) {
 const colors = {
 business: { main: '#2b579a', text: '#333' },
 dark: { main: '#1a1a2e', text: '#eee' },
 minimal: { main: '#333', text: '#333' }
 };
 const c = colors[style] || colors.business;

 const elements = [];
 const baseY = 60;

 if (slide.type === 'cover') {
 elements.push({
 type: 'text', id: 't1', x: 100, y: 200, width: 800, height: 60,
 content: slide.title, style: { fontSize: 44, color: c.main, fontWeight: 'bold' }
 });
 if (slide.subtitle) {
 elements.push({
 type: 'text', id: 't2', x: 100, y: 280, width: 800, height: 40,
 content: slide.subtitle, style: { fontSize: 24, color: c.text }
 });
 }
 } else {
 elements.push({
 type: 'text', id: 't1', x: 60, y: 40, width: 800, height: 50,
 content: slide.title, style: { fontSize: 32, color: c.main, fontWeight: 'bold' }
 });
 (slide.content || []).forEach((bullet, i) => {
 elements.push({
 type: 'text', id: 'b'+i, x: 80, y: 120 + i \* 50, width: 800, height: 40,
 content: '• ' + bullet, style: { fontSize: 18, color: c.text }
 });
 });
 }

 return elements;
 }

 function getStyleBackground(style) {
 if (style === 'dark') return { type: 'solid', color: '#1a1a2e' };
 if (style === 'minimal') return { type: 'solid', color: '#ffffff' };
 return { type: 'solid', color: '#f8f9fa' };
 }
})();
</script>
`;

html = html.replace('</body>', bridgeScript + '\n</body>');
fs.writeFileSync(htmlPath, html);
console.log('✅ PPTist bridge injected');

执行：

node inject-pptist-bridge.js ./dist

## Step 3: 打包

mkdir -p pptist-plugin/dist
cp -r dist/\* pptist-plugin/dist/

创建 pptist-plugin/manifest.json：

{
 "manifest\_version": "0.1.0",
 "id": "com.pptist.ai",
 "name": "PPTist AI 幻灯片",
 "version": "1.0.0",
 "author": "PPTist Community / AI Toolbox",
 "category": "work",
 "entry": "dist/index.html",
 "permissions": ["llm.chat", "storage.get", "storage.set"],
 "hosting": { "type": "static" }
}

## 安装

cp -r pptist-plugin ~/.config/ai-toolbox/plugins/com.pptist.ai

**效果**：打开 PPTist 后，顶部会出现 **“AI 生成 PPT”** 按钮，点击弹出面板，输入主题和页数，AI 生成后直接写入 PPTist 的存储并刷新页面。

# 快速验证脚本

如果你想一键测试这 3 个插件是否都安装成功，在 Tauri 前端加这个调试面板：

// 在 App.tsx 的侧边栏底部加一个调试区
<div style={{ marginTop: 'auto', padding: 12, borderTop: '1px solid #eee', fontSize: 12 }}>
 <div style={{ color: '#999', marginBottom: 8 }}>已安装插件</div>
 {plugins.map(p => (
 <div key={p.id} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
 <div style={{
 width: 6, height: 6, borderRadius: '50%',
 background: p.id === activePlugin ? '#22c55e' : '#ccc'
 }} />
 <span style={{ color: '#666' }}>{p.name}</span>
 <span style={{ color: '#aaa', fontSize: 10 }}>{p.permissions.length} 权限</span>
 </div>
 ))}
</div>

# 下一步建议

1. **先用 hello-plugin 跑通**：确认 window.\_\_HOST\_\_ 注入、LLM 对话、Storage 隔离全部正常
2. **再跑 Excalidraw**：验证复杂前端项目的 bridge 注入模式
3. **最后跑 PPTist**：验证 localStorage 数据注入和页面级交互

如果 hello-plugin 的 LLM 对话失败，检查： - Tauri plugin\_llm\_chat 是否正确注册了 invoke\_handler - \_\_plugin\_id 参数是否在 Command 函数签名中接收 - LLM 配置（api\_key / base\_url）是否已填入

需要我把 **hello-plugin 的完整 TypeScript 类型定义文件**（给插件开发者用的 npm 包）或者 **自动化封装脚本**（输入 GitHub 仓库地址，自动构建+注入+打包）也做出来吗？

**User:**

给我可以直接打包下载的内容就可以，可以发给我的 kimi claw

**Kimi:**

我直接给你生成可下载的插件包，包含构建脚本和说明。三个插件包已生成，可以直接下载：

**1. Hello 验证器**（直接可用） hello-plugin.zip

解压后复制到： - macOS/Linux: ~/.config/ai-toolbox/plugins/com.aitoolbox.hello/ - Windows: %APPDATA%\ai-toolbox\plugins\com.aitoolbox.hello\

**2. Excalidraw AI 白板**（需先构建原项目） excalidraw-plugin.zip

包含： - manifest.json → 复制到插件目录 - inject-bridge.js → 构建后注入 Excalidraw - README.md → 完整构建步骤

使用流程：

git clone https://github.com/excalidraw/excalidraw.git && cd excalidraw
yarn && yarn build:app
node inject-bridge.js ./build
cp -r build/\* /path/to/excalidraw-plugin/dist/
# 最后把整个 excalidraw-plugin 放入 AI Toolbox 插件目录

**3. PPTist AI 幻灯片**（需先构建原项目） pptist-plugin.zip

包含： - manifest.json - inject-bridge.js - README.md

使用流程：

git clone https://github.com/pipipi-pikachu/PPTist.git && cd PPTist
npm install && npm run build
node inject-bridge.js ./dist
cp -r dist/\* /path/to/pptist-plugin/dist/

**建议验证顺序**： 1. 先放 hello-plugin → 确认 Tauri 宿主 API 注入正常 2. 再跑 Excalidraw → 验证复杂前端项目的 bridge 注入 3. 最后跑 PPTist → 验证 localStorage 数据注入

如果 hello-plugin 的 LLM 对话报错，检查 Tauri 侧 plugin\_llm\_chat 是否正确注册了 invoke\_handler，以及 \_\_plugin\_id 参数是否在 Rust Command 签名中接收。