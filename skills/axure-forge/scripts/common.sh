#!/bin/bash
set -euo pipefail
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need_value() { [ "$#" -ge 2 ] && [ -n "$2" ] || fail "missing value for $1"; }
require_platform() {
  [ "$(uname -s)" = Darwin ] || fail 'v1 supports macOS only'
  [ "$(uname -m)" = arm64 ] || fail 'v1 requires macOS ARM64; no Intel binary is published'
}
check_axure() {
  local app="$1" plist executable version bundle major
  plist="$app/Contents/Info.plist"
  [ -f "$plist" ] || fail "Axure not found: $app; use --axure-path /path/to/Axure.app"
  bundle=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist" 2>/dev/null) || fail 'cannot identify Axure application'
  version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist" 2>/dev/null) || version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist" 2>/dev/null) || fail 'cannot determine Axure version'
  executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist" 2>/dev/null) || fail 'missing application executable metadata'
  major=${version%%.*}
  case "$major:$bundle" in 9:com.axure.AxureRP9|11:com.axure.AxureRP11) ;; *) fail "unsupported Axure application: $bundle ($version)" ;; esac
  [ -x "$app/Contents/MacOS/$executable" ] || fail 'Axure executable missing or not executable'
  printf 'axure_path=%s\naxure_version=%s\naxure_format_version=%s\n' "$app" "$version" "$major"
}

detect_environment() {
  local app="$1" preferred="$2" available='' info major default_version=9
  case "$preferred" in ''|9|11) ;; *) fail 'format-version must be 9 or 11' ;; esac
  if [ -n "$app" ]; then
    info=$(check_axure "$app") || return 1
    printf '%s\n' "$info"
    available=$(printf '%s\n' "$info" | sed -n 's/^axure_format_version=//p')
  else
    for major in 9 11; do
      app="${AXURE_APPLICATIONS_DIR:-/Applications}/Axure RP $major.app"
      if [ -f "$app/Contents/Info.plist" ]; then
        info=$(check_axure "$app") || return 1
        printf '%s\n' "$info"
        available="${available:+$available,}$major"
      fi
    done
  fi
  [ "$available" != 11 ] || default_version=11
  [ -z "$preferred" ] || default_version=$preferred
  printf 'available_format_versions=%s\ndefault_format_version=%s\n' "${available:-none}" "$default_version"
  if [ -z "$available" ]; then
    printf 'editor_validation=unavailable\n'
  fi
}

json_value() {
  printf '%s' "$1" | /usr/bin/plutil -extract "$2" raw -o - - 2>/dev/null
}
