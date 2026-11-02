---
name: axure-forge
description: 用 AxureForge 分析、创建和编辑 Axure RP9 原型，支持 HTML 转 RP、定位和修改元件、设置交互、批量操作；也用于检查 RP9 环境和安装 AxureForge。适用于 Apple 芯片的 Mac，需要在本机安装 Axure RP9。
---

# AxureForge

用 `axure-forge` 命令操作 RP9。不需要了解文件内部结构，用命令就能完成日常工作。
以下相对路径都以本 skill 目录为基准；实际执行时换成绝对路径。

## 启动与数据复用

- 同一任务运行一次 `bash scripts/doctor.sh`；环境或二进制变化后才重查。非标准路径加 `--axure-path APP`。
- 缺少兼容 CLI 时读 [安装说明](references/installation.md)，安装发布的目录包；不要安装 Python 或克隆源码构建。
- 有 RP 输入时直接 `dump --project FILE` 完整解析并生成索引，替代“检查文件头 → project open → page list → page get”的多次往返。非 RP9 不编辑。
- 默认工作目录是当前目录的 `.forge/`，可传 `--work-dir DIR`。先读 `summary.json`；只针对异常读取 report 或索引，不把完整节点数据载入对话。

## 按任务加载

当前任务相关参考说明只需读一次：

- HTML 转换：[项目与 HTML](references/project-and-html.md)。
- 定位和编辑：[检索与编辑](references/search-and-edit.md)。
- 交互：[交互](references/interactions.md)。
- 批量与证据：[批量与验证](references/batch-and-verify.md)。

## 执行约束

- 以 `capabilities --json` 中命令参数声明为准；一般不必反复 `--help`。输出协议为 2，单操作读取 `result`，批量读取 `results`。
- HTML 使用一次 `html import`，由 CLI 自动计算布局、写 RP、重新解析并产出计划/索引/报告。不要手算容器宽高、反复试导入或重复探测已有能力。
- 编辑先 dump 一次，再用本地 JSONL 定位真实 `scope_id`/`node_id`。一次 batch 尽量完成修改，并通过 `--index` 做写前新鲜度校验。创建出的 ID 使用批量结果引用。
- 计划自动缓存；显式 `--plan FILE` 失效时重新生成，不能绕过哈希检查。索引只读，不能手改后用于写入。
- 输出默认另存新路径，已存在则换迭代文件名；只有用户明确要求覆盖才用 `--force`。
- 同一问题不重复确认；只有业务含义或高成本分叉才提问。用户询问进度时引用已有证据，不重跑截图。
- 结构、布局估算、视觉、交互分别汇报。CLI 自动检查不代表 Axure 视觉或交互实测；普通转换不打开 GUI，需要视觉验收时在交付检查点集中检查。
- 汇报输出路径、变更、`.forge/summary.json` 和未验证项；检查失败的候选文件不能描述为最终交付。
