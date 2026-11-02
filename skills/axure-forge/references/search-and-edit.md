# 检索与编辑

```bash
axure-forge search explore --project demo.rp --query 提交 --category instance --limit 5
```

读取 `result.items` 中实际 `scope_id`、`node_id` 和路径，必要时用 `node get` 确认。匹配多项时使用名称、类型、页面路径缩小范围；存在业务歧义时询问用户，不批量改掉同名元件。无命中时换关键词或列出目标页面的节点。

```bash
axure-forge node get --project demo.rp --scope-id SCOPE --node-id NODE
axure-forge node update --project demo.rp --scope-id SCOPE --node-id NODE \
  --changes '{"text":"确认提交"}' --output edited.rp
axure-forge node create --project edited.rp --scope-id SCOPE \
  --spec '{"kind":"button","name":"返回","text":"返回","bounds":{"x":40,"y":120,"width":120,"height":40}}' \
  --output with-button.rp
axure-forge node delete --project with-button.rp --scope-id SCOPE --node-id NODE --output deleted.rp
```

基础编辑用 `node update --changes`；元件专属属性用 `node configure --properties`，例如 `{"disabled":true}`。JSON 布尔值为 `true/false`。`node move`、富文本、分组等按相应子命令帮助调用，不能把未支持的属性塞入 changes。

模板发现：`search explore --query 输入框 --category template --limit 5`。用返回的模板标识调用 `library instantiate`。自定义库通过每次调用的 `--library-path FILE` 注册；独立的 `library register` 不会持久化到下一次 CLI 会话。

`search context` 使用返回的 result_id；独立 CLI 会话的检索上下文可能不可恢复，优先利用搜索结果中的稳定节点/作用域 ID 获取详情，不反复尝试已失效的会话句柄。

重新打开输出，再检索/读取目标，验证文本、类型和必要属性。其他现有领域（table、tree、menu、master、adaptive_view、connector 等）使用 `axure-forge --help` 发现真实名称，仅加载任务所需帮助。
