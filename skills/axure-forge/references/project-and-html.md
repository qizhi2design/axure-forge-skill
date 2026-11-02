# HTML 和项目

创作前先按 SKILL.md 约定页面范围和画布规格。下方 `1440x900` 是命令示例，应替换为已确认的尺寸；技术默认值不代表用户选择。需要 HTML 起点时见 [HTML 模板](html-templates.md)。

```bash
axure-forge html import ./site --page-size 1440x900 --format-version 9 --output dashboard@v1.rp --verify --work-dir .forge
```

`auto` 模式宽度固定，高度以传入值为下限并随内容延展；`--page-mode fixed` 固定宽高，越界列入报告。旧 `--viewport '[1440,900]'` 保留，冲突参数报错。

命令一次完成计划、导入、重新解析和验证。先读取 `.forge/summary.json`：包含 RP、plan、index、report 路径、节点数和验收范围。完整数据留在磁盘，异常时才读详情。

显式查看计划或跨步骤复用：

```bash
axure-forge html plan ./site --page-size 1440x900 --format-version 9 --output .forge/plan.json
axure-forge html import ./site --page-size 1440x900 --plan .forge/plan.json --output dashboard@v2.rp
```

计划绑定 HTML、实际资源、引擎版本、参数和字体配置。输入变化必须重新 plan；普通导入会自动失效并刷新缓存。显式计划失效则报错，不重新算一遍后悄悄替换。

可选 `--text-metrics FILE`：JSON 包含 `schema_version:1`、`source`、`version` 和 `factors:[{family,size,weight,factor}]`。默认用内置估算，不强制校准；配置不是 Axure 实测证明。

`data-forge-name` 可覆盖图层名；`data-axure-id` 用于原生组件映射。`--mapping FILE` 接受 JSON 文件。复杂交互见交互参考。

HTML 脚本、外部样式、远程资源和 CSS grid 不执行或不获取；报告会列出具体限制。画布是布局与检查契约，RP9 设计器本身使用可滚动画布。

新建文件使用本任务从 `doctor.sh` 或用户约定得到的格式，例如 `--format-version 11`。未传时 CLI 默认 9；skill 应显式传入选择。已有项目加 `--project input.rp`，保持源版本，不使用新建默认值；显式版本与源文件不一致会被拒绝。原有 project/page 命令仍可用，新增操作优先在 batch 内组合完成，避免多次打开文件。


## 格式与转换

```bash
axure-forge project create --format-version 11 --output new11.rp
axure-forge project check-conversion --project source9.rp --target-version 11
axure-forge project convert --project source9.rp --target-version 11 --output converted11.rp
```

仅支持 9 与 11。先检查 `ok`，读取转换报告；阻断诊断位于 `error.details.report`。转换包含未保存的应用编辑，但返回独立项目，源文件保持不变。目标必须与源路径不同，已存在的目标遵守 `--force`。预检通过不代表已经转换或完成原生编辑器验收。
