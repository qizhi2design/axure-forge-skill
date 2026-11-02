# 事件、动态面板与中继器

每次命令都传 `--project`，修改传新的 `--output`。以下大写 ID 必须来自真实响应。

```bash
axure-forge panel create --project demo.rp --scope-id SCOPE \
  --bounds '{"x":40,"y":100,"width":400,"height":240}' --states '["概览","详情"]' --name 内容面板 --output panel.rp
axure-forge panel get --project panel.rp --scope-id SCOPE --node-id PANEL_NODE
```

动态面板位于宿主作用域；每个状态有自己的作用域，创建状态内元件使用状态返回的 scope ID。状态切换动作的状态目标需要实际状态标识；先获取 panel 详情，再构造事件，不把宿主 scope 当状态 ID。

```bash
axure-forge interaction set --project panel.rp --scope-id SCOPE --node-id BUTTON \
  --events '[{"event":"click","cases":[{"actions":[{"kind":"set_panel_state","params":{"panel":"PANEL_NODE","state":"详情"}}]}]}]' \
  --output interactive.rp
axure-forge interaction get --project interactive.rp --scope-id SCOPE --node-id BUTTON
```

事件树是 `event → cases → actions → kind/params`，不是扁平动作列表。页面事件使用 `page set-events`；RP9 页面加载使用 `load`，不能用 `page_load` 代替。`interaction catalogue` 提供事件声明，但声明存在不等于每种对象支持。

```bash
axure-forge repeater create --project interactive.rp --scope-id SCOPE \
  --bounds '{"x":500,"y":100,"width":200,"height":40}' --columns '["Name"]' \
  --rows '[{"Name":"Alpha"}]' --name 商品列表 --output repeater.rp
axure-forge repeater get --project repeater.rp --scope-id SCOPE --node-id REPEATER
axure-forge repeater get-data --project repeater.rp --scope-id SCOPE --node-id REPEATER
axure-forge repeater set-data --project repeater.rp --scope-id SCOPE --node-id REPEATER \
  --columns '["Name"]' --rows '[{"Name":"Beta"}]' --output updated.rp
```

模板作用域与宿主不同，使用 repeater get 返回的 template 信息定位。只写数据集不等于模板已绑定显示数据；根据实际需求设置模板和 item_load 交互。

`refresh_repeater` 在 RP9 原生导出存在限制，引擎拒绝写入；不要通过 raw 绕过。复杂动作先查对应帮助并校验返回错误。保存后重开读取事件/数据；实际点击、预览行为需 Axure 设计器单独验证。
