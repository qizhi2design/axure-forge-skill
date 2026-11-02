# HTML 模板

这些模板是可复制的原型起点，尺寸与业务示例不是用户已确认的需求。先按 SKILL.md 完成画布约定，再选择一份模板；不要一次读完所有模板。

| 模板 | 建议画布 | 用途 |
| --- | --- | --- |
| [桌面看板](../assets/html-templates/desktop-dashboard.html) | 宽 1440、首屏高 900，auto | 侧栏、关键指标、任务列表和来源分布 |
| [桌面列表与表单](../assets/html-templates/desktop-list-form.html) | 宽 1440、首屏高 900，auto | 搜索筛选、表格、侧边编辑表单 |
| [移动端详情](../assets/html-templates/mobile-detail.html) | 宽 390、首屏高 844，auto | 顶栏、详情、跟进记录和底部操作 |

机器可读目录：[manifest.json](../assets/html-templates/manifest.json)。先读目录或本表，仅加载选中的 HTML。列表、表单和详情可以组合为多页流程，不要求套用示例行业、文案或全部模块。

## 使用

1. 复制选中的模板到任务工作目录，保留 skill 内的原文件。尺寸、固定区域与页面范围依照已确认约定；修改根 `.frame` / `.screen` 的 width、min-height，并给 CLI 传同样的 `--page-size`。固定画布使用 `--page-mode fixed`，检查超出内容。
2. 替换业务文案和数据，删去无关模块，按用户品牌调整色彩与字体。复用 flex、百分比及内容流约束，侧栏之外的容器由 CLI 自动计算，不要求 AI 为每张卡片反复手算坐标或宽度。
3. `data-forge-name` 用于可读图层名；`data-axure-id` 用于组件/事件映射，同一页面内应唯一。复制模块时更新 ID。HTML 原生按钮、输入框并不代表已经配置好 Axure 业务交互；根据任务添加 mapping，再分别汇报结构、布局估算、视觉和交互验证范围。

```bash
# 假设画布已经确认，并已复制、修改模板：
axure-forge html import ./site --page-size 1440x900 --page-mode auto --output prototype@v1.rp --verify
```

模板均为单文件 HTML，使用内嵌 CSS、系统字体、block/flex/table 与原生表单，不依赖 JS、网络图片、外部样式、SVG 或 CSS grid。模板是低成本结构参考，不是任意 CSS 的还原保证。长页总高度取决于真实内容；移动端底部操作区随文档流排布，不预设吸底交互。

## 版本与验收

三份模板在包含盒模型零值修复的源码 CLI 中已通过 `--fail-on warn`，无不支持项。已发布 CLI 0.3.0 可导入这些模板，但会保留默认描边、内边距相关警告；检查实际 report，不将告警或结构通过描述为视觉通过。0.4.0 发布包包含该修复；使用 0.3.0 的用户需要升级，既有安装不会自动替换。

维护者可运行 `node tests/templates.mjs /ABS/axure-forge --strict` 复验；普通模式保留旧 CLI 告警，严格模式要求 0 error / 0 warn。此脚本用于仓库维护，不要求使用 skill 的用户安装 Node。
