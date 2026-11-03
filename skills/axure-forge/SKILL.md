---
name: axure-forge
description: 设计、创建和编辑 Axure RP9/RP11 原型，先明确页面范围与画布宽高，再完成 HTML 转 RP、元件检索、交互和批量修改；也适用于环境嗅探、格式选择、严格版本转换和 CLI 安装。适用于 Apple 芯片 Mac；安装和生成文件不要求已安装 Axure 编辑器。
---

# AxureForge

用 `axure-forge` 命令操作 RP9/RP11。不需要了解文件内部结构，用命令就能完成日常工作。
以下相对路径都以本 skill 目录为基准；实际执行时换成绝对路径。

## 创作前先约定画布

- 新建原型、新增独立页面或大幅调整布局时，先明确用途与页面范围、目标端、画布宽度、首屏高度，以及固定高度还是纵向延展。画布是二维的；长页总高度由内容计算，不要求用户预估。
- 优先复用本次对话、已有设计约定或用户明确指定的参考尺寸。单纯修改文字、元件属性或交互，沿用已有布局，不重新确认画布。不能把 RP 节点外接矩形当成用户确认的画布。
- 缺少影响设计的信息时，先给出具体建议，一次性请用户确认；确认前只做环境检查、读源文件等准备，不按猜测尺寸创作 HTML 或生成 RP。示例：“建议做桌面端线索列表页，宽 1440px、首屏高 900px，内容超出后纵向延展；按这个规格开始，还是有指定尺寸？”
- 用户已明确规格、已确认建议，或明确授权自行决定时直接执行。授权自行决定时说明所选规格，不再加一次审批。CLI 的默认尺寸不等于用户已确认。
- 将约定简记到工作目录的 `design-brief.md`：页面范围、目标端、宽度、首屏高度、延展方式、参考来源及确认状态。当前任务直接复用上下文，不每步重读；仅规格或范围发生变化时更新。
- 将约定传给 `--page-size WxH` 与 `--page-mode auto|fixed`；侧栏、主内容区和卡片尺寸由模板约束及 CLI 自动计算，只确认会影响设计的固定区域。

## 启动与数据复用

- 同一任务运行一次 `bash scripts/doctor.sh`，读取 `available_format_versions`、`default_format_version` 和 `protocol_version`；环境或二进制变化后才重查。非标准应用路径加 `--axure-path APP`。
- 安装不强制绑定 RP9，也不要求已安装编辑器。新建版本优先级：用户明确指定 → 本项目已确认约定 → 环境嗅探。仅 RP11 可用时默认 11；仅 RP9、两者都有或都未安装时默认 9。两者都有且交付对象不明确时可询问一次，建议 RP9；没有必要时说明采用默认值后继续，不增加强制确认。
- 将选择及来源记入 `design-brief.md`，新建项目与 HTML 导入显式传 `--format-version 9|11`。已有输入保持源格式，不能套用新建默认值改版本；转换必须是用户要求的独立操作。没有编辑器仍可生成与结构验证，视觉/交互验收报告未执行。
- 缺少兼容 CLI 时读 [安装说明](references/installation.md)，安装发布的目录包；不要安装 Python 或克隆源码构建。
- 有 RP 输入时直接 `dump --project FILE` 完整解析并生成索引，替代“检查文件头 → project open → page list → page get”的多次往返。RP9/RP11 均可编辑，其他版本拒绝；默认不转换。
- 默认工作目录是当前目录的 `.forge/`，可传 `--work-dir DIR`。先读 `summary.json`；只针对异常读取 report 或索引，不把完整节点数据载入对话。

## 版本检查与手动更新

- 日常操作使用本地 CLI；不能因为断网、版本服务不可用或更新失败而阻止原型任务，也不能循环重试安装。
- 用户要求检查版本时执行 `axure-forge update check --path /ABS/SKILL --json`，或 `bash scripts/doctor.sh --check-updates`。检查状态为 `unavailable` 时说明暂时无法检查，继续使用本地版本；不得称为“已是最新版”。
- 用户要求更新时，先执行 `update all --path /ABS/SKILL --dry-run --json` 展示来源、版本和位置，再沿用用户已有授权执行 `update all --path /ABS/SKILL --yes --json`。可以只更新 `cli` 或 `skill`。用户未要求更新时不自动安装。
- 多份 skill 必须指定当前 skill 的真实路径；未知版本或本地修改需要用户明确授权覆盖后才传 `--force`。保留备份，完成后提示重新加载 skill 或开启新会话。
- CLI 支持更换 GitHub 仓库与 HTTPS 镜像，参见 [安装说明](references/installation.md)。CLI 缺少更新入口时才使用安装脚本引导。

## 按任务加载

运行中的 SPA、宿主浏览器或复杂控件还原：先读[SPA 语义预处理](references/spa-semantic.md)，涉及树形下拉、菜单、Tab、表格或日历时再读[控件映射决策](references/component-mapping.md)。优先可编辑原生控件及组合，不把整块交互区域作为图片兜底。

复合控件使用公开 components 配置与稳定业务键，按触发器、弹层、内容、装饰声明归属。默认保真；用户指定简化的组件才设 appearance:plain。检查自动生成的 component-report，缺失数据与未实测交互明确报告。

当前任务相关参考说明只需读一次：

- 新建页面需要起点时：[HTML 模板](references/html-templates.md)，只读取与任务匹配的一份模板。
- HTML 转换：[项目与 HTML](references/project-and-html.md)。
- React/Vue 等 SPA、减少 DOM 噪声、原生控件优先或日常 Chrome/Edge 已登录标签页还原：[SPA 语义预处理](references/spa-semantic.md)。先检查当前 CLI 是否提供 web 命令与所需参数。
- 定位和编辑：[检索与编辑](references/search-and-edit.md)。
- 交互：[交互](references/interactions.md)。
- 批量与证据：[批量与验证](references/batch-and-verify.md)。

## CLI 展示与诊断

- 本版要求 CLI 0.5.0 及以上。直接运行 `axure-forge` 显示版本与分组帮助；`--version` 仅输出版本号。帮助与 CLI 提示为英文，用户内容保持原样。
- CLI 命令与长参数使用完整的小写连字符拼写，例如 `adaptive-view`、`adaptive-view-set`、`interaction-style`、`master-folder`、`master-instance`、`master-tree`、`page-tree`。旧下划线命令和长参数缩写已移除；batch JSON 的 `master_instance.create` 等内部操作名及参数字段保持原样。
- 失败时先读 stdout 的单个 JSON 错误和 stderr 的简短提示；默认不显示 Python 堆栈。普通错误按提示修正，不循环重试。遇到未预期错误时，可在确认原操作输出与副作用后加 `--debug` 诊断；它只向 stderr 增加堆栈，不改变 JSON。
- 退出码 `0` 成功、`1` 执行或校验失败、`2` 参数或输入错误、`130` 用户取消。无参数或纯命令分组显示帮助且退出 `0`；不以退出码 `0` 单独推断已生成 RP，仍检查响应及输出文件。

## 执行约束

- 以 `capabilities --json` 中命令参数声明为准；一般不必反复 `--help`。输出协议为 3；先判断 `ok`，单操作读取 `result`，批量读取 `result.results`，失败读取 `error.code/message/details`。旧 v2 请求明确拒绝；CLI 版本号相同也不能代替能力检查。
- HTML 使用一次 `html import`，由 CLI 自动计算布局、写 RP、重新解析并产出计划/索引/报告。不要手算容器宽高、反复试导入或重复探测已有能力。
- 编辑先 dump 一次，再用本地 JSONL 定位真实 `scope_id`/`node_id`。一次 batch 尽量完成修改，并通过 `--index` 做写前新鲜度校验。创建出的 ID 使用批量结果引用。
- batch 原子提交：失败时 `error.details.applied_count` 为 0，不保留中间编辑；不要从失败批次继续引用结果。`project.export` 和 `library.register` 不放入编辑批次；文件输出使用 CLI 的 `--output`。
- 计划自动缓存；显式 `--plan FILE` 失效时重新生成，不能绕过哈希检查。索引只读，不能手改后用于写入。
- RP9/RP11 转换先 `project check-conversion`，再 `project convert` 另存；未知字段或未验证能力阻断时读取报告，不能用改文件头、删未知字段或原始对象写入来绕过。
- 输出默认另存新路径，已存在则换迭代文件名；只有用户明确要求覆盖才用 `--force`。
- 画布与页面范围按创作前约定确认一次；同一问题不重复确认，仅业务含义或高成本分叉仍不明确时再提问。用户询问进度时引用已有证据，不重跑截图。
- 结构、布局估算、视觉、交互分别汇报。CLI 自动检查不代表 Axure 视觉或交互实测；普通转换不打开 GUI，需要视觉验收时在交付检查点集中检查。
- 汇报输出路径、变更、`.forge/summary.json` 和未验证项；检查失败的候选文件不能描述为最终交付。
