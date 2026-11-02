# 事件、动态面板与中继器

每条命令都要带 `--project`，做修改时再带一个新的 `--output`。下面代码里的大写 ID 必须换成真实返回的 ID。

```bash
axure-forge panel create --project demo.rp --scope-id SCOPE \
  --bounds '{"x":40,"y":100,"width":400,"height":240}' --states '["概览","详情"]' --name 内容面板 --output panel.rp
axure-forge panel get --project panel.rp --scope-id SCOPE --node-id PANEL_NODE
```

动态面板放在它所在的页面或容器里。每个状态内部有独立的元件空间，往状态里加元件要用状态返回的 `scope_id`。

状态切换动作里的状态目标要用真实状态 ID。先取面板详情再配事件，不要把面板所在的 `scope_id` 当成状态 ID。

```bash
axure-forge interaction set --project panel.rp --scope-id SCOPE --node-id BUTTON \
  --events '[{"event":"click","cases":[{"actions":[{"kind":"set_panel_state","params":{"panel":"PANEL_NODE","state":"详情"}}]}]}]' \
  --output interactive.rp
axure-forge interaction get --project interactive.rp --scope-id SCOPE --node-id BUTTON
```

事件按 `event → cases → actions → kind/params` 一层层嵌套，不是平铺的动作清单。

页面级事件用 `page set-events`。RP9 的页面加载事件写 `load`，不能写成 `page_load` 代替。

`interaction catalogue` 能列出支持的事件名，但列表里有，不代表每种对象都能用。

```bash
axure-forge repeater create --project interactive.rp --scope-id SCOPE \
  --bounds '{"x":500,"y":100,"width":200,"height":40}' --columns '["Name"]' \
  --rows '[{"Name":"Alpha"}]' --name 商品列表 --output repeater.rp
axure-forge repeater get --project repeater.rp --scope-id SCOPE --node-id REPEATER
axure-forge repeater get-data --project repeater.rp --scope-id SCOPE --node-id REPEATER
axure-forge repeater set-data --project repeater.rp --scope-id SCOPE --node-id REPEATER \
  --columns '["Name"]' --rows '[{"Name":"Beta"}]' --output updated.rp
```

中继器的模板有自己独立的元件空间，和外面不同。用 `repeater get` 返回的 template 信息来定位。

只写数据不会让模板显示出来；还要按实际需求设置模板和 item_load 交互。

`refresh_repeater` 受 RP9 原生格式限制，不支持写入；不要绕过正常修改方式硬写。

复杂动作先查对应帮助，并检查返回的错误。保存后重新打开读取事件和数据；实际点击、预览效果要在 Axure 设计器里单独验证。
