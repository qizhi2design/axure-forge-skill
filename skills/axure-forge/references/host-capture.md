# 已登录宿主标签页：采集任务执行

CLI 提供确定性脚本与离线校验；宿主提供现有 Chrome/Edge 标签页的连接、交互与截图。
不能通过复制 Cookie、storage state 或新建独立浏览器来替代目标标签页。

## 准备与工具能力

运行 `web prepare --config FILE --output NEW_DIR`。目录内包含 manifest.json、collector.js、
paint.js、results/ 与 assets/；prepare 拒绝覆盖已有目录，--force 也不能复用旧结果。
按 manifest.tasks 读取 page_id、path、page_steps、steps、readiness 与 region/state。
组件定义位于 manifest.config.pages[].components。

从宿主文档确认：已有标签页连接、只读 DOM/样式/Range、PNG 截图和本地文件保存。
选择目标页并核对登录状态。只使用允许的页面 API，遇到限制报告能力缺口。
不要在只读工具里注入 script 标签、eval/new Function 或执行 paint.js。

collector.js 是 request => result 函数。每次传 task_id，以及由连接工具确认的 browser 名称。
如果工具支持函数调用，可直接传函数和参数；若它把字符串作为表达式执行，构造：

```js
JSON.stringify((<collector.js 原文>)(<JSON 序列化的 request>))
```

JSON 文本在宿主本地解析/保存，避免深层对象被工具截断。不要把完整 DOM 和大批原始记录
打印到对话。结果过大时传 transport:{offset:0,limit:24000}，逐段读取返回的 chunk。
每段 total、sha256 必须相同，offset 连续；拼接后在宿主本地校验 UTF-8 文本的 SHA256 再解析。
重复读段须使用同一份 request 与两个 probe；摘要变化或确认样本过期则重采集，不能拼接不同状态。

## 每个任务

1. 通过宿主执行 page_steps，并确认该页面就绪；已有标签页不重复导航。
   调用 {action:'baseline'}，保存返回的 signature/metadata 对象为 baseline_before。
2. 通过宿主执行 task.steps。capture 不会点击或输入，所有交互都走宿主的 UI API。
3. 对每个复合组件执行 capture_steps，调用 {action:'component',component_id} 保存观察。
   Tab 逐项选中后调用 {action:'tab',component_id,item_key,content_selector}，把返回的
   content/content_bounds 放入该 item。状态仍可见时保存其 PNG。恢复原 Tab，再执行 restore_steps。
   不用未实际展开的数据补造选项；data 声明须有源码或实际观察依据。
4. 恢复组件后调用 {action:'probe'} 得到 sample；至少 250ms 后再调用 probe 得到 confirmation。
   调用 {action:'capture',baseline:baseline_before,sample,confirmation,components:[...已观察组件]}。
   两份探针应相同，间隔不超过 30 秒，confirmation 不能超过 30 秒前；几何变化就重新取样。
   大结果分段读取期间保留同一份样本；临时页面数据不写入全局变量。
5. 保存 raw.records 以及组件 Tab content.records 中所有带 raster_id 的局部 PNG。
   再调用 probe，把返回的 baseline 写入 capture_after；其 signature 必须等于 stability.after，
   metadata 必须等于本次采集 metadata。截图造成滚动、失焦或布局变化时恢复并重采集。
6. 显式恢复 task.steps 的页面变化。调用 baseline，把结果写入 baseline_after，要求与
   baseline_before 完全相同。恢复失败停止该状态；不能把“恢复步骤执行过”当成已恢复。
7. 保存 results/<task_id>.json。最终对象含 task_id、manifest_sha256、metadata、raw、
   baseline_before、baseline_after、capture_after、stability 和 rasters。

## 局部 PNG

每个 raster_id 对应一条 rasters 记录：

```json
{"id":"p000-s000-12","file":"assets/icon.png","sha256":"文件字节的 SHA256",
 "bounds":{"x":100,"y":120,"width":40,"height":30},"scale":2}
```

宿主只返回 JPEG 时，用已有系统编码器先转 PNG，再计算文件哈希与像素尺寸；例如 macOS 的
`sips -s format png source.jpg --out shot.png`。这不增加产品依赖，也不能恢复 JPEG 已损失的细节。
没有可用编码器则报告资源能力缺口。

bounds 必须等于原始记录的文档 CSS 坐标。按宿主截图 API 的实际裁剪原点换算：
视口裁剪需减 scroll，文档裁剪不减。scale 是截图像素/CSS 比率，不能仅凭 DPR 猜测。
PNG 实际宽高必须等于 bounds 宽高 × scale（允许 1 像素舍入）；文件只能位于本次采集目录内。
包括 Tab 内容在内，缺失、重复、未知、哈希不符或坐标不符都会阻止组装。

装饰层必须只截图背景/阴影等绘制，保留子控件可编辑。仅当宿主明确提供写能力时，使用
paint.js 的 {action:'hide',selector} 临时隐藏子内容，截图后在 finally 调用 {action:'restore'}。
记录 paint_only:true 以及相同的 restoration_before/restoration_after 签名。
只读宿主无法获取必需的 paint-only 图时停止并报告，不能把整个交互面板截图冒充完整还原。

## 离线转换

```sh
axure-forge web capture --input DIR --output snapshot.json
axure-forge web plan --snapshot snapshot.json --output plan.json
axure-forge web import --plan plan.json --format-version 11 --output prototype.rp
```

采集按实际窗口大小，不强制调整视口；多任务须保持同源和一致视口。只保存来源 origin/pathname，
不把 URL query/hash 作为来源证据。业务文字、表单值和截图仍可能敏感，应保留在用户工作目录。
DOM 顺序对复杂叠层仅为近似；CLI 结构通过、宿主交互通过和 Axure GUI 通过分开汇报。
旧 --url/--build-dir/--browser/--storage-state 等参数已移除。旧有效 snapshot/plan 可继续离线使用。
