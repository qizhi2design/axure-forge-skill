# Validation — 2026-11-02

- Skill metadata: official skill-creator quick_validate passed (PyYAML is a developer-only validation dependency).
- Discovery: `npx skills add . --list` found `axure-forge` under `skills/axure-forge/`.
- Shell environment tests: RP9 actual application metadata recognized as 9.0.0.3746; renamed app fixture accepted; missing app, wrong version and missing executable rejected.
- File gate: RP9 header accepted; RP11, truncated and invalid signatures rejected. A header-only fake file is separately rejected by full CLI parsing.
- Installation: real local Mach-O binary installed to temporary directory and reused; checksum mismatch and incomplete offline arguments rejected while old binary bytes stayed unchanged.
- Simulated Release download: archive, SHA256SUMS, native architecture/version, and temporary creation/reopen checks passed with a whitelist PATH containing no Python, pip, uv, Node, npm or Git. Unexpected archive members and unsupported OS rejected.
- Business smoke: 19 real binary commands passed: project/page creation, search, panel state event, repeater data replacement, batch editing, reopen, output protection, batch failure without output, and HTML import.
- Native designer: generated `多页项目.rp` opened in installed RP9 without an error dialog; screenshot inspection confirmed `Page 1` and `新增页面` in the page list. This verifies opening and page structure only. Interactive preview behavior was not tested.
- Upstream release PR: macOS ARM64, Ubuntu x64 and Windows x64 binary CI passed at commit f6b3870. Windows required explicit resource packaging and UTF-8 resource/protocol handling.

Distribution correction: the source repository is private; the consumer source is
the existing public `qizhi2design/axureforge-cli` repository. Version 0.2.1 was
built and verified natively in CI run 41407286717, then published there with the
existing versioned directory/archive convention and third-party licenses. The
installer defaults to anonymous curl downloads and minimum CLI 0.2.1.

Reproduce using `bash tests/run.sh BINARY` and `bash tests/install-download.sh BINARY`. Consumers do not need the developer test tools.

Final 0.2.1 distribution checks:
- Anonymous curl download from public GitHub Release, SHA256SUMS verification,
  startup/capability checks and global installation passed. `axure-forge --version`
  returned 0.2.1 from ~/.local/bin.
- Versioned public archive layout tests passed with no external runtime in PATH;
  checksum mismatch, unexpected archive members and platform rejection passed.
- Doctor now reads the root CLI help once instead of starting one process per
  domain; metadata validation passed again.
- Final observed installed-binary version startup was 27.10 seconds on this host;
  prior candidate startup was 57.82 seconds. No cross-platform startup claim.
- Final public 0.2.1 business smoke completed: all 19 CLI commands passed,
  including HTML import, panel event round-trip, repeater data and failed-batch
  output protection. Native designer inspection above used the prior 0.2.0
  development candidate; the public 0.2.1 smoke was structural only.
