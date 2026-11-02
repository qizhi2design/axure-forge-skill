---
name: axure-forge
description: 用 AxureForge 分析、创建和编辑 Axure RP9 原型，支持 HTML 转 RP、定位和修改元件、设置交互、批量操作；也用于检查 RP9 环境和安装 AxureForge。适用于 Apple 芯片的 Mac，需要在本机安装 Axure RP9。
---

# AxureForge

用 `axure-forge` 命令操作 RP9。不需要了解文件内部结构，用命令就能完成日常工作。
以下相对路径都以本 skill 目录为基准；实际执行时换成绝对路径。

## 启动

1. 运行 `bash scripts/doctor.sh`。RP9 装在非默认位置时加 `--axure-path APP`。没检测到 RP9 就停下来，向用户说明原因。判断版本要看应用本身的信息，不能只看文件夹名字。
2. AxureForge 缺失或版本不匹配时，读[安装说明](references/installation.md)后运行安装器。已有可用版本直接复用，不要自行升级，也不要自己下载源码编译。
3. 有输入文件时，先运行 `bash scripts/inspect-rp.sh --project FILE`，再用 `axure-forge project open --path FILE` 完整打开。只看文件头还不能确认文件完好，要继续打开一次。不是 RP9 的文件不编辑，也不自动转换。

## 按任务加载

只读当前任务需要的文档，不用一次全部读完。

- 创建项目、页面、导入 HTML：[项目与 HTML](references/project-and-html.md)。
- 分析项目、定位和修改元件、使用模板：[检索与编辑](references/search-and-edit.md)。
- 事件、动态面板、中继器：[交互](references/interactions.md)。
- 多步修改、批量执行和结果核对：[批量与验证](references/batch-and-verify.md)。

## 执行约束

- 命令输出是 JSON。内容在 `result` 里，`result` 不是最外层。`schema_version` 为 2。
- 用返回的真实 ID（`scope_id`、`node_id` 等），不要猜。先用 `search explore --limit 5` 定位，需要时再读具体对象，不要一上来就列出所有页面节点。
- 每执行一条命令都是独立一次。下一条命令要带上一步的输出文件；多处修改可以写成批量 JSON，参数以实际子命令的 `--help` 为准。
- 输出默认另存新文件。要覆盖已有文件，必须用户明确要求并传 `--force`。批量执行出错立即停止，失败时不会写出文件；部分成功不要当成完整成功汇报。
- 写完重新打开一次，再核对目标属性。检查文件结构、在 Axure 设计器里打开、预览交互是三件不同的事；没做实机验证就明确说明。
- 汇报输出路径、实际改了哪些内容、验证到哪一步。遇到工具不支持的功能，要说清限制；不承诺任意 HTML 都能无损转换。
