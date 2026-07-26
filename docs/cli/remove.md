# remove — Remove Skills

删除已安装的技能。

## 别名

`r`, `rm`, `uninstall`

## 语法

```
skill-spark remove [skills...] [-g] [-f]
```

## 选项

| 选项 | 说明 |
|------|------|
| `-g, --global` | 仅删除全局 scope 的技能 |
| `-f, --force` | 跳过确认提示 |

## 用法

### 删除全部技能

```bash
# 删除所有 scope 的全部技能
skill-spark remove

# 仅删除全局技能
skill-spark remove -g

# 跳过确认
skill-spark remove -f
```

### 删除指定技能

```bash
# 删除指定技能（所有 scope）
skill-spark remove my-skill

# 删除指定技能（仅全局）
skill-spark remove my-skill -g

# 一次删除多个
skill-spark remove git-workflow github-cli -f
```

## 工作流程

1. 从 `skills.lock` 读取已安装的技能列表
2. 按 scope（project/global）和名称筛选
3. 显示待删除列表，确认后执行
4. 遍历所有 Agent 目录删除对应文件
5. 清理 `skills.lock` 中的追踪记录

## 输出示例

```
◇  Found 3 items to remove (all scopes).
│    skill:git-workflow [project]
│    skill:github-cli [project]
│    skill:git-workflow [global]
│
◇  Remove 3 items?
│  Yes
│
✔ Removed skill:git-workflow [project]
✔ Removed skill:github-cli [project]
✔ Removed skill:git-workflow [global]
│
└  Removed 3 items
```
