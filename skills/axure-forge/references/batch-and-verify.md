# 批量与验证

```bash
axure-forge dump --project input.rp --work-dir .forge
# 通过 rg/jq 查 .forge/index/nodes.jsonl，不重复 page get
axure-forge batch ops.json --project input.rp --index .forge/index --output output@v1.rp --verify
```

索引含源文件 SHA256 和索引文件校验。写入前检查源文件；成功输出会生成新索引，路径见 summary，不能继续沿用旧索引。已有操作占用 `--index`（位置序号）时，新鲜度参数名为 `--project-index`。

批量 JSON：

```json
{"schema_version":3,"operations":[
  {"op":"page.create","as":"detail","params":{"name":"详情"}},
  {"op":"node.create","params":{"scope_id":{"$ref":"detail.scope_id"},"spec":{"kind":"text","text":"新页面"}}}
]}
```

`--project` 自动提供 project_id；新建项目也可命名结果并引用 `project.project_id`、`project.pages.0.scope_id`。引用只允许前面的已成功结果，缺字段、前向引用、重复别名均报错。成功为 `{"schema_version":3,"ok":true,"result":{"results":[...]}}`。失败为 `ok:false`，错误位于 `error.code/message/details`；`details.failed_index` 从 0 开始，`details.applied_count` 为 0。批次在隔离图中执行，失败不提交任何编辑，也不产出目标 RP，不返回可继续引用的候选结果。旧 v2 请求不兼容。

`project.export` 与 `library.register` 不允许进入编辑批次。CLI 用外层 `--output` 在成功后发布文件；模板库在批次前通过 `--library-path` 提供。MCP/SDK 成功提交后需重新获取项目句柄，失败时原句柄仍有效。

导入和 batch 默认重新解析输出并生成证据。`--verify` 也可用于其他写入命令。`--evidence-dir DIR` 覆盖证据位置，`--fail-on error|warn|none` 控制门禁，默认 error。失败保留诊断和候选 RP，summary 标记 candidate。

```bash
axure-forge dump --check --project input.rp --index .forge/index
axure-forge verify --index .forge/index --json .forge/check.json
```

verify 读取索引不解析 RP；传 --project 时额外校验源文件。结构已检查、布局估算、视觉未检查、交互未检查分别报告。缺少画布或边框意图等依据时输出限制，不能声称通过了这些检查。不要把合法的多行文本、隐藏状态、叠层当成布局错误。

验收报告路径直接复用；不因用户问“好了吗”而再次打开 GUI。只有需要视觉或交互验收时才集中打开 Axure。

SPA 分阶段验证：structure 通过重新解析、摘要校验和原生 ID 映射检查；visual 与 interaction 由目标 Axure 导出的实际预览验收，CLI 自动检查保留 not_run。RP9 仅回读时明确未执行 GUI。

排版检查真实行框与 writing-mode/text-orientation/white-space/lineHeight；固定测量框不得自动扩宽。横排、竖排、真实换行分别抽查，混排字形旋转不支持时保留诊断。透明填充、零 padding、已有边框改为零都需创建/更新/回读；TableCell 还要读取四边 table_borders，不能仅看通用 border.width。

背景检查从文字框逐层追溯组件底板、Portal 装饰和页面画布，结合 consumed_layers 确认归属；不通过批量删背景修复一个组件。交互集中覆盖树半选/禁用/确认/取消、菜单多组组合折叠、Tab 回切、跨年和逆序日期及禁用日期。保存截图与操作结果，区分浏览器采集测试和 RP 预览测试。

Portal 弹层打开后检查实际点击命中：后生成的表格或内容不能遮挡确认/取消。层级恢复应由通用弹层置顶行为完成。父菜单行高度取该行自身的文字行框与内边距，不能将整个子树高度当作父行高度。禁用状态需在选中样式刷新后仍然生效。原生交互字段的类型错误可能通过结构回读，因此新增原生动作后仍需集中做编辑器预览。
