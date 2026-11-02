# 批量与验证

```bash
axure-forge dump --project input.rp --work-dir .forge
# 通过 rg/jq 查 .forge/index/nodes.jsonl，不重复 page get
axure-forge batch ops.json --project input.rp --index .forge/index --output output@v1.rp --verify
```

索引含源文件 SHA256 和索引文件校验。写入前检查源文件；成功输出会生成新索引，路径见 summary，不能继续沿用旧索引。已有操作占用 `--index`（位置序号）时，新鲜度参数名为 `--project-index`。

批量 JSON：

```json
{"schema_version":2,"operations":[
  {"op":"page.create","as":"detail","params":{"name":"详情"}},
  {"op":"node.create","params":{"scope_id":{"$ref":"detail.scope_id"},"spec":{"kind":"text","text":"新页面"}}}
]}
```

`--project` 自动提供 project_id；新建项目也可命名结果并引用 `project.project_id`、`project.pages.0.scope_id`。引用只允许前面的已成功结果，缺字段、前向引用、重复别名均报错。操作出错不保存输出；现有批量格式保持兼容。

导入和 batch 默认重新解析输出并生成证据。`--verify` 也可用于其他写入命令。`--evidence-dir DIR` 覆盖证据位置，`--fail-on error|warn|none` 控制门禁，默认 error。失败保留诊断和候选 RP，summary 标记 candidate。

```bash
axure-forge dump --check --project input.rp --index .forge/index
axure-forge verify --index .forge/index --json .forge/check.json
```

verify 读取索引不解析 RP；传 --project 时额外校验源文件。结构已检查、布局估算、视觉未检查、交互未检查分别报告。缺少画布或边框意图等依据时输出限制，不能声称通过了这些检查。不要把合法的多行文本、隐藏状态、叠层当成布局错误。

验收报告路径直接复用；不因用户问“好了吗”而再次打开 GUI。只有需要视觉或交互验收时才集中打开 Axure。
