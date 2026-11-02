#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
binary=${1:?Usage: tests/install-download.sh BINARY}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/assets" "$tmp/tools"
mkdir -p "$tmp/assets/axure-forge-0.2.1-macos-arm64"
cp "$binary" "$tmp/assets/axure-forge-0.2.1-macos-arm64/axure-forge"
(cd "$tmp/assets" && tar -czf axure-forge-0.2.1-macos-arm64.tar.gz axure-forge-0.2.1-macos-arm64/axure-forge && shasum -a 256 axure-forge-0.2.1-macos-arm64.tar.gz > SHA256SUMS)
for tool in uname dirname mktemp rm awk shasum chmod cp file mkdir mv tar cat basename; do ln -s "$(command -v "$tool")" "$tmp/tools/$tool"; done
cat > "$tmp/tools/curl" <<'MOCK'
#!/bin/bash
set -euo pipefail
asset=''; out=''
while [ "$#" -gt 0 ]; do
 case "$1" in
  https://github.com/qizhi2design/axureforge-cli/releases/download/v0.2.1/*) asset=${1##*/}; shift ;;
  -o) out=$2; shift 2 ;;
  *) shift ;;
 esac
done
[ -n "$asset" ] && [ -n "$out" ] || exit 1
/bin/cp "$TEST_RELEASE_DIR/$asset" "$out"
MOCK
chmod +x "$tmp/tools/curl"
# Whitelist only needed tools: no Python, uv, pip, Node, npm or Git.
PATH="$tmp/tools" TEST_RELEASE_DIR="$tmp/assets" /bin/bash "$ROOT/skills/axure-forge/scripts/install.sh" --bin-dir "$tmp/bin"
"$tmp/bin/axure-forge" --version
before=$(shasum -a 256 "$tmp/bin/axure-forge")
printf '%064d  axure-forge-0.2.1-macos-arm64.tar.gz\n' 0 > "$tmp/assets/SHA256SUMS"
if PATH="$tmp/tools" TEST_RELEASE_DIR="$tmp/assets" /bin/bash "$ROOT/skills/axure-forge/scripts/install.sh" --bin-dir "$tmp/bin" --force > "$tmp/failure.log" 2>&1; then exit 1; fi
[ "$before" = "$(shasum -a 256 "$tmp/bin/axure-forge")" ]
grep -q 'checksum mismatch' "$tmp/failure.log"
# Restore checksum, then provide an archive with unexpected members.
printf 'unexpected' > "$tmp/assets/extra"
(cd "$tmp/assets" && tar -czf axure-forge-0.2.1-macos-arm64.tar.gz axure-forge-0.2.1-macos-arm64/axure-forge extra && shasum -a 256 axure-forge-0.2.1-macos-arm64.tar.gz > SHA256SUMS)
if PATH="$tmp/tools" TEST_RELEASE_DIR="$tmp/assets" /bin/bash "$ROOT/skills/axure-forge/scripts/install.sh" --bin-dir "$tmp/bin" --force > "$tmp/failure.log" 2>&1; then exit 1; fi
grep -q 'unexpected archive contents' "$tmp/failure.log"
[ "$before" = "$(shasum -a 256 "$tmp/bin/axure-forge")" ]
# Reject unsupported platforms before inspecting apps or fetching anything.
printf '#!/bin/bash\nprintf "Linux\\n"\n' > "$tmp/tools/uname".mock
chmod +x "$tmp/tools/uname.mock"
rm "$tmp/tools/uname"
mv "$tmp/tools/uname.mock" "$tmp/tools/uname"
if PATH="$tmp/tools" /bin/bash "$ROOT/skills/axure-forge/scripts/doctor.sh" --rp9-only > "$tmp/failure.log" 2>&1; then exit 1; fi
grep -q 'macOS only' "$tmp/failure.log"
printf 'PASS: simulated Release download, archive validation, preservation, platform rejection, runtime-free installer PATH\n'
