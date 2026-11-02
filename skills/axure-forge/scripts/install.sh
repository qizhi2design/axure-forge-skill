#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"
app='/Applications/Axure RP 9.app'
version=v0.2.1
binary=''
checksum=''
bin_dir="$HOME/.local/bin"
force=0
download_method=curl
while [ "$#" -gt 0 ]; do
  case "$1" in
    --axure-path) need_value "$@"; app=$2; shift 2 ;;
    --version) need_value "$@"; version=$2; shift 2 ;;
    --binary-path) need_value "$@"; binary=$2; shift 2 ;;
    --checksum-path) need_value "$@"; checksum=$2; shift 2 ;;
    --bin-dir) need_value "$@"; bin_dir=$2; shift 2 ;;
    --force) force=1; shift ;;
    --download-method) need_value "$@"; download_method=$2; shift 2 ;;
    --help|-h) printf '%s\n' 'Usage: install.sh [--version v0.2.1] [--axure-path APP] [--bin-dir DIR] [--force]' 'Download: --download-method curl|gh|auto (default curl, no login)' 'Offline: --binary-path FILE --checksum-path SHA256SUMS' 'Existing compatible installs are reused; --force explicitly replaces them.'; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done
require_platform
check_rp9 "$app"
[[ "$version" =~ ^v0\.2\.[0-9]+$ ]] || fail 'supported release tags: v0.2.N'
case "$download_method" in auto|gh|curl) ;; *) fail 'download method must be auto, gh or curl' ;; esac
if [ -n "$binary" ] || [ -n "$checksum" ]; then
  [ -f "$binary" ] && [ -f "$checksum" ] || fail 'offline install needs both binary and SHA256SUMS'
fi
if [ -e "$bin_dir/axure-forge" ] && [ "$force" -eq 0 ]; then
  "$SCRIPT_DIR/doctor.sh" --axure-path "$app" --binary-path "$bin_dir/axure-forge"
  installed=$("$bin_dir/axure-forge" --version)
  [ "$installed" = "${version#v}" ] || fail "installed $installed differs from $version; use --force to upgrade"
  printf 'reused=%s\n' "$bin_dir/axure-forge"
  exit 0
fi
tmp=$(mktemp -d)
staged=''
cleanup() { rm -rf "$tmp"; if [ -n "$staged" ]; then rm -f "$staged"; fi; }
trap cleanup EXIT
verify() {
  local file=$1 sums=$2 expected actual name
  name=$(basename "$file")
  expected=$(awk -v name="$name" '$2 == name || $2 == "*" name {print $1}' "$sums")
  [[ "$expected" =~ ^[[:xdigit:]]{64}$ ]] || fail "missing or ambiguous SHA256 for $name"
  actual=$(shasum -a 256 "$file" | awk '{print $1}')
  [ "$actual" = "$expected" ] || fail "checksum mismatch: $name"
}
if [ -n "$binary" ]; then
  verify "$binary" "$checksum"
  cp "$binary" "$tmp/axure-forge"
else
  package="axure-forge-${version#v}-macos-arm64"
  asset="$package.tar.gz"
  base="https://github.com/qizhi2design/axureforge-cli/releases/download/$version"
  if [ "$download_method" = auto ]; then
    if command -v gh >/dev/null && gh auth status --hostname github.com >/dev/null 2>&1; then download_method=gh; else download_method=curl; fi
  fi
  if [ "$download_method" = gh ]; then
    command -v gh >/dev/null || fail 'gh unavailable; use default curl download or offline installation'
    gh release download "$version" --repo qizhi2design/axureforge-cli --pattern "$asset" --pattern SHA256SUMS --dir "$tmp" || fail 'GitHub download failed; use public curl download or offline installation'
  else
    curl --fail --location --retry 2 --connect-timeout 15 --max-time 180 "$base/$asset" -o "$tmp/$asset" || fail "Release download failed: $version; check public Release assets or use offline installation; no Python fallback"
    curl --fail --location --retry 2 --connect-timeout 15 --max-time 60 "$base/SHA256SUMS" -o "$tmp/SHA256SUMS" || fail 'checksum download failed'
  fi
  verify "$tmp/$asset" "$tmp/SHA256SUMS"
  tar -tzf "$tmp/$asset" > "$tmp/members"
  while IFS= read -r member; do
    case "$member" in
      "$package/axure-forge"|"$package/README.md"|"$package/LICENSE"|"$package/THIRD_PARTY_NOTICES.md"|"$package/THIRD_PARTY_LICENSES/"|"$package/THIRD_PARTY_LICENSES/"*.txt) ;;
      *) fail "unexpected archive contents: $member" ;;
    esac
    case "$member" in *../*) fail 'archive contains parent traversal' ;; esac
  done < "$tmp/members"
  tar -xzf "$tmp/$asset" -C "$tmp" -- "$package/axure-forge"
  [ -f "$tmp/$package/axure-forge" ] && [ ! -L "$tmp/$package/axure-forge" ] || fail 'binary must be a regular file'
  cp "$tmp/$package/axure-forge" "$tmp/axure-forge"
fi
chmod 755 "$tmp/axure-forge"
file "$tmp/axure-forge" | /usr/bin/grep -q 'Mach-O.*arm64' || fail 'expected macOS ARM64 executable'
[ "$("$tmp/axure-forge" --version)" = "${version#v}" ] || fail 'binary version differs from requested release'
"$SCRIPT_DIR/doctor.sh" --axure-path "$app" --binary-path "$tmp/axure-forge"
"$tmp/axure-forge" project create --name 'Installation check' --output "$tmp/check.rp" > /dev/null
"$tmp/axure-forge" project open --path "$tmp/check.rp" > /dev/null
mkdir -p "$bin_dir"
staged=$(mktemp "$bin_dir/.axure-forge.XXXXXX")
cp "$tmp/axure-forge" "$staged"
chmod 755 "$staged"
mv -f "$staged" "$bin_dir/axure-forge"
staged=''
printf 'installed=%s\n' "$bin_dir/axure-forge"
case ":$PATH:" in *":$bin_dir:"*) ;; *) printf 'Add to your shell profile: export PATH="%s:$PATH"\n' "$bin_dir" ;; esac
