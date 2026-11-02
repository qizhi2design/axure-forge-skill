# 项目、页面与 HTML

```bash
axure-forge project create --name Demo --first-page 首页 --output demo.rp
axure-forge project open --path demo.rp
axure-forge page list --project demo.rp
axure-forge page create --project demo.rp --name 详情 --output two-pages.rp
axure-forge page rename --project two-pages.rp --page-id PAGE_ID --name 商品详情 --output renamed.rp
```

返回的 `result.pages[]` 里有页面的 `id`。看详情用 `page get --project FILE --page-id ID`，其中的 `scope_id` 是新建元件时要放的位置标识。

页面 ID 和 `scope_id` 不一定相同，不能混用。删页面用 `page delete`；页面下还有子页面时，先看 `--help`。

```bash
axure-forge html import ./site --output imported.rp
axure-forge html import ./index.html --page-name 首页 --viewport '[1440,900]' --output imported.rp
```

传目录时，程序会自动读目录里的 `index.html`，图片等资源按 HTML 所在目录去找。

`--viewport` 要写 JSON 数组，`--mapping` 要写结构化 JSON；详细参数需要时查 `html import --help`。导入到已有项目时加 `--project input.rp`，输出必须另存成新文件。

导入完重新用 `project open` 打开，先看页面名对不对，再搜关键文字。

HTML/CSS 只支持已经实现的转换规则，不要承诺网页脚本和所有布局都能原样还原。新建文件的输出格式是 RP9；RP11 的文件不会自动转成 RP9。
