# skill-spark 安装与运行指南

本文档说明如何从源码安装和运行 **skill-spark** —— 一个通用的 AI 编码助手 Skill 管理工具（Universal skill manager for AI coding agents）。

---

## 前置依赖

在构建和运行 skill-spark 之前，请确保你的环境已满足以下条件：

| 依赖 | 版本要求 | 说明 |
|------|---------|------|
| [Node.js](https://nodejs.org/) | ≥ 18.x | 运行时基础（Bun 内置兼容） |
| [Bun](https://bun.sh/) | 最新稳定版 | 构建工具与运行时，用于执行 `bun run build` |
| [pnpm](https://pnpm.io/) | 11.12.0 | 包管理器（仓库根目录 `package.json` 中已锁定） |
| Git | 任意较新版本 | 克隆仓库及 Skill 安装源管理 |

> **提示**：建议通过 `corepack enable` 或 `npm install -g pnpm@11.12.0` 安装 pnpm，以确保与仓库锁定的版本一致。

### 快速检查依赖

```bash
node --version   # 应输出 v18.x 或更高
bun --version    # 应输出 1.x
pnpm --version   # 应输出 11.12.0
git --version
```

---

## 从源码安装步骤

### 1. 克隆仓库

```bash
git clone https://github.com/variableway/fire-skills.git
cd fire-skills
```

### 2. 安装依赖

```bash
pnpm install
```

> 若未安装 pnpm，也可先用 `bun install` 或 `npm install` 临时替代，但推荐统一使用 pnpm 以避免 `pnpm-lock.yaml` 冲突。

---

## 构建命令

skill-spark 提供两种构建方式：生成可执行的 JS 入口文件，或编译为独立二进制文件。

### 构建 JS 入口（默认）

```bash
bun run build
```

执行后会在 `./dist/index.js` 生成入口文件，并已自动赋予可执行权限（`chmod +x`）。该文件可通过以下方式运行：

```bash
node ./dist/index.js --help
```

### 构建独立二进制文件

```bash
bun run build:exe
```

执行后会在 `./dist/skill-spark` 生成不依赖外部运行时 的独立可执行文件。推荐用于全局安装或分发场景。

### 一次性构建全部

```bash
bun run build:all
```

等价于先后执行 `bun run build` 和 `bun run build:exe`。

### 构建并安装到用户 PATH

```bash
bun run build:install
# 等价于 ./scripts/build-install.sh
```

会执行 `build:all`，并将可执行文件安装到 `~/.local/bin/skill-spark`（需该目录在 PATH 中）。

### 其他常用脚本

| 命令 | 作用 |
|------|------|
| `bun run build:install` | 构建并安装到 `~/.local/bin` |
| `bun run dev` | 直接以开发模式运行源码（不构建） |
| `bun run typecheck` | 运行 TypeScript 类型检查（无 emit） |
| `bun run format` | 使用 Biome 格式化代码 |
| `bun run lint` | 使用 Biome 检查代码风格 |
| `bun run check` | Biome 综合检查（格式 + 风格） |

---

## 全局安装与本地运行方式

### 方式一：本地运行（不安装到系统 PATH）

构建完成后，可直接通过相对路径调用：

```bash
# 使用 Node.js 运行构建产物
node ./dist/index.js --help

# 或使用 wrapper 脚本（自动查找构建产物）
./scripts/install.sh --help
```

### 方式二：全局安装（推荐）

若已构建独立二进制文件，可将其复制到系统 PATH：

```bash
# macOS / Linux
sudo cp ./dist/skill-spark /usr/local/bin/

# 或复制到用户级 bin 目录
mkdir -p ~/.local/bin
cp ./dist/skill-spark ~/.local/bin/
# 确保 ~/.local/bin 已加入 PATH
```

全局安装后，即可在任意目录直接使用：

```bash
skill-spark --help
```

### 方式三：通过 `npm link` / `pnpm link` 全局链接

```bash
# 在仓库根目录执行
pnpm link --global

# 或针对已构建的 bin 链接
ln -s "$(pwd)/dist/index.js" /usr/local/bin/skill-spark
```

---

## CLI 基本使用示例

### 查看帮助与版本

```bash
skill-spark --help
skill-spark --version
```

### 常用命令速览

```bash
# 搜索 Skill
skill-spark search git

# 从本地目录安装 Skill（当前项目）
skill-spark add skills/devops

# 从本地目录全局安装
skill-spark add skills/devops --global

# 安装指定 Skill 到指定 Agent
skill-spark add skills/devops --agent codex

# 列出已安装的 Skill
skill-spark list

# 检查是否有更新
skill-spark outdated

# 更新全部 Skill
skill-spark update

# 移除指定 Skill
skill-spark remove git-workflow

# 诊断环境
skill-spark doctor
```

### 安装脚本 Wrapper

仓库在 `scripts/` 目录下提供了封装脚本，便于不熟悉 CLI 参数的用户使用：

```bash
# 安装（add 的封装）
./scripts/install.sh skills/devops --system

# 移除（remove 的封装）
./scripts/remove.sh git-workflow

# 更新（update 的封装）
./scripts/update.sh
```

> 这些脚本会自动检测 `skill-spark` 是否在 PATH 中，若未找到，则回退到 `node ./dist/index.js` 或 `bun run src/index.ts`。

---

## 验证安装成功的方法

### 1. 检查命令可用性

```bash
which skill-spark        # 应输出二进制路径
skill-spark --version    # 应输出版本号，如 0.1.0
```

### 2. 检查帮助信息

```bash
skill-spark --help
```

正常输出应包含以下一级命令：`search`、`add`、`update`、`outdated`、`remove`、`list`、`validate`、`inspect`、`use`、`profile`、`map`、`sync`、`agent`、`doctor`。

### 3. 运行环境诊断

```bash
skill-spark doctor
```

该命令会检查：
- 配置目录是否存在（`~/.skill-spark/`）
- Agent 目录映射状态
- 已安装 Skill 的完整性
- 依赖项缺失警告

### 4. 测试基本功能

```bash
# 应输出已安装 Skill 列表（初次为空也是正常）
skill-spark list

# 应输出当前追踪 Skill 的更新状态
skill-spark outdated
```

若以上命令均返回预期结果且无报错，则表明 skill-spark 已成功安装并可正常运行。

---

## 常见问题

| 问题 | 排查方法 |
|------|---------|
| `skill-spark: command not found` | 先执行 `bun run build`，或将 `./dist` 加入 PATH |
| `bun: command not found` | 安装 Bun：`curl -fsSL https://bun.sh/install \| bash` |
| 构建失败 / 类型错误 | 运行 `bun run typecheck` 查看详细错误；确认 `pnpm install` 已执行 |
| 脚本提示找不到 skill-spark | 确认已执行 `bun run build` 生成 `./dist/index.js` |

---

## 相关资源

- 仓库地址：https://github.com/variableway/fire-skills
- [概述与架构](./overview.md)
- [通用 Skill 安装指南](../install-skills.md)
- [DevOps Skills 安装](../usage/install-devops-skills.md)
- [项目架构与 MVP](../projects/architecture-and-mvp.md)
- Bun 官方文档：https://bun.sh/docs
- pnpm 官方文档：https://pnpm.io/installation
