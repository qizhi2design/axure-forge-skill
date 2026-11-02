# 批量与验证

批量 JSON 使用 schema_version=2，操作名为带点的内部名称，参数键使用下划线：

```json
{
  "schema_version": 2,
  "operations": [
    {"op":"node.update","params":{"scope_id":"SCOPE","node_id":"NODE","changes":{"text":"确认"}}},
    {"op":"page.rename","params":{"page_id":"PAGE","name":"首页"}}
  ]
}
```

```bash
axure-forge batch ops.json --project input.rp --output output.rp
axure-forge project open --path output.rp
```

使用 `--project` 时可省略各操作的 project_id，由 CLI 注入。批量结果在根 `results[]`，单操作结果在根 `result`。不支持用占位符引用前一步生成的 ID；先创建并保存、读取真实 ID，再构造下一批操作。

批量按序执行，错误含 `failed_index`、`applied_count` 和已有结果。CLI 出错不保存输出，不提供会话级整批回滚。检查进程退出码与 JSON 错误，不只看是否有 results。

验证顺序：重新打开 → 确认 format_version=9 → 检查页面 → 定点读取修改对象/事件/数据。覆盖输出必须用户已明确要求，并传 `--force`；否则另存文件。输出存在时 CLI 默认拒绝覆盖。

原生 RP9 打开、保存、预览测试与结构检查分开报告。没有实际执行 GUI/交互就标为“未验证”，不要从结构成功推断用户交互一定正确。
