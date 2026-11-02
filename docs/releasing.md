# Skill 发布流程

CLI 和 skill 独立发版；不要覆盖既有 tag 或同版本资源。以下命令以 0.4.0 为例，后续发布需替换为新的版本。

1. 修改 skill 后刷新文件哈希与兼容范围：

   ```bash
   python3 scripts/package_release.py --version 0.4.0 --cli-min 0.4.0
   ```

   可通过 `--cli-max 0.5.0` 设置不包含上限；默认不设置上限。当前 skill 平台仍为 macOS ARM64。

2. 使用真实 CLI 运行 `bash tests/run.sh /ABS/axure-forge`，并运行 `bash tests/install-download.sh /ABS/axure-forge`、`bash tests/update-offline.sh /ABS/axure-forge`。
3. 提交更新后的 `skill-manifest.json` 和对应内容，在此提交创建新 tag。
4. 从同一提交生成发布包：

   ```bash
   python3 scripts/package_release.py --version 0.4.0 --cli-min 0.4.0 --output dist/release-0.4.0
   ```

5. 将完整目录中的 `release-manifest.json`、`SHA256SUMS`、`axure-forge-skill-0.4.0.tar.gz` 一起附加到对应的正式 GitHub Release。不要将自动生成的 GitHub 源码压缩包当作 skill 更新包。

`npx skills add` 继续从 `skills/axure-forge` 安装；CLI 更新使用带校验清单的 Release。先发布满足兼容范围的 CLI，再发布依赖它的 skill。只完成代码修改不代表新版本已在线上可用。
