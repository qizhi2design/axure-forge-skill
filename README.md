<p align="center">
  <img src="docs/images/banner.jpg" alt="AxureForge Skill —— 说一句话，改一个原型" width="100%">
</p>

<h1 align="center">AxureForge Skill</h1>

<p align="center"><b>说一句话，改一个原型。</b></p>
<p align="center">
  用日常语言让 AI 助手分析、新建和修改 Axure RP9/RP11 原型<br>
  不记命令，不碰文件格式。
</p>

<p align="center">
  <img alt="平台：Apple 芯片 Mac" src="https://img.shields.io/badge/platform-Apple%20Silicon-000000?logo=apple&logoColor=white">
  <img alt="适用于 Axure RP9/RP11" src="https://img.shields.io/badge/Axure-RP9%20%2F%20RP11-0A7AFF">
  <img alt="可与 Claude / Codex 配合" src="https://img.shields.io/badge/works%20with-Claude%20%7C%20Codex-7C3AED">
  <img alt="许可证 MIT" src="https://img.shields.io/badge/license-MIT-22C55E">
</p>

<p align="center">
  <img alt="HTML 转原型" src="https://img.shields.io/badge/HTML%E8%BD%AC%E5%8E%9F%E5%9E%8B-22D3EE?style=flat-square">
  <img alt="元件定位" src="https://img.shields.io/badge/%E5%85%83%E4%BB%B6%E5%AE%9A%E4%BD%8D-22D3EE?style=flat-square">
  <img alt="交互配置" src="https://img.shields.io/badge/%E4%BA%A4%E4%BA%92%E9%85%8D%E7%BD%AE-22D3EE?style=flat-square">
  <img alt="批量修改" src="https://img.shields.io/badge/%E6%89%B9%E9%87%8F%E4%BF%AE%E6%94%B9-22D3EE?style=flat-square">
</p>

<p align="center">
  <a href="#能做什么">能做什么</a> ·
  <a href="#它是怎么工作的">它是怎么工作的</a> ·
  <a href="#安装">安装</a> ·
  <a href="#怎么用">怎么用</a> ·
  <a href="#常见问题">常见问题</a>
</p>

## 能做什么

- 🔍 看清楚一个老原型的页面结构，不用一页页点开。
- 🔗 查清某个按钮或面板上挂了什么交互。
- 🌐 把现成的网页读成可以继续编辑的原型。
- ✏️ 批量改文案，比如把页面里的「提交」统一改成「确认提交」。
- 🧱 从零建一个项目，加上页面和按钮，先有个能讲的骨架。
- 👆 给按钮配交互，比如点一下，面板切换到另一个状态。

## 它是怎么工作的

整个过程分四步，中间的事它来做。

1. **你提需求** —— 用中文说一句就行。
2. **约定页面与画布** —— 新建或大幅改版时，一次确认页面范围、宽度、首屏高度和长页延展方式；已有约定直接沿用。
3. **生成或修改 .rp** —— AI 可参考内置看板、列表表单或移动端 HTML 模板，由 AxureForge 自动计算布局并检查输出。
4. **你在 Axure 里打开验收** —— 看效果，不满意就接着说。

## 使用前准备

- 一台 Apple 芯片的 Mac（M 系列芯片）。
- 安装和生成不要求已安装 Axure；原生视觉验收时使用对应 RP9/RP11 编辑器。
- 不需要另外安装运行环境，AxureForge 装好就能用。

## 安装

第一条命令只是看看这个仓库里有什么：

```bash
npx skills add qizhi2design/axure-forge-skill --list
```

第二条命令把 AxureForge 装到你的 AI 助手里：

```bash
npx skills add qizhi2design/axure-forge-skill --skill axure-forge --agent codex --global
```

安装会用到 `npx` 命令。如果提示找不到这个命令，先装一次 npm（npm 官网有安装包）再回来。
所需的程序从公开下载页获取（[axureforge-cli](https://github.com/qizhi2design/axureforge-cli)），不需要登录。

装好以后，在 AI 助手里用 `$axure-forge` 就能唤起它。

## 怎么用

直接用中文说需求就行，不用记命令。

| 你说的话 | 它会做什么 |
| --- | --- |
| `$axure-forge 检查 RP9 环境` | 确认本机的 Axure RP9 能不能配合工作，缺什么会直接说。 |
| `$axure-forge 分析 ./demo.rp 的页面和交互` | 列出有哪些页面、页面上有什么元件、挂了什么交互。 |
| `$axure-forge 将 ./site 转换为 ./demo.rp` | 把网页文件夹读成可编辑的原型，另存为新文件。 |
| `$axure-forge 将 ./demo.rp 中「提交」改为「确认提交」，另存为 ./edited.rp` | 找到文字所在位置，改完另存，原文件不动。 |
| `$axure-forge 创建两个状态的面板，并为按钮添加切换交互` | 新建两状态面板，把按钮接上「点击切换状态」。 |

第一次使用会嗅探 RP9/RP11 环境并检查 v3 能力，再准备需要的程序。已经装过且版本合适的会直接复用。

## 可选设置

- Axure 没装在默认位置（自动嗅探「应用程序」中的 RP9/RP11）：直接告诉它你的安装路径。
- 想装到别的位置：默认装在 `~/.local/bin`，也可以指定别的目录。
- 升级或覆盖：想换新版本时明确说明；不说明时继续用已经装好的。
- 离线安装：手上有安装包和校验文件（用来确认下载完整）时，可以从本地装。

当前 skill 要求协议 v3；历史同版本号的旧二进制不一定兼容。更多安装选项见 [安装说明](skills/axure-forge/references/installation.md)。

## 常见问题

<details>
<summary><b>装好了，但 AI 助手里没反应？</b></summary>

先确认是用 `$axure-forge` 唤起它的。第一次运行会嗅探编辑器环境并检查需要的程序，稍等一下。

</details>

<details>
<summary><b>提示找不到 npx 命令？</b></summary>

先装一次 npm（npm 官网有安装包），装好再回来跑安装命令。

</details>

<details>
<summary><b>改动会覆盖原文件吗？</b></summary>

默认另存为新文件，不会覆盖你的原文件。要覆盖必须你明确要求。

</details>

<details>
<summary><b>Axure 没装在默认位置怎么办？</b></summary>

直接告诉它你的安装路径。自动嗅探「应用程序」中的 RP9/RP11，也支持指定自定义位置。

</details>

<details>
<summary><b>能处理 Axure RP11 的文件吗？</b></summary>

可以读取、编辑和保存 RP11，也支持预检后严格转换；已有文件默认保持源格式。

</details>

<details>
<summary><b>支持 Windows 或 Intel 芯片的 Mac 吗？</b></summary>

目前只支持 Apple 芯片的 Mac（M 系列芯片）。

</details>

## 使用提醒

- Axure RP11 的文件可以读取、编辑和保存 RP11，也支持预检后严格转换；已有文件默认保持源格式。
- 修改默认另存为新文件，不会覆盖你的原文件。要覆盖必须你明确要求。
- 自动检查只验证文件结构和属性。交互效果请在 Axure 里实际预览确认。
- 网页转原型不是 100% 还原。浏览器里的脚本和复杂排版可能对不上，转完要自己过一遍。

## 仓库里有什么

<details>
<summary><b>展开看目录结构</b></summary>

- `skills/axure-forge/` —— 分发给 AI 助手的目录，安装时用的就是这里。
- `docs/images/` —— 顶部那张横幅图。
- `tests/` —— 维护者自测用的检查脚本，普通使用者用不到。

</details>

## 许可证

AxureForge Skill 采用 MIT 许可证，全文见 [LICENSE](LICENSE)。
随包提供的 AxureForge 程序也采用 MIT 许可证。
