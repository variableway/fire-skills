# list — List Installed Skills

列出已安装的技能和命令。

## 别名

`l`

## 语法

```
skill-spark list
```

无参数。从 `skills.lock` 读取所有已追踪的安装记录，按 scope 分组显示。

## 输出示例

```
◆  Project
│    ◇  skill:git-workflow
│    ◇  skill:github-cli
│
◆  Global
│    ◇  skill:scanning-for-secrets
```
