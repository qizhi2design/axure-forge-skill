# 二进制安装

仅支持 macOS ARM64，必须安装 Axure RP9。安装和使用不需要 Python、pip、uv、Git 或 Node。通过 npx 安装 skill 本身才需要 Node/npm。

```bash
bash /ABS/SKILL/scripts/doctor.sh --rp9-only
bash /ABS/SKILL/scripts/install.sh --version v0.2.1
# 非标准应用路径：以上命令添加 --axure-path '/Applications/Custom Axure.app'
```

安装器从公开仓库 `https://github.com/qizhi2design/axureforge-cli/releases/download/v0.2.1/` 获取 `axure-forge-0.2.1-macos-arm64.tar.gz` 和 `SHA256SUMS`，校验 archive、架构、版本、命令及创建/重开行为，然后原子替换 `~/.local/bin/axure-forge`。默认 curl 匿名下载，不需要 GitHub 登录。发布尚未完成时会明确下载失败，不回退源码安装。校验和证明下载一致性，不代表签名或公证。

离线安装（校验文件中的名称必须与二进制 basename 一致）：

```bash
bash /ABS/SKILL/scripts/install.sh \
  --binary-path /downloads/axure-forge \
  --checksum-path /downloads/SHA256SUMS
```

安装参数：`--version v0.2.N`（默认 v0.2.1，最低 0.2.1）、`--axure-path APP`、`--bin-dir DIR`（默认 ~/.local/bin）、`--binary-path FILE` + `--checksum-path FILE`、`--download-method curl|gh|auto`（默认 curl）、`--force`（替换现有命令）。已有目标版本复用；升级需明确传 `--force`。所有脚本支持 `--help`。

`doctor.sh` 接受 `--axure-path`、`--binary-path`、`--rp9-only`，输出 key=value；失败退出 1。`inspect-rp.sh --project FILE [--axure-path APP]` 输出头部格式 JSON；非 RP9 退出 1，必须再运行 CLI 完整打开以排除损坏。

如果 PATH 不包含安装目录，在 shell 配置添加 `export PATH="$HOME/.local/bin:$PATH"`，或直接使用安装器打印的绝对路径。不能启动时报告具体 stderr；不要自动移除系统隔离属性、绕过 Gatekeeper 或要求 sudo。二进制未经签名、公证，需要时由用户在系统设置允许。
