# 使用 Skill Spark CLI 搜索 GitHub Workflow 技能

本指南演示如何使用 `skill-spark` 搜索与 GitHub workflow 相关的主题技能。

## 前置条件

- 安装 [Bun](https://bun.sh) 运行时
- `skill-spark` CLI 可用（优先在项目根目录执行 `./dist/skill-spark`；如不存在先运行 `bun run build:all`）

## 基础搜索

搜索匹配 "github workflow" 关键词的技能。结果会同时从两个数据源合并获取：skills 注册表（`skillsdirectory.com`）和 flins 目录：

```bash
./dist/skill-spark search "github workflow"
```

输出示例：

```
Found 10 skills (registry: 10)
  Github Automation ...
  Github Workflow Automation ...
  ...
```

## 高级搜索选项

### 按分类筛选

缩小到特定分类（如 `devops`、`development`、`tools`）：

```bash
./dist/skill-spark search "github workflow" --category devops
```

### 控制结果数量

调整每页结果数量（最大 100）：

```bash
./dist/skill-spark search "github workflow" --limit 10
```

### 分页浏览

使用 `--offset` 进行分页：

```bash
./dist/skill-spark search "github workflow" --limit 5 --offset 10
```

### 排序结果

按不同条件排序：

```bash
# 按星标数排序（最多）
./dist/skill-spark search "github workflow" --sort stars

# 按最新排序
./dist/skill-spark search "github workflow" --sort recent

# 按投票排序
./dist/skill-spark search "github workflow" --sort votes
```

### 组合多个选项

```bash
./dist/skill-spark search "github workflow" \
  --category devops \
  --limit 10 \
  --sort stars
```

### 使用自定义注册表

覆盖默认注册表 URL：

```bash
./dist/skill-spark search "github workflow" --registry https://custom.registry.com/api
```

或通过环境变量设置：

```bash
export FIRE_SKILL_REGISTRY_URL="https://custom.registry.com/api"
./dist/skill-spark search "github workflow"
```

## 保存结果到文件

将搜索结果导出为 JSON 文件：

```bash
./dist/skill-spark search "github workflow" -o results.json
./dist/skill-spark search "github workflow" --limit 5 --sort stars -o /tmp/output.json
```

输出文件结构：

```json
{
  "query": "github workflow",
  "registry": 3,
  "directory": 0,
  "total": 3,
  "skills": [
    {
      "schemaVersion": "1",
      "slug": "ruvnet-github-automation",
      "name": "Github Automation",
      "description": "GitHub workflow automation, PR management...",
      "repository": "ruvnet/ruflo",
      "stars": 55216,
      "tags": ["bash", "code-review", "git", "ci/cd"],
      "author": { "name": "ruvnet" }
    }
  ]
}
```

## 交互式浏览模式

不提供查询字符串即可进入交互式 TUI 浏览模式，可过滤并多选技能进行安装：

```bash
./dist/skill-spark search
```

使用方向键导航，输入进行过滤，空格键选择/取消选择，回车键安装选中技能。

## 相关搜索查询

要更全面覆盖 GitHub workflow 主题，尝试以下查询：

```bash
# CI/CD pipeline 技能
./dist/skill-spark search "ci cd pipeline"

# GitHub Actions 技能
./dist/skill-spark search "github actions"

# DevOps 自动化技能
./dist/skill-spark search "devops automation"

# 部署工作流技能
./dist/skill-spark search "deployment workflow"
```
