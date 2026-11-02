# 检索与编辑

```bash
axure-forge search explore --project demo.rp --query 提交 --category instance --limit 5
```

从 `result.items` 里取真实的 `scope_id`、`node_id` 和路径，需要时用 `node get` 确认。

命中多个时，用名称、类型、页面路径缩小范围。业务含义不明确就先问用户，不要一次改掉所有同名元件。一条都没命中，就换关键词，或者直接列出目标页面的节点。

```bash
axure-forge node get --project demo.rp --scope-id SCOPE --node-id NODE
axure-forge node update --project demo.rp --scope-id SCOPE --node-id NODE \
  --changes '{"text":"确认提交"}' --output edited.rp
axure-forge node create --project edited.rp --scope-id SCOPE \
  --spec '{"kind":"button","name":"返回","text":"返回","bounds":{"x":40,"y":120,"width":120,"height":40}}' \
  --output with-button.rp
axure-forge node delete --project with-button.rp --scope-id SCOPE --node-id NODE --output deleted.rp
```

改通用属性用 `node update --changes`；元件专属属性用 `node configure --properties`，例如 `{"disabled":true}`。JSON 里的布尔值写 `true/false`。

`node move`、富文本、分组等按对应子命令的帮助调用；不支持改的属性不要硬塞进 changes。

找模板：`search explore --query 输入框 --category template --limit 5`。拿到模板标识后，用 `library instantiate` 放到页面上。

自己的元件库要在每次调用时用 `--library-path FILE` 指定；单独执行 `library register` 不会保留到下一次命令。

`search context` 要用返回的 result_id。每次命令都是独立一次，上一次的搜索上下文可能已经失效。优先用搜索结果里固定的节点 ID 和作用域 ID 取详情，不要反复重试已经失效的会话。

重新打开输出文件，再搜一次、读一次目标，核对文字、类型和必要属性。

其他类别（`table`、`tree`、`menu`、`master`、`adaptive_view`、`connector` 等）可以用 `axure-forge --help` 查实际名称，只查当前任务需要的部分。
