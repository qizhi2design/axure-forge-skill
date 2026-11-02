#!/bin/bash
set -euo pipefail
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need_value() { [ "$#" -ge 2 ] && [ -n "$2" ] || fail "missing value for $1"; }
require_platform() {
  [ "$(uname -s)" = Darwin ] || fail 'v1 supports macOS only'
  [ "$(uname -m)" = arm64 ] || fail 'v1 requires macOS ARM64; no Intel binary is published'
}
check_rp9() {
  local app="$1" plist executable version bundle
  plist="$app/Contents/Info.plist"
  [ -f "$plist" ] || fail "RP9 not found: $app; use --axure-path /path/to/Axure.app"
  bundle=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist" 2>/dev/null) || fail 'cannot identify Axure application'
  version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist" 2>/dev/null) || version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist" 2>/dev/null) || fail 'cannot determine Axure version'
  executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist" 2>/dev/null) || fail 'missing application executable metadata'
  [ "$bundle" = com.axure.AxureRP9 ] || fail "requires Axure RP9, found $bundle"
  case "$version" in 9.*) ;; *) fail "requires RP9, found $version" ;; esac
  [ -x "$app/Contents/MacOS/$executable" ] || fail 'RP9 executable missing or not executable'
  printf 'axure_path=%s\naxure_version=%s\n' "$app" "$version"
}
