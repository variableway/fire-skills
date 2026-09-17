# selfhost

把自建 SMB 网盘接到 macOS 命令行。多套主机写在一份 `config.json` 里；**唯一环境变量**是 `SELFHOST_CLI_PASSWORD`（仅 `via: smbfs` 需要）。密码不要写进 json。

## 命令

| 命令 | 作用 |
| --- | --- |
| `selfhost profiles` | 列出 json 里的配置 |
| `selfhost open` | `open smb://user@host/share`，访达弹密码，可写入钥匙串 |
| `selfhost mount` | `via: open` 时同上；`via: smbfs` 时跑 `mount_smbfs` |
| `selfhost umount`（别名 `unmount`） | 卸载 |
| `selfhost status` | 挂载点是否已挂上 |
| `selfhost path` | 打印给 `cp` / `mv` 用的本地路径 |

```bash
skill-spark selfhost profiles
skill-spark selfhost open --profile lazycat
mv ~/Downloads/a.zip "$(skill-spark selfhost path --profile lazycat)/"

SELFHOST_CLI_PASSWORD='…' skill-spark selfhost mount --profile lazycat
```

## 选项

| 选项 | 作用 |
| --- | --- |
| `--config <path>` | 指定 `config.json` |
| `--profile <name>` | profile 名（默认取 `config.json` 的 `default`） |

## config.json

从当前目录向上最多 8 层查找名为 `config.json` 且含 `profiles` 字段的文件。本仓库根目录的 [config.json](../config.json) 是模板。

```json
{
  "default": "lazycat",
  "profiles": {
    "lazycat": {
      "host": "192.168.1.5",
      "share": "share",
      "user": "admin",
      "mountPoint": "~/Desktop/lazycat_disk",
      "via": "open"
    }
  }
}
```

| 字段 | 作用 |
| --- | --- |
| `host` / `share` / `user` | SMB 主机、共享名、用户名 |
| `mountPoint` | `mount_smbfs` 的挂载点，支持 `~` |
| `via` | `open`（走访达 / 钥匙串）或 `smbfs`（走 `mount_smbfs`，需密码） |

字段从哪抄、挂上后盘在哪：见 hub 侧 `tools/docs/uc-10-lazycat-where-to-look.md`。

## 结构

```text
packages/skill-cli/src/commands/selfhost/
  index.ts   # 子命令注册
  config/    # 读 config.json、选 profile
  smb/       # URL 与 mount_smbfs / open / umount
```
