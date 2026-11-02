#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"
app=''; preferred=''
version=v0.3.0
binary=''; checksum=''; package_dir=''
bin_dir="$HOME/.local/bin"
force=0; download_method=curl
while [ "$#" -gt 0 ]; do
  case "$1" in
    --axure-path) need_value "$@"; app=$2; shift 2 ;;
    --format-version) need_value "$@"; preferred=$2; shift 2 ;;
    --version) need_value "$@"; version=$2; shift 2 ;;
    --binary-path) need_value "$@"; binary=$2; shift 2 ;;
    --package-dir) need_value "$@"; package_dir=$2; shift 2 ;;
    --checksum-path) need_value "$@"; checksum=$2; shift 2 ;;
    --bin-dir) need_value "$@"; bin_dir=$2; shift 2 ;;
    --force) force=1; shift ;;
    --download-method) need_value "$@"; download_method=$2; shift 2 ;;
    --help|-h) printf '%s\n' 'Usage: install.sh [--version v0.3.0] [--axure-path APP] [--bin-dir DIR] [--format-version 9|11] [--force]' 'Online: --download-method curl|gh|auto' 'Offline: --package-dir DIR --checksum-path SHA256SUMS (whole directory, relative file paths)' 'Legacy single-file offline: --binary-path FILE --checksum-path SHA256SUMS'; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done
require_platform
detect_environment "$app" "$preferred"
[[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'supported release tags: vX.Y.Z'
case "$download_method" in auto|gh|curl) ;; *) fail 'download method must be auto, gh or curl' ;; esac
[ -z "$binary" ] || [ -z "$package_dir" ] || fail 'choose package-dir or binary-path'
if [ -e "$bin_dir/axure-forge" ] && [ "$force" -eq 0 ]; then
  installed=$("$bin_dir/axure-forge" --version) || fail 'installed CLI failed; use --force explicitly'
  [ "$installed" = "${version#v}" ] || fail "installed $installed differs from $version; use --force to upgrade"
  doctor_args=(--binary-path "$bin_dir/axure-forge")
  [ -z "$app" ] || doctor_args+=(--axure-path "$app")
  [ -z "$preferred" ] || doctor_args+=(--format-version "$preferred")
  bash "$SCRIPT_DIR/doctor.sh" "${doctor_args[@]}"
  printf 'reused=%s\n' "$bin_dir/axure-forge"
  exit 0
fi
tmp=$(mktemp -d); staged=''; link=''
cleanup() { rm -rf "$tmp"; if [ -n "$staged" ]; then rm -rf "$staged"; fi; if [ -n "$link" ]; then rm -f "$link"; fi; }
trap cleanup EXIT
verify() {
  local file=$1 sums=$2 expected actual name
  name=$(basename "$file")
  expected=$(awk -v name="$name" '$2 == name || $2 == "*" name {print $1}' "$sums")
  [[ "$expected" =~ ^[[:xdigit:]]{64}$ ]] || fail "missing or ambiguous SHA256 for $name"
  actual=$(shasum -a 256 "$file" | awk '{print $1}')
  [ "$actual" = "$expected" ] || fail "checksum mismatch: $name"
}
if [ -n "$package_dir" ]; then
  [ -d "$package_dir/_internal" ] && [ -f "$package_dir/axure-forge" ] && [ -f "$checksum" ] || fail 'offline directory needs executable, _internal and SHA256SUMS'
  package_dir=$(cd "$package_dir" && pwd)
  checksum=$(cd "$(dirname "$checksum")" && pwd)/$(basename "$checksum")
  while read -r hash member; do
    [[ "$hash" =~ ^[[:xdigit:]]{64}$ ]] || fail 'invalid checksum manifest'
    case "$member" in /*|*..*|*\\*) fail 'invalid checksum path' ;; esac
  done < "$checksum"
  (cd "$package_dir" && shasum -a 256 -c "$checksum" > /dev/null) || fail 'package checksum mismatch'
  # Reject extra unchecked files and links in an offline package.
  while IFS= read -r member; do
    relative=${member#"$package_dir/"}
    expected=$(awk -v name="$relative" '$2 == name {print $1}' "$checksum")
    [ -n "$expected" ] || fail "unchecked package member: $relative"
  done < <(find "$package_dir" -type f)
  [ -z "$(find "$package_dir" -type l -print -quit)" ] || fail 'offline package links are not supported'
  cp -R "$package_dir" "$tmp/package"
elif [ -n "$binary" ]; then
  [ -f "$binary" ] && [ -f "$checksum" ] || fail 'offline install needs binary and SHA256SUMS'
  [ ! -d "$(dirname "$binary")/_internal" ] || fail 'directory executable requires --package-dir; copying one file loses dependencies'
  verify "$binary" "$checksum"
  mkdir "$tmp/package"
  cp "$binary" "$tmp/package/axure-forge"
else
  package="axure-forge-${version#v}-macos-arm64"
  asset="$package.tar.gz"
  base="https://github.com/qizhi2design/axureforge-cli/releases/download/$version"
  if [ "$download_method" = auto ]; then
    if command -v gh >/dev/null && gh auth status --hostname github.com >/dev/null 2>&1; then download_method=gh; else download_method=curl; fi
  fi
  if [ "$download_method" = gh ]; then
    gh release download "$version" --repo qizhi2design/axureforge-cli --pattern "$asset" --pattern SHA256SUMS --dir "$tmp" || fail 'GitHub download failed'
  else
    curl --fail --location --retry 2 --connect-timeout 15 --max-time 180 "$base/$asset" -o "$tmp/$asset" || fail 'Release download failed; no source build fallback'
    curl --fail --location --retry 2 --connect-timeout 15 --max-time 60 "$base/SHA256SUMS" -o "$tmp/SHA256SUMS" || fail 'checksum download failed'
  fi
  verify "$tmp/$asset" "$tmp/SHA256SUMS"
  tar -tzf "$tmp/$asset" > "$tmp/members"
  while IFS= read -r member; do
    case "$member" in /*|*../*|*/..|*\\*) fail "invalid archive path: $member" ;; esac
    case "$member" in "$package/"|"$package/axure-forge"|"$package/_internal/"*|"$package/README.md"|"$package/LICENSE"|"$package/THIRD_PARTY_NOTICES.md"|"$package/THIRD_PARTY_LICENSES/"*) ;; *) fail "unexpected archive contents: $member" ;; esac
  done < "$tmp/members"
  tar -tvzf "$tmp/$asset" > "$tmp/types"
  if /usr/bin/grep -Eq '^[lh]' "$tmp/types"; then fail 'archive links are not supported'; fi
  tar -xzf "$tmp/$asset" -C "$tmp"
  mv "$tmp/$package" "$tmp/package"
fi
chmod 755 "$tmp/package/axure-forge"
file "$tmp/package/axure-forge" | /usr/bin/grep -q 'Mach-O.*arm64' || fail 'expected macOS ARM64 executable'
[ "$("$tmp/package/axure-forge" --version)" = "${version#v}" ] || fail 'binary version differs from requested release'
doctor_args=(--binary-path "$tmp/package/axure-forge")
[ -z "$app" ] || doctor_args+=(--axure-path "$app")
[ -z "$preferred" ] || doctor_args+=(--format-version "$preferred")
bash "$SCRIPT_DIR/doctor.sh" "${doctor_args[@]}"
for format in 9 11; do
  (cd "$tmp" && ./package/axure-forge project create --name 'Installation check' --format-version "$format" --output "check$format.rp" > /dev/null && ./package/axure-forge dump --project "check$format.rp" > /dev/null)
done
mkdir -p "$bin_dir/.axure-forge"
staged=$(mktemp -d "$bin_dir/.axure-forge/${version#v}.XXXXXX")
cp -R "$tmp/package/." "$staged/"
# Validate final relocated directory before atomically switching the public command.
[ "$("$staged/axure-forge" --version)" = "${version#v}" ] || fail 'relocated package failed'
link="$bin_dir/.axure-forge-link.$$"
ln -s "$staged/axure-forge" "$link"
mv -f "$link" "$bin_dir/axure-forge"
link=''; staged=''
printf 'installed=%s\n' "$bin_dir/axure-forge"
