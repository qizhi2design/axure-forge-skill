# 批量与验证

批量 JSON 里 `schema_version` 固定填 2。操作名带点，参数名用下划线：

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

带 `--project` 时，各操作里的 project_id 可以省略，命令会自动补上。批量结果在最外层的 `results[]`，单个操作的结果在最外层的 `result`。

不能用占位符引用上一步生成的 ID。先创建并保存、读出真实 ID，再写下一批操作。

批量按顺序执行。出错时，返回里会有 `failed_index`、`applied_count` 和已经完成的结果。

命令出错不会保存输出，批量也不支持整批回滚。要看命令的退出状态和错误信息，不能只看有没有返回结果。

验证顺序：重新打开 → 确认 format_version=9 → 检查页面 → 定点读取改过的对象、事件、数据。

要覆盖已有文件，必须用户明确要求并传 `--force`；否则另存新文件。目标文件已存在时，命令默认不会覆盖。

在 RP9 里打开、保存、预览测试，和检查文件结构，要分开汇报。

没有真的在界面上操作过，就标成“未验证”。结构检查通过，不等于交互一定正确。
