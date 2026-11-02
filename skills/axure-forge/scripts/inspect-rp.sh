#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"
app=''
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
[ -z "$app" ] || check_axure "$app" >&2
[ -n "$project" ] && [ -f "$project" ] || fail '--project must name an existing file'
# Explicit bytes avoid host-endian assumptions. This is a format gate, not a full parser.
read -r b1 b2 b3 b4 < <(od -An -tu1 -N4 "$project") || fail 'truncated RP header'
[ "${b1:-}" = 172 ] && [ "${b2:-}" = 239 ] || fail 'invalid RP signature'
[ -n "${b3:-}" ] && [ -n "${b4:-}" ] || fail 'truncated RP header'
version=$((b3 + b4 * 256))
case "$version" in 9|11) ;; *) fail "RP$version is not supported; no automatic conversion" ;; esac
printf '{"format_version":%d,"supported":true,"validation":"header_only"}\n' "$version"
