# 安装

只支持 Apple 芯片的 Mac（M 系列芯片），并且必须安装 Axure RP9。安装和使用都不需要另外准备运行环境；只有用 npx 安装这个 skill 时才需要 Node/npm。

```bash
bash /ABS/SKILL/scripts/doctor.sh --rp9-only
bash /ABS/SKILL/scripts/install.sh --version v0.2.1
# 非标准应用路径：以上命令添加 --axure-path '/Applications/Custom Axure.app'
```

安装器会从公开仓库 `https://github.com/qizhi2design/axureforge-cli/releases/download/v0.2.1/` 下载 `axure-forge-0.2.1-macos-arm64.tar.gz` 和 `SHA256SUMS`，检查文件是否完整、架构和版本是否正确、命令能不能用、能否新建并重新打开文件，然后替换 `~/.local/bin/axure-forge`。

默认用 curl 匿名下载，不需要登录 GitHub。版本还没发布时会直接报下载失败，不会改用源码构建。

校验和只能说明下载内容一致，不代表已经签名或通过系统安全审核。

离线安装（校验文件里写的文件名必须和命令文件名一致）：

```bash
bash /ABS/SKILL/scripts/install.sh \
  --binary-path /downloads/axure-forge \
  --checksum-path /downloads/SHA256SUMS
```

安装参数：`--version v0.2.N`（默认 v0.2.1，最低 0.2.1）、`--axure-path APP`、`--bin-dir DIR`（默认 ~/.local/bin）、`--binary-path FILE` + `--checksum-path FILE`、`--download-method curl|gh|auto`（默认 curl）、`--force`（替换现有命令）。已有目标版本直接复用；升级要明确传 `--force`。所有脚本都支持 `--help`。

`doctor.sh` 接受 `--axure-path`、`--binary-path`、`--rp9-only`，输出 key=value；失败时退出 1。

`inspect-rp.sh --project FILE [--axure-path APP]` 只输出文件头信息的 JSON。不是 RP9 就退出 1，必须再用 AxureForge 完整打开一次，确认文件没损坏。

如果命令找不到，说明安装目录不在 PATH 里：把 `export PATH="$HOME/.local/bin:$PATH"` 加到 shell 配置，或者直接用安装器打印的完整路径。

启动失败时，不要编造具体的报错内容。不要自动去掉系统的安全隔离标记，不要绕过系统安全提示，也不要要求 sudo。

这个程序文件没有 Apple 签名和安全审核，必要时请用户到系统设置里手动允许。
