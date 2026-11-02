# 项目、页面与 HTML

```bash
axure-forge project create --name Demo --first-page 首页 --output demo.rp
axure-forge project open --path demo.rp
axure-forge page list --project demo.rp
axure-forge page create --project demo.rp --name 详情 --output two-pages.rp
axure-forge page rename --project two-pages.rp --page-id PAGE_ID --name 商品详情 --output renamed.rp
```

响应 `result.pages[]` 提供页面 `id`。使用 `page get --project FILE --page-id ID` 获取详情，其中 `scope_id` 是创建元件所需的作用域；页面 ID 与 scope ID 不保证相同，不能混用。删除页面使用 `page delete`，有子页面时先查看 `--help`。

```bash
axure-forge html import ./site --output imported.rp
axure-forge html import ./index.html --page-name 首页 --viewport '[1440,900]' --output imported.rp
```

目录输入读取 `index.html`，相对资源以 HTML 所在目录解析。`--viewport` 是 JSON 数组，`--mapping` 是结构化 JSON，详细参数只在需要时查 `html import --help`。导入现有项目时指定 `--project input.rp`，输出必须另存。

导入后重新 `project open`，检查页面名，再搜索关键文本。HTML/CSS 只支持引擎已实现的映射；不要承诺浏览器脚本和所有布局无损还原。新建文件写出目标为 RP9；RP11 不自动降级。
