---
name: axure-forge
description: 使用 AxureForge 独立二进制 CLI 分析、创建和编辑 Axure RP9 原型，支持 HTML 转 RP、元件定位、交互和批量操作；也用于 RP9 环境检查及 CLI 安装。适用于 macOS ARM64，必须安装本机 Axure RP9。
---

# AxureForge

通过 `axure-forge` 命令操作 RP9，不读取底层序列化源码完成普通业务任务。以下相对路径均以本 skill 目录为基准；执行时使用实际绝对路径。

## 启动

1. 运行 `bash scripts/doctor.sh`；非标准 RP9 路径加 `--axure-path APP`。未检测到 RP9 则停止，说明原因。检测依赖应用元数据及可执行文件，不能以目录名代替版本检查。
2. 缺少或不兼容 CLI 时读取 [安装说明](references/installation.md)，运行二进制安装器。已有兼容版本直接复用。不要安装 Python、pip、uv 或克隆源码构建；不要自行升级兼容版本。
3. 有输入文件时运行 `bash scripts/inspect-rp.sh --project FILE`，再用 `axure-forge project open --path FILE` 完整解析。头部识别不代表文件有效。非 RP9 不进行编辑或自动转换。

## 按任务加载

只读当前任务需要的文档，不一次性载入全部参考资料。

- 创建项目、页面、HTML 导入：[项目与 HTML](references/project-and-html.md)。
- 分析项目、定位和修改元件、模板：[检索与编辑](references/search-and-edit.md)。
- 事件、面板、中继器：[交互](references/interactions.md)。
- 多步修改、批量执行和验收：[批量与验证](references/batch-and-verify.md)。

## 执行约束

- CLI 输出为 JSON；读取 `result`，不要把它当根对象。`schema_version` 为 2。
- 使用返回的 `scope_id`、`node_id` 等真实 ID，不猜测。优先 `search explore --limit 5`，需要时再读取具体对象；不要先倾倒所有页面节点。
- 单次 CLI 调用是新会话。下一条命令必须打开上一步输出文件；多个编辑可写批量 JSON，业务参数遵循实际子命令 `--help`。
- 默认另存输出，覆盖需用户明确要求并传 `--force`。批量错误立即停止，CLI 失败时不写出输出；不要将部分成功描述为完整成功。
- 写出后重新打开验证，并复查目标属性。结构验证与 Axure 设计器打开、预览交互是不同证据，没有实机验证时明确说明。
- 汇报输出路径、实际变更和验证范围；遇到不支持的原生能力说明限制，不保证任意 HTML 无损转换。
