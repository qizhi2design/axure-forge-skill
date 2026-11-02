# 安装与环境嗅探

运行平台为 Apple 芯片 Mac。安装 CLI、生成和结构验证不要求已安装 Axure，也不绑定 RP9；需要原生视觉验收时才使用对应编辑器。不需要额外 Python 运行时。

```bash
bash /ABS/SKILL/scripts/doctor.sh --app-only
bash /ABS/SKILL/scripts/install.sh --version v0.3.0
bash /ABS/SKILL/scripts/doctor.sh
```

安装器从公开仓库 [axureforge-cli](https://github.com/qizhi2design/axureforge-cli/releases) 下载目录包与校验文件，完整校验、检查协议 v3 和双版本能力、分别创建并重新解析 RP9/RP11 后，原子切换命令入口。失败保留旧安装；无需登录 GitHub，不改用源码构建。

版本号不能代表协议兼容：历史 `0.3.0` 可能仍是 v2。以 doctor 能力检查为准；没有兼容发布包时说明限制，不循环重装同一个旧包。本次源码适配不代表已发布新二进制。

## 生成格式选择

`doctor.sh` 输出 `available_format_versions` 和 `default_format_version`。自动检查应用元数据；仅 RP11 时默认 11，其余情况默认 9。两版均在且交付对象不明确时可询问一次，建议 RP9；用户指定和项目已确认约定优先。

- `--axure-path APP`：嗅探非标准位置或改名的 RP9/RP11。
- `--format-version 9|11`：覆盖本次检查的建议值，允许选择未安装编辑器的格式；生成命令仍须显式传入该值。
- `--app-only`：只报告环境，缺少编辑器不会阻止安装；显式给出的错误路径会报错。
- `AXURE_APPLICATIONS_DIR`：替换默认 `/Applications` 检查目录。

将选定格式及来源写入项目的 `design-brief.md`，在当前任务复用。已有文件按源格式编辑；新建默认值不用于自动转换。未安装编辑器时，原生视觉和交互状态保持未验证。

## 安装参数

```bash
bash /ABS/SKILL/scripts/install.sh   --package-dir /downloads/axure-forge-0.3.0-macos-arm64   --checksum-path /downloads/PACKAGE-SHA256SUMS
```

目录包必须整体安装。参数包括 `--version vX.Y.Z`（默认 v0.3.0）、`--bin-dir DIR`（默认 `~/.local/bin`）、`--axure-path APP`、`--format-version 9|11`、`--package-dir DIR` + `--checksum-path FILE`、`--download-method curl|gh|auto` 和 `--force`。默认匿名 curl 下载；已有安装只有能力兼容时才能复用，更换版本明确传 `--force`。

`doctor.sh` 还接受 `--binary-path CLI`，以 JSON 能力声明检查 v3、原子批次、双版本读写及生成版本参数。`inspect-rp.sh --project FILE` 是可选文件头检查，接受 RP9/RP11，不能代替 `dump --project FILE` 完整解析；普通任务不额外运行它。

安装目录不在 PATH 时，使用安装器输出的完整路径，或将 `~/.local/bin` 加到 PATH。不要自动移除系统隔离标记、绕过安全提示或要求 sudo。程序未签名；确有系统阻止时，由用户在系统设置中允许。
