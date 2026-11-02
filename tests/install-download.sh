#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
binary=${1:?Usage: tests/install-download.sh BINARY}
version=$("$binary" --version)
export TEST_RELEASE_VERSION="$version"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export AXURE_APPLICATIONS_DIR="$tmp/no-editors"
mkdir -p "$tmp/assets" "$tmp/tools"
mkdir -p "$tmp/assets/axure-forge-${version}-macos-arm64"
cp -RL "$(dirname "$binary")/." "$tmp/assets/axure-forge-${version}-macos-arm64/"
(cd "$tmp/assets" && tar -czf axure-forge-${version}-macos-arm64.tar.gz axure-forge-${version}-macos-arm64 && shasum -a 256 axure-forge-${version}-macos-arm64.tar.gz > SHA256SUMS)
cat > "$tmp/assets/releases.json" <<JSON
[{"tag_name":"v9.0.0","draft":true,"prerelease":false},
 {"tag_name":"v${version}","draft":false,"prerelease":false},
 {"tag_name":"v8.0.0","draft":false,"prerelease":true}]
JSON
cat > "$tmp/assets/release-manifest.json" <<JSON
{"manifest_version":1,"component":"cli","version":"${version}","protocol_version":3,
 "assets":{"macos-arm64":{"filename":"axure-forge-${version}-macos-arm64.tar.gz"}}}
JSON
for tool in uname dirname mktemp rm awk shasum chmod cp file mkdir mv tar cat basename sed ln bash; do ln -s "$(command -v "$tool")" "$tmp/tools/$tool"; done
cat > "$tmp/tools/curl" <<'MOCK'
#!/bin/bash
set -euo pipefail
asset=''; out=''
while [ "$#" -gt 0 ]; do
 request=${1#https://mirror.example/}
 case "$request" in
  https://api.github.com/repos/*/releases?per_page=100) asset=releases.json; printf '%s\n' "$1" >> "${TEST_RELEASE_URLS:-/dev/null}"; shift ;;
  https://github.com/*/releases/download/v${TEST_RELEASE_VERSION}/*) asset=${request##*/}; printf '%s\n' "$1" >> "${TEST_RELEASE_URLS:-/dev/null}"; shift ;;
  -o) out=$2; shift 2 ;;
  *) shift ;;
 esac
done
[ -n "$asset" ] || exit 1
if [ -n "$out" ]; then /bin/cp "$TEST_RELEASE_DIR/$asset" "$out"; else /bin/cat "$TEST_RELEASE_DIR/$asset"; fi
MOCK
chmod +x "$tmp/tools/curl"
# Whitelist only needed tools: no Python, uv, pip, Node, npm or Git.
PATH="$tmp/tools" TEST_RELEASE_DIR="$tmp/assets" /bin/bash "$ROOT/skills/axure-forge/scripts/install.sh" --version v${version} --bin-dir "$tmp/bin"
"$tmp/bin/axure-forge" --version
before=$(shasum -a 256 "$tmp/bin/axure-forge")
# Default selection reads metadata, ignores draft/prerelease and needs no extra runtime.
PATH="$tmp/tools" TEST_RELEASE_DIR="$tmp/assets" /bin/bash "$ROOT/skills/axure-forge/scripts/install.sh" --bin-dir "$tmp/latest-bin"
[ "$("$tmp/latest-bin/axure-forge" --version)" = "$version" ]
PATH="$tmp/tools" TEST_RELEASE_DIR="$tmp/assets" TEST_RELEASE_URLS="$tmp/urls" /bin/bash "$ROOT/skills/axure-forge/scripts/install.sh" --repo example/fork --mirror-prefix https://mirror.example/ --bin-dir "$tmp/mirror-bin"
grep -q 'https://mirror.example/https://api.github.com/repos/example/fork/releases' "$tmp/urls"
grep -q 'https://mirror.example/https://github.com/example/fork/releases/download/' "$tmp/urls"
printf '%064d  axure-forge-%s-macos-arm64.tar.gz\n' 0 "$version" > "$tmp/assets/SHA256SUMS"
if PATH="$tmp/tools" TEST_RELEASE_DIR="$tmp/assets" /bin/bash "$ROOT/skills/axure-forge/scripts/install.sh" --version v${version} --bin-dir "$tmp/bin" --force > "$tmp/failure.log" 2>&1; then exit 1; fi
[ "$before" = "$(shasum -a 256 "$tmp/bin/axure-forge")" ]
grep -q 'checksum mismatch' "$tmp/failure.log"
# Restore checksum, then provide an archive with unexpected members.
printf 'unexpected' > "$tmp/assets/extra"
(cd "$tmp/assets" && tar -czf axure-forge-${version}-macos-arm64.tar.gz axure-forge-${version}-macos-arm64 extra && shasum -a 256 axure-forge-${version}-macos-arm64.tar.gz > SHA256SUMS)
if PATH="$tmp/tools" TEST_RELEASE_DIR="$tmp/assets" /bin/bash "$ROOT/skills/axure-forge/scripts/install.sh" --version v${version} --bin-dir "$tmp/bin" --force > "$tmp/failure.log" 2>&1; then exit 1; fi
grep -q 'unexpected archive contents' "$tmp/failure.log"
[ "$before" = "$(shasum -a 256 "$tmp/bin/axure-forge")" ]
# Reject unsupported platforms before inspecting apps or fetching anything.
printf '#!/bin/bash\nprintf "Linux\\n"\n' > "$tmp/tools/uname".mock
chmod +x "$tmp/tools/uname.mock"
rm "$tmp/tools/uname"
mv "$tmp/tools/uname.mock" "$tmp/tools/uname"
if PATH="$tmp/tools" /bin/bash "$ROOT/skills/axure-forge/scripts/doctor.sh" --app-only > "$tmp/failure.log" 2>&1; then exit 1; fi
grep -q 'macOS only' "$tmp/failure.log"
printf 'PASS: simulated Release download, archive validation, preservation, platform rejection, runtime-free installer PATH\n'
