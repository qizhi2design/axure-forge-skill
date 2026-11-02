#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"
app='/Applications/Axure RP 9.app'
binary=''
rp9_only=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --axure-path) need_value "$@"; app=$2; shift 2 ;;
    --binary-path) need_value "$@"; binary=$2; shift 2 ;;
    --rp9-only) rp9_only=1; shift ;;
    --help|-h) printf '%s\n' 'Usage: doctor.sh [--axure-path APP] [--binary-path CLI] [--rp9-only]'; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done
require_platform
check_rp9 "$app"
[ "$rp9_only" -eq 0 ] || exit 0
if [ -z "$binary" ]; then
  binary=$(command -v axure-forge || true)
  if [ -z "$binary" ] && [ -x "$HOME/.local/bin/axure-forge" ]; then binary="$HOME/.local/bin/axure-forge"; fi
fi
[ -n "$binary" ] && [ -x "$binary" ] || fail 'CLI missing; run install.sh'
capabilities=$("$binary" capabilities --json) || fail 'CLI capabilities unavailable; install v0.3.0 explicitly'
version=$(printf '%s' "$capabilities" | sed -n 's/.*"version": "\([0-9][0-9.]*\)".*/\1/p')
[[ "$version" =~ ^0\.3\.[0-9]+$ ]] || fail "unsupported CLI version: $version; expected 0.3.x"
for command in 'html.plan' 'html.import' 'dump' 'verify' 'batch'; do
  case "$capabilities" in *\""$command"\"*) ;; *) fail "CLI lacks $command" ;; esac
done
printf 'cli_path=%s\ncli_version=%s\n' "$binary" "$version"
if ! command -v axure-forge >/dev/null; then printf 'PATH: add %s to PATH\n' "$(dirname "$binary")" >&2; fi
