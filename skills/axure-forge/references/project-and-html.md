# HTML 和项目

```bash
axure-forge html import ./site --page-size 1440x900 --output dashboard@v1.rp --verify --work-dir .forge
```

默认宽度固定，高度至少 900px 并随内容延展；`--page-mode fixed` 固定宽高，越界列入报告。旧 `--viewport '[1440,900]'` 保留，冲突参数报错。

命令一次完成计划、导入、重新解析和验证。先读取 `.forge/summary.json`：包含 RP、plan、index、report 路径、节点数和验收范围。完整数据留在磁盘，异常时才读详情。

显式查看计划或跨步骤复用：

```bash
axure-forge html plan ./site --page-size 1440x900 --output .forge/plan.json
axure-forge html import ./site --page-size 1440x900 --plan .forge/plan.json --output dashboard@v2.rp
```

计划绑定 HTML、实际资源、引擎版本、参数和字体配置。输入变化必须重新 plan；普通导入会自动失效并刷新缓存。显式计划失效则报错，不重新算一遍后悄悄替换。

可选 `--text-metrics FILE`：JSON 包含 `schema_version:1`、`source`、`version` 和 `factors:[{family,size,weight,factor}]`。默认用内置估算，不强制校准；配置不是 Axure 实测证明。

`data-forge-name` 可覆盖图层名；`data-axure-id` 用于原生组件映射。`--mapping FILE` 接受 JSON 文件。复杂交互见交互参考。

HTML 脚本、外部样式、远程资源和 CSS grid 不执行或不获取；报告会列出具体限制。画布是布局与检查契约，RP9 设计器本身使用可滚动画布。

已有项目加 `--project input.rp`。原有 project/page 命令仍可用，新增操作优先在 batch 内组合完成，避免多次打开文件。
