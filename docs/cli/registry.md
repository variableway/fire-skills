# registry

扫描 git 仓、合并进 YAML 登记表、按登记表 clone / pull。

路径全部来自配置（`.innate-registry-cli.yaml` 或 `registry-cli.yaml`），不写死在代码里。换项目时复制一份配置改字段即可。

## 命令

| 命令 | 登记表 | 扫描目录 |
| --- | --- | --- |
| `registry scan [dirs...]` | 配置里的 `registry`（相对 hub） | 参数，或配置 `scanDirs` |
| `registry clone` | 同上 | 按条目 `path` 落到 works / apps |
| `registry scan-refs [dirs...]` | 配置里的 `refsRegistry`（相对 works） | 参数，或配置 `refsScanDirs` |
| `registry clone-refs` | 同上 | 同上 |

```bash
skill-spark registry scan                 # 用配置里的 scanDirs
skill-spark registry scan base skills     # 只扫指定目录
skill-spark registry clone                # clone / pull 登记表里的所有项目
skill-spark registry scan-refs
skill-spark registry clone-refs
```

## 选项

`scan` / `scan-refs`：

| 选项 | 作用 |
| --- | --- |
| `--depth <n>` | 递归深度（1 = 只扫直接子目录，0 = 不限）。默认 3 |
| `--keep-missing` | 目录消失时保留登记表里的行，不删除 |
| `--regenerate` | 按磁盘重建登记表，丢弃额外字段 |

`scan` / `scan-refs` / `clone` / `clone-refs` 都支持：

| 选项 | 环境变量 | 作用 |
| --- | --- | --- |
| `--config <path>` | `REGISTRY_CLI_CONFIG` | 指定配置文件 |
| `--hub-root <path>` | `REGISTRY_CLI_HUB_ROOT` | hub 仓根目录 |
| `--works-root <path>` | `REGISTRY_CLI_WORKS_ROOT` | 克隆 / 扫描的根目录 |
| `--works-name <name>` | `REGISTRY_CLI_WORKS_NAME` | 未给 worksRoot 时按目录名向上找 |
| `--apps-root <path>` | `REGISTRY_CLI_APPS_ROOT` | 已拆出去的 apps 树 |
| `--apps-prefix <name>` | — | YAML 里映射到 appsRoot 的路径前缀 |
| `--registry <path>` | — | 覆盖登记表路径 |

## 配置文件

向上最多 8 层查找 `.innate-registry-cli.yaml`，其次 `registry-cli.yaml`。

| 字段 | 作用 |
| --- | --- |
| `worksRoot` / `worksName` | 克隆与扫描的根目录 |
| `appsRoot` / `appsPrefix` | 外置 apps 树及其路径前缀 |
| `registry` / `refsRegistry` | hub 侧 / works 侧登记表 |
| `scanDirs` / `refsScanDirs` | 默认扫描目录 |
| `sectionSecondOnly` / `sectionKeepPrefix` | 登记表分组规则 |
| `defaultDescBySection` | 新条目缺 `desc` 时的默认值 |
| `ignoreDirs` | 扫描时跳过的目录名 |

登记表里的 `path` 决定落盘位置：

- 以 `appsPrefix` 开头 → 落到 `appsRoot`
- 以 hub 目录名（`hubRoot` 的 basename）开头 → 落到 `hubRoot`，`path` 保留 hub 名前缀
- 其余 → 落到 `worksRoot`

## 结构

```text
packages/skill-cli/src/commands/registry/
  index.ts     # 子命令注册
  config/      # 读配置、解析 hub / works / apps
  git/         # git 原语 + clone / pull
  scan/        # 扫描目录、merge、写回
  store/       # YAML 登记表读写
```

```bash
bun test packages/skill-cli/src/commands/registry
```
