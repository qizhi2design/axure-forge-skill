#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"
app=''; preferred=''
version=''
config_file="$HOME/Library/Application Support/axure-forge/config.json"
config_repo=$(/usr/bin/plutil -extract sources.cli.repo raw -o - "$config_file" 2>/dev/null || true)
config_mirror=$(/usr/bin/plutil -extract sources.cli.mirror-prefix raw -o - "$config_file" 2>/dev/null || true)
repo=${AXURE_FORGE_CLI_REPO:-${config_repo:-qizhi2design/axureforge-cli}}
mirror=${AXURE_FORGE_CLI_MIRROR_PREFIX-${config_mirror:-}}
network_unavailable() {
  printf '%s\n' '暂时无法连接发布源，本次未更新；已有 CLI 可继续使用。未安装时请联网重试，或提供离线包。'
  exit 0
}
binary=''; checksum=''; package_dir=''
bin_dir="$HOME/.local/bin"
force=0; download_method=curl
while [ "$#" -gt 0 ]; do
  case "$1" in
    --axure-path) need_value "$@"; app=$2; shift 2 ;;
    --format-version) need_value "$@"; preferred=$2; shift 2 ;;
    --repo) need_value "$@"; repo=$2; shift 2 ;;
    --mirror-prefix) need_value "$@"; mirror=$2; shift 2 ;;
    --version) need_value "$@"; version=$2; shift 2 ;;
    --binary-path) need_value "$@"; binary=$2; shift 2 ;;
    --package-dir) need_value "$@"; package_dir=$2; shift 2 ;;
    --checksum-path) need_value "$@"; checksum=$2; shift 2 ;;
    --bin-dir) need_value "$@"; bin_dir=$2; shift 2 ;;
    --force) force=1; shift ;;
    --download-method) need_value "$@"; download_method=$2; shift 2 ;;
    --help|-h) printf '%s\n' 'Usage: install.sh [--version vX.Y.Z] [--repo OWNER/REPO] [--mirror-prefix HTTPS_PREFIX] [--axure-path APP] [--bin-dir DIR] [--format-version 9|11] [--force]' 'Online: --download-method curl|gh|auto' 'Offline: --package-dir DIR --checksum-path SHA256SUMS (whole directory, relative file paths)' 'Legacy single-file offline: --binary-path FILE --checksum-path SHA256SUMS'; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done
require_platform
detect_environment "$app" "$preferred"
[ -z "$version" ] || [[ "$version" =~ ^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || fail 'supported release tags: vX.Y.Z'
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || fail 'repository must be owner/repo'
case "$repo" in ./*|../*|*/.|*/..) fail 'invalid repository' ;; esac
case "$mirror" in ''|https://*) ;; *) fail 'mirror prefix must be HTTPS' ;; esac
[ -z "$version" ] || version="v${version#v}"
case "$download_method" in auto|gh|curl) ;; *) fail 'download method must be auto, gh or curl' ;; esac
[ -z "$binary" ] || [ -z "$package_dir" ] || fail 'choose package-dir or binary-path'
if [ -e "$bin_dir/axure-forge" ] && [ "$force" -eq 0 ]; then
  installed=$("$bin_dir/axure-forge" --version) || fail 'installed CLI failed; use --force explicitly'
  [ -z "$version" ] || [ "$installed" = "${version#v}" ] || fail "installed $installed differs from $version; use --force to upgrade"
  doctor_args=(--binary-path "$bin_dir/axure-forge")
  [ -z "$app" ] || doctor_args+=(--axure-path "$app")
  [ -z "$preferred" ] || doctor_args+=(--format-version "$preferred")
  bash "$SCRIPT_DIR/doctor.sh" "${doctor_args[@]}"
  printf 'reused=%s\n' "$bin_dir/axure-forge"
  exit 0
fi
lock_dir="$HOME/Library/Application Support/axure-forge/update.lock"
mkdir -p "$(dirname "$lock_dir")"
mkdir "$lock_dir" 2>/dev/null || fail "another update is running; if interrupted, remove $lock_dir and retry"
tmp=$(mktemp -d); staged=''; link=''
cleanup() { rm -rf "$tmp"; rm -rf "$lock_dir"; if [ -n "$staged" ]; then rm -rf "$staged"; fi; if [ -n "$link" ]; then rm -f "$link"; fi; }
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
  if [ -z "$version" ]; then
    releases=$(curl --silent --fail --location --connect-timeout 5 --max-time 15 \
      "${mirror}https://api.github.com/repos/$repo/releases?per_page=100" 2>/dev/null) || network_unavailable
    skill_manifest="$SCRIPT_DIR/../skill-manifest.json"
    minimum=$(/usr/bin/plutil -extract cli_min_version raw -o - "$skill_manifest" 2>/dev/null || printf '0.3.0')
    maximum=$(/usr/bin/plutil -extract cli_max_version raw -o - "$skill_manifest" 2>/dev/null || true)
    [ "$maximum" != null ] || maximum=''
    version_ge() {
      local a1 a2 a3 b1 b2 b3
      IFS=. read -r a1 a2 a3 <<< "$1"
      IFS=. read -r b1 b2 b3 <<< "$2"
      [ "$a1" -gt "$b1" ] || { [ "$a1" -eq "$b1" ] && { [ "$a2" -gt "$b2" ] || { [ "$a2" -eq "$b2" ] && [ "$a3" -ge "$b3" ]; }; }; }
    }
    # Keep original tags; manifests and download URLs use the actual tag spelling.
    index=0; best=''
    while [ "$index" -lt 100 ]; do
      tag=$(json_value "$releases" "$index.tag_name") || break
      draft=$(json_value "$releases" "$index.draft")
      prerelease=$(json_value "$releases" "$index.prerelease")
      index=$((index + 1))
      [[ "$tag" =~ ^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || continue
      [ "$draft" = false ] && [ "$prerelease" = false ] || continue
      candidate=${tag#v}
      version_ge "$candidate" "$minimum" || continue
      if [ -n "$maximum" ] && version_ge "$candidate" "$maximum"; then continue; fi
      if [ -n "$best" ] && version_ge "${best#v}" "$candidate"; then continue; fi
      manifest=$(curl --silent --fail --location --connect-timeout 5 --max-time 15 \
        "${mirror}https://github.com/$repo/releases/download/$tag/release-manifest.json" 2>/dev/null) || network_unavailable
      [ "$(json_value "$manifest" protocol_version)" = 3 ] || continue
      [ "$(json_value "$manifest" component)" = cli ] || continue
      [ "$(json_value "$manifest" version)" = "$candidate" ] || fail 'release manifest version mismatch'
      asset=$(json_value "$manifest" assets.macos-arm64.filename) || continue
      [ "$asset" = "axure-forge-$candidate-macos-arm64.tar.gz" ] || fail 'invalid release asset name'
      best=$tag
    done
    [ -n "$best" ] || fail 'no compatible stable release with metadata; keep the existing CLI or supply an offline package'
    version=$best
  fi
  package="axure-forge-${version#v}-macos-arm64"
  asset="$package.tar.gz"
  base="${mirror}https://github.com/$repo/releases/download/$version"
  if [ "$download_method" = auto ]; then
    if [ -n "$mirror" ]; then download_method=curl; elif command -v gh >/dev/null && gh auth status --hostname github.com >/dev/null 2>&1; then download_method=gh; else download_method=curl; fi
  fi
  if [ -n "$mirror" ] && [ "$download_method" = gh ]; then fail 'mirror requires curl download method'; fi
  if [ "$download_method" = gh ]; then
    gh release download "$version" --repo "$repo" --pattern "$asset" --pattern SHA256SUMS --dir "$tmp" 2>/dev/null || network_unavailable
  else
    curl --silent --fail --location --connect-timeout 10 --max-time 180 "$base/$asset" -o "$tmp/$asset" 2>/dev/null || network_unavailable
    curl --silent --fail --location --connect-timeout 10 --max-time 60 "$base/SHA256SUMS" -o "$tmp/SHA256SUMS" 2>/dev/null || network_unavailable
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
if [ -z "$version" ]; then version="v$("$tmp/package/axure-forge" --version)"; fi
[[ "$version" =~ ^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || fail 'invalid installed version'
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
