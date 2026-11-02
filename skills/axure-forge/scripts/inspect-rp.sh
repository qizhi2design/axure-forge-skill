#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"
app='/Applications/Axure RP 9.app'
project=''
while [ "$#" -gt 0 ]; do
  case "$1" in
    --axure-path) need_value "$@"; app=$2; shift 2 ;;
    --project) need_value "$@"; project=$2; shift 2 ;;
    --help|-h) printf '%s\n' 'Usage: inspect-rp.sh --project FILE [--axure-path APP]'; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done
require_platform
check_rp9 "$app" >&2
[ -n "$project" ] && [ -f "$project" ] || fail '--project must name an existing file'
# Explicit bytes avoid host-endian assumptions. This is a format gate, not a full parser.
read -r b1 b2 b3 b4 < <(od -An -tu1 -N4 "$project") || fail 'truncated RP header'
[ "${b1:-}" = 172 ] && [ "${b2:-}" = 239 ] || fail 'invalid RP signature'
[ -n "${b3:-}" ] && [ -n "${b4:-}" ] || fail 'truncated RP header'
version=$((b3 + b4 * 256))
printf '{"format_version":%d,"is_rp9":%s,"validation":"header_only"}\n' "$version" "$([ "$version" -eq 9 ] && printf true || printf false)"
[ "$version" -eq 9 ] || fail "RP$version is not supported for editing; no automatic conversion"
