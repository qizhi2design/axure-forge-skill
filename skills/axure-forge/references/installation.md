# 安装与环境嗅探

运行平台为 Apple 芯片 Mac。安装 CLI、生成和结构验证不要求已安装 Axure，也不绑定 RP9；需要原生视觉验收时才使用对应编辑器。不需要额外 Python 运行时。

```bash
bash /ABS/SKILL/scripts/doctor.sh --app-only
bash /ABS/SKILL/scripts/install.sh
bash /ABS/SKILL/scripts/doctor.sh
```

安装器从公开仓库 [axureforge-cli](https://github.com/qizhi2design/axureforge-cli/releases) 下载目录包与校验文件，完整校验、检查协议 v3 和双版本能力、分别创建并重新解析 RP9/RP11 后，原子切换命令入口。失败保留旧安装；无需登录 GitHub，不改用源码构建。

版本号不能代表协议兼容：历史 `0.3.0` 可能仍是 v2。以 doctor 能力检查为准；没有兼容发布包时说明限制，不循环重装同一个旧包。0.4.0 起的正式发布包包含协议 v3 和更新清单，旧 0.3.0 发布资源保持不变。

## 生成格式选择

`doctor.sh` 输出 `available_format_versions` 和 `default_format_version`。自动检查应用元数据；仅 RP11 时默认 11，其余情况默认 9。两版均在且交付对象不明确时可询问一次，建议 RP9；用户指定和项目已确认约定优先。

- `--axure-path APP`：嗅探非标准位置或改名的 RP9/RP11。
- `--format-version 9|11`：覆盖本次检查的建议值，允许选择未安装编辑器的格式；生成命令仍须显式传入该值。
- `--app-only`：只报告环境，缺少编辑器不会阻止安装；显式给出的错误路径会报错。
- `AXURE_APPLICATIONS_DIR`：替换默认 `/Applications` 检查目录。

将选定格式及来源写入项目的 `design-brief.md`，在当前任务复用。已有文件按源格式编辑；新建默认值不用于自动转换。未安装编辑器时，原生视觉和交互状态保持未验证。

## 安装参数

```bash
bash /ABS/SKILL/scripts/install.sh   --package-dir /downloads/axure-forge-0.4.0-macos-arm64   --checksum-path /downloads/PACKAGE-SHA256SUMS
```

目录包必须整体安装。参数包括 `--version vX.Y.Z`（默认选择与当前 skill 兼容的最新正式版；已有兼容安装直接复用）、`--bin-dir DIR`（默认 `~/.local/bin`）、`--axure-path APP`、`--format-version 9|11`、`--package-dir DIR` + `--checksum-path FILE`、`--download-method curl|gh|auto` 和 `--force`。默认匿名 curl 下载；已有安装只有能力兼容时才能复用，更换版本明确传 `--force`。

`doctor.sh` 还接受 `--binary-path CLI`，以 JSON 能力声明检查 v3、原子批次、双版本读写及生成版本参数。`inspect-rp.sh --project FILE` 是可选文件头检查，接受 RP9/RP11，不能代替 `dump --project FILE` 完整解析；普通任务不额外运行它。

安装目录不在 PATH 时，使用安装器输出的完整路径，或将 `~/.local/bin` 加到 PATH。不要自动移除系统隔离标记、绕过安全提示或要求 sudo。程序未签名；确有系统阻止时，由用户在系统设置中允许。


## 版本检查、更新与来源

```bash
axure-forge update check --path /ABS/SKILL
axure-forge update all --path /ABS/SKILL --dry-run
axure-forge update all --path /ABS/SKILL --yes
axure-forge update cli --version 0.4.0 --yes
axure-forge config set sources.cli.repo qizhi2design/axureforge-cli
axure-forge config set sources.skill.repo qizhi2design/axure-forge-skill
axure-forge config set sources.cli.mirror-prefix https://mirror.example/
axure-forge config reset sources.cli
axure-forge config set updates.auto-check false
bash /ABS/SKILL/scripts/doctor.sh --check-updates
```

CLI 与 skill 独立版本管理，选择正式 Release 并校验协议和能力。skill 的版本及文件哈希记录在 `skill-manifest.json`。本地修改或历史安装无基线时，更新要求显式 `--force` 并保留备份；共享目录和链接会按真实路径去重，更新后需要重新加载 skill。

首次安装脚本接受 `--repo OWNER/REPO`、`--mirror-prefix HTTPS_PREFIX`；也可用 `AXURE_FORGE_CLI_REPO`、`AXURE_FORGE_CLI_MIRROR_PREFIX`。已有 CLI 的更新命令支持单次参数、环境变量、用户配置、默认值四级来源。检查全部组件时，单次来源参数必须配合 `--component cli|skill`；`update all` 使用各组件独立配置。镜像采用“前缀 + 完整 HTTPS 上游 URL”，同时代理 API 与下载。环境变量的 skill 对应名称为 `AXURE_FORGE_SKILL_REPO` 和 `AXURE_FORGE_SKILL_MIRROR_PREFIX`。

**离线可继续使用。** 普通命令不依赖检查结果。交互终端每天至多自动检查一次，额外等待不超过一秒，失败静默跳过；脚本和 JSON 调用不自动联网。手动检查断网时返回 `ok: true`、`check_status: unavailable`；手动更新未获得完整产物时返回 `update_status: not_applied`，退出码为 0，不修改旧安装。不能把无法检查当作已是最新版。

首次安装时若断网，脚本正常结束并说明需要联网或离线包；已有兼容安装优先复用且不联网。调用方应通过 `doctor.sh` 或命令路径确认是否确实装好，不能只凭安装脚本退出码判断。校验失败、非法参数和权限问题仍作为真实错误报告。

pip / uv tool / 源码安装由 CLI 提供原安装方式的升级指引；二进制更新保留完整目录，失败恢复原入口。Windows 的二进制更新使用独立进程，先返回 `submitted`，当前进程退出后完成；随后执行 `update check` 查看最终结果。skill 本身目前仍仅支持 Apple 芯片 Mac。
