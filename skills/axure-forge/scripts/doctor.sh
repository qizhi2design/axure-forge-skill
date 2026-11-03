#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"
app=''; binary=''; preferred=''; app_only=0; check_updates=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --axure-path) need_value "$@"; app=$2; shift 2 ;;
    --binary-path) need_value "$@"; binary=$2; shift 2 ;;
    --format-version) need_value "$@"; preferred=$2; shift 2 ;;
    --check-updates) check_updates=1; shift ;;
    --app-only) app_only=1; shift ;;
    --help|-h) printf '%s\n' 'Usage: doctor.sh [--axure-path APP] [--binary-path CLI] [--format-version 9|11] [--app-only] [--check-updates]' 'Editors are optional. Only RP11 detected: default 11; otherwise default 9. Explicit format wins.'; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done
require_platform
detect_environment "$app" "$preferred"
[ "$app_only" -eq 0 ] || exit 0
if [ -z "$binary" ]; then
  binary=$(command -v axure-forge || true)
  if [ -z "$binary" ] && [ -x "$HOME/.local/bin/axure-forge" ]; then binary="$HOME/.local/bin/axure-forge"; fi
fi
[ -n "$binary" ] && [ -x "$binary" ] || fail 'CLI missing; run install.sh'
capabilities=$("$binary" capabilities --json) || fail 'CLI capabilities unavailable; install a protocol-v3 build'
[ "$(json_value "$capabilities" schema_version)" = 3 ] && [ "$(json_value "$capabilities" ok)" = true ] || fail 'CLI must return a successful protocol-v3 envelope; old v2 builds are incompatible'
[ "$(json_value "$capabilities" result.protocol_version)" = 3 ] || fail 'CLI lacks protocol v3'
[ "$(json_value "$capabilities" result.batch.atomic)" = true ] && [ "$(json_value "$capabilities" result.batch.external_writes)" = false ] || fail 'CLI lacks atomic editing batches'
version=$(json_value "$capabilities" result.version) || fail 'missing CLI version'
for slot in 0 1; do
  expected=9; [ "$slot" = 0 ] || expected=11
  [ "$(json_value "$capabilities" "result.supported_versions.$slot")" = "$expected" ] || fail 'CLI must support RP9 and RP11'
  [ "$(json_value "$capabilities" "result.formats.$slot.version")" = "$expected" ] || fail 'invalid format capability declaration'
  for ability in read edit write; do
    [ "$(json_value "$capabilities" "result.formats.$slot.$ability")" = true ] || fail "CLI lacks RP$expected $ability"
  done
done
for command in 'html import' 'html plan' 'dump' 'verify' 'batch' 'project check-conversion' 'project convert' 'adaptive-view list' 'adaptive-view-set list' 'interaction-style get' 'master-folder get' 'master-instance get' 'master-tree get' 'page-tree get' 'web prepare' 'web capture' 'web plan' 'web import'; do
  printf '%s' "$capabilities" | /usr/bin/plutil -extract "result.cli.$command" json -o - - >/dev/null 2>&1 || fail "CLI lacks $command"
done
html_cli=$(printf '%s' "$capabilities" | /usr/bin/plutil -extract 'result.cli.html import' json -o - -)
case "$html_cli" in *'"--format-version"'*) ;; *) fail 'CLI HTML import lacks explicit format selection' ;; esac
printf 'cli_path=%s\ncli_version=%s\nprotocol_version=3\n' "$binary" "$version"
if ! command -v axure-forge >/dev/null; then printf 'PATH: add %s to PATH\n' "$(dirname "$binary")" >&2; fi

skill_version=$(/usr/bin/plutil -extract version raw -o - "$SCRIPT_DIR/../skill-manifest.json" 2>/dev/null || printf 'unknown')
printf 'skill_version=%s\n' "$skill_version"
if [ "$check_updates" -eq 1 ]; then
  if printf '%s' "$capabilities" | /usr/bin/plutil -extract 'result.cli.update check' json -o - - >/dev/null 2>&1; then
    "$binary" update check --path "$SCRIPT_DIR/.." --json
  else
    printf '%s\n' 'update_check=unsupported; 当前 CLI 没有更新入口，请先安装支持更新的新版本。'
  fi
fi
