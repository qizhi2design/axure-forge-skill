# AxureForge Skill v0.5.0

Requires CLI 0.5.0 or later, protocol v3, and an Apple-silicon Mac.

- Updates instructions for English CLI help, version display, JSON errors, exit codes, and `--debug` diagnostics.
- Uses kebab-case command groups; internal batch operation names remain unchanged.
- Doctor verifies the renamed command groups and host-browser import capabilities, so an older incompatible CLI is not silently reused.
- Includes the existing host-browser capture guidance and native composite widget workflow.
- Installation remains runtime-free and supports validated offline directory packages. Release manifests include compatibility information and managed-file hashes.

Install with:

```bash
npx skills add qizhi2design/axure-forge-skill --skill axure-forge --agent codex --global
```

Or update an existing installation with `axure-forge update all --path /ABS/SKILL --dry-run`, then `axure-forge update all --path /ABS/SKILL --yes`. Reload the skill or start a new session after updating.
