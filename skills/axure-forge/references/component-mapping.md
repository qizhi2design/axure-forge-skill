# SPA 控件映射决策

用于运行页面转 RP，先读取本页实际角色、层级、状态与几何；不要按框架标签逐个复制 DOM。AI 决定组件边界，现有浏览器工具采集证据，CLI 或原生创建接口写入元件。

## 遍历与匹配

按触发器、关联弹层、内容区分组遍历。优先级：原生标签/ARIA → 关联与状态 → 结构 → 框架类名 → 外观。`aria-controls/owns` 指向的 Portal 可在根外；关联缺失时，通过真实展开前后新增且可见的弹层确定归属。不要将所有 Portal 合并。

`ant-*`、`orange-go-*` 等前缀可变化，类名只作补充。树缺少 treeitem 角色时，从缩进单元、父子容器、switcher 与 checked/indeterminate 状态联合推断，并记录依据。不能仅凭相邻文本推断层级。

采集区分：已挂载但被滚动裁剪、未展开的子树、虚拟列表未挂载项。只展开任务范围内的代表分支；未知项不补造。复选框读取 input.checked/disabled 或 ARIA；“账号禁用”等文字标记不等于复选框 disabled。

| 观察特征 | 优先映射 | 保留的行为/边界 |
|---|---|---|
| button、role=button | Button | 标签、禁用、点击；图标可单独栅格 |
| 普通单选 combobox/select | Droplist | 完整已观察选项、当前值；原生选择，无需逐选项状态 |
| 多选/可搜索/树形 Select | 触发器＋动态面板＋子组件 | 搜索、树、复选项、临时选择、确定/取消分别处理；不转普通 Droplist |
| tree/treeitem、稳定父子层级 | Tree | 层级与展开收起；复选级联不是普通 Tree 的默认能力 |
| 树形多选、半选/自定义行布局 | 表格或行组＋Checkbox＋面板 | 仅实现有证据的级联范围；避免为全部选项组合复制面板状态 |
| checkbox/radio | Checkbox/Radio | checked、disabled；半选须有单独状态，不能默认为未选 |
| menu/menuitem、行高与缩进 | Table 行或原生 Menu | 导航选中、分组折叠、行点击；图标独立。内联折叠菜单优先表格分组，悬浮子菜单优先 Menu |
| tablist/tab/tabpanel | 动态面板＋标签按钮 | 一个标签对应一个已观察内容态；当前标签高亮同步 |
| 日期范围＋日历网格 | 输入框＋面板＋Table 日历 | 开始/结束两阶段选择；月份、禁用日期、快捷项分别声明。更新日期不代表重算数据 |
| table/grid，规则行列 | Table | 单元格文本、行列尺寸和明确点击；复杂筛选/分页另建控件 |
| 重复数据行、重复布局 | Table 或 Repeater | 静态少量行优先 Table；数据驱动更新且能力可用才用 Repeater |
| dialog、抽屉、浮层 | 动态面板＋原生内容 | 初始隐藏、打开/关闭、遮罩；不因容器复杂就把内容全部截图 |
| 标签、数字动画、辅助只读输入 | 合并到语义主体 | 同一数字的动画切片合并为完整数值；不输出测量节点和隐藏辅助输入 |
| canvas、地图、复杂 SVG、装饰背景 | 局部图像 | 图像只覆盖不能编辑的视觉部分，避免吞掉文字、按钮或点击主体 |

## 工具边界

开发版 `pages[].components` 支持 button/select 以及 tree-select、menu、tabs、date-range、table；先检查实际 CLI 能力与版本。复合类型由 core 编译为 Table/Checkbox/Panel 等原生元件，沿用 capture → plan → import，不另写页面专用生成器。

每个复合控件声明稳定 `id` 和唯一 `selector`。按“触发器—弹层—内容—装饰”确定归属；根外 Portal 和组件独有底板通过 `associated_selectors` 显式声明。需要展开采集的浮层声明成对的 `capture_steps`、`restore_steps`。同一图层只能属于一个组件；嵌套或重复归属报错，不能删除相邻图层来消除重影。当前复合根不能位于 web region 内。

最小配置片段（放入同一页面的 components 数组，替换为实际观察数据）：

```json
[
  {"id":"nav","kind":"menu","selector":"#nav","data":{"items":[{"key":"g","label":"分组"},{"key":"detail","label":"详情","parent":"g","page":"detail-page"}],"selected":"detail","complete":true}},
  {"id":"org","kind":"tree-select","selector":"#org","associated_selectors":["#org-popup"],"capture_steps":[{"kind":"click","selector":"#org"}],"restore_steps":[{"kind":"click","selector":"#org-cancel"}],"data":{"items":[{"key":"root","label":"组织"},{"key":"a","label":"账号","parent":"root"}],"selected":["a"],"cascade":true,"complete":true}},
  {"id":"views","kind":"tabs","selector":"#tabs","data":{"selected":"a","items":[{"key":"a","label":"概览","selector":"#tab-a","content_selector":"#content-a"},{"key":"b","label":"明细","selector":"#tab-b","content_selector":"#content-b"}]}},
  {"id":"period","kind":"date-range","selector":"#period","data":{"min":"2026-12-01","max":"2027-01-31","disabled_dates":["2027-01-01"]}},
  {"id":"grid","kind":"table","selector":"#grid"}
]
```

菜单的 page 必须对应 pages 中真实页面 id；没有导航证据则不填，并保留未绑定诊断。树/菜单/Tab 的 key 与文案分离；DOM 自动提取要求 id 或 data-forge-key。表格自动读取矩形 tr/td 或 ARIA grid；合并单元格需要显式矩形数据。也可声明 `data.rows`、`row_heights`、`column_widths`，但必须来自已观察证据。Tab 仅切换已采集内容，缺失态禁用并报告。日期只编译声明 min/max 内有限日期（最多 120 个月），不推测后端规则。

`data.complete` 必须有全量证据才能设 true；部分树即使 cascade=true 也不对未知后代级联。报告的 provenance 区分 DOM 与显式已观察数据。树使用节点状态保存草稿和确认值，菜单按组独立折叠并移动后续行，日历逆序选择会重新开始。数据表排序、筛选、分页需额外显式事件/区域绑定，当前组件不会自动计算业务数据。

默认 `appearance:"faithful"`。用户明确要求简化时，仅对指定组件设 `appearance:"plain"`，移除归属范围内底板、边框和装饰。透明文字只影响文字框；组件底板可能是另一个 DOM 或 Portal；页面背景属于画布，三者分别判断。plain 不能清除未归属的邻接或页面背景。复杂图标、装饰尚需检查 component-report 与目标预览，不能把原生组合映射自动视为像素保真。

多选需要区分草稿和已确认状态：打开从已确认值恢复；取消撤销草稿；确定保存并更新摘要。已有 57 项但只采到 2 项时，可以明确保留另外 55 项，不能凭两个演示项替换全量选择。树展开与多选级联分别验收，未实现级联应明确列出。

菜单用表格时，表格负责行布局，不自动承担层级行为。把子分组放进独立面板或可移动行组，折叠后收起空白并移动后续分组；不要把实际只隐藏图标的操作称为菜单折叠。

表格边框须检查单元格实际四边：Axure TableCell 的 left/top/right/bottom-border-width 与对应 color 独立于通用 MyStyle。无边框菜单和日历需要四边宽度均为 0；只检查通用 border.width 不足以证明网格已消失。验收应同时覆盖保留边框的数据表，并在目标编辑器导出的预览中检查。

## 覆盖记录与验收

在工作目录记录 component-mapping.md 或 JSON 清单：组件、来源选择器/证据、映射类型、原生/组合/图像、已实现行为、降级原因、未采集范围。优先检查可分解的可交互区域，随后处理局部图像。

CLI 自动写 component-report.json（capture/plan 使用产物名加 -component-report 后缀）。检查来源、消费图层、实现行为、缺失数据和诊断；import 返回组件 id 到实际 RP 节点 id 的映射。报告接入 --fail-on，不代表视觉/交互已通过。遇到未归属弹层、重复消费、无导航绑定、部分树或未知 Tab 内容必须先处理或明确降级。

验收应覆盖新映射产生的行为：多选确认后重开、修改后取消、树展开收起、菜单折叠后布局、Tab 回切、日期范围选择。先重新解析与结构检查，再在目标 Axure 预览实测。单纯节点数量、控件清单或结构通过不等于交互通过。
