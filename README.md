# AxureForge Skill

通过独立二进制 CLI 分析、创建和编辑 Axure RP9。使用端无需 Python、pip、uv 或源码构建；第一版支持 macOS ARM64，必须安装 Axure RP9。

## 安装 skill

本仓库为独立的公开 GitHub skill 仓库，标准目录可被 `skills` CLI 发现：

```bash
npx skills add qizhi2design/axure-forge-skill --list
npx skills add qizhi2design/axure-forge-skill --skill axure-forge --agent codex --global
```

本地安装：在本仓库执行 `npx skills add . --skill axure-forge --agent codex --global`。安装器会处理 scripts 和 references；不要只复制 SKILL.md。npx 需要 Node/npm，CLI 本身不依赖 Node。

## 使用

```text
$axure-forge 检查 RP9 环境并安装二进制 CLI
$axure-forge 分析 ./demo.rp 的页面和交互
$axure-forge 将 ./site 转换为 ./demo.rp
$axure-forge 将 ./demo.rp 中“提交”改为“确认提交”，另存为 ./edited.rp
$axure-forge 创建两个状态的面板，并为按钮添加切换交互
```

首次运行检查 RP9，再检查/安装 CLI。兼容的现有版本直接复用。输入 RP11 只报告版本，不自动转换或编辑。修改后重新打开核对；设计器预览需单独验证。

## 参数

Skill 接受自然语言，没有自定义的 `$skill --flag` 解析器。以下任务字段映射到真实脚本或 CLI 参数：

| 字段 | 用途 |
| --- | --- |
| action | doctor / install / analyze / create / import-html / edit / batch，由自然语言选择 |
| project / output | 输入/输出 RP 路径；修改默认另存 |
| input | HTML 文件或含 index.html 的目录 |
| query | 搜索文字、名称，可结合类型和页面 |
| operations | schema_version=2 的批量 JSON 文件 |
| axure-path | RP9 应用路径，默认 /Applications/Axure RP 9.app |
| version | 安装版本，默认 v0.2.1，最低 0.2.1 |
| binary-path / checksum-path | 本地二进制与 SHA256SUMS，必须一起提供 |
| bin-dir | 全局命令安装目录，默认 ~/.local/bin |
| download-method | 默认 curl 匿名下载；可选 gh / auto |
| force | 明确替换已有安装或覆盖业务输出，两者属于不同命令 |

```bash
bash skills/axure-forge/scripts/doctor.sh --help
bash skills/axure-forge/scripts/install.sh --help
bash skills/axure-forge/scripts/inspect-rp.sh --help
```

二进制来源：公开仓库 <https://github.com/qizhi2design/axureforge-cli> 的版本 Release，不需要 GitHub 登录。下载资产约定为 `axure-forge-0.2.1-macos-arm64.tar.gz` 和 `SHA256SUMS`，包内保留第三方许可证。可使用已有本地产物离线安装：

```bash
bash skills/axure-forge/scripts/install.sh \
  --binary-path /absolute/path/axure-forge \
  --checksum-path /absolute/path/SHA256SUMS
export PATH="$HOME/.local/bin:$PATH"
axure-forge --version
```

## 目录与验证

`skills/axure-forge/` 是实际分发目录；`references/` 按任务加载，`scripts/` 只使用 Shell 与 macOS 系统工具。tests 不进入 skill 上下文。

```bash
bash tests/run.sh /absolute/path/axure-forge
```


MIT License。CLI 上游单独采用 MIT License，二进制不提交到本仓库。
