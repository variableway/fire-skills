# golang-cli-app Skill

Go CLI 应用开发技能 - 提供 Cobra/Viper/PTerm/Bubble Tea 的代码示例、项目模板和最佳实践。

## 技术栈

| 层 | 技术 | 用途 |
|---|------|------|
| CLI 框架 | Cobra | 命令定义、子命令、flag |
| 配置 | Viper | YAML/ENV/flag 配置绑定 |
| TUI (基础) | PTerm | 彩色输出、表格、Spinner |
| TUI (交互) | Bubble Tea | 交互式选择器、确认对话框 |
| 测试 | Ginkgo/Gomega | BDD 风格测试 |

## 快速开始

```bash
# 安装到当前项目
./scripts/install.sh --project

# 安装到系统级
./scripts/install.sh --system
```

## 内容

| 文件 | 说明 |
|------|------|
| [SKILL.md](SKILL.md) | 完整技能定义和代码示例 |
| [references/tui-patterns.md](references/tui-patterns.md) | TUI 模式参考 |
| [references/subcommand-rules.md](references/subcommand-rules.md) | 子命令设计规范 |
| [scripts/install.sh](scripts/install.sh) | macOS/Linux 安装脚本 |
| [scripts/install.ps1](scripts/install.ps1) | Windows 安装脚本 |

## 参考项目

- [spark-cli](https://github.com/variableway/spark-cli) - 本技能的源项目
- [Cobra 官方文档](https://cobra.dev/)
- [Bubble Tea 教程](https://github.com/charmbracelet/bubbletea#tutorial)
- [PTerm 示例](https://github.com/pterm/pterm#examples)
