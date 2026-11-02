#!/bin/bash
# Runtime-free bootstrap checks: offline is a normal outcome, never a crash.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
binary=${1:?Usage: tests/update-offline.sh /absolute/path/axure-forge}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/tools" "$tmp/bin"
cat > "$tmp/tools/curl" <<'MOCK'
#!/bin/bash
printf 'curl: simulated offline\n' >&2
exit 7
MOCK
chmod +x "$tmp/tools/curl"
export AXURE_APPLICATIONS_DIR="$tmp/no-editors"
PATH="$tmp/tools:$PATH" bash "$ROOT/skills/axure-forge/scripts/install.sh" --bin-dir "$tmp/new-bin" > "$tmp/offline.log" 2>&1
grep -q '暂时无法连接' "$tmp/offline.log"
if grep -Eq 'ERROR:|Traceback|curl:' "$tmp/offline.log"; then cat "$tmp/offline.log"; exit 1; fi
[ ! -e "$tmp/new-bin/axure-forge" ]
ln -s "$binary" "$tmp/bin/axure-forge"
PATH="$tmp/tools:$PATH" bash "$ROOT/skills/axure-forge/scripts/install.sh" --bin-dir "$tmp/bin" > "$tmp/reused.log" 2>&1
grep -q 'reused=' "$tmp/reused.log"
PATH="$tmp/tools:$PATH" bash "$ROOT/skills/axure-forge/scripts/install.sh" --bin-dir "$tmp/bin" --force > "$tmp/unchanged.log" 2>&1
grep -q '暂时无法连接' "$tmp/unchanged.log"
[ "$(readlink "$tmp/bin/axure-forge")" = "$binary" ]
# Explicit legacy version also handles a mid-download network outage gracefully.
PATH="$tmp/tools:$PATH" bash "$ROOT/skills/axure-forge/scripts/install.sh" --version v0.3.0 --bin-dir "$tmp/bin" --force > "$tmp/explicit.log" 2>&1
grep -q '暂时无法连接' "$tmp/explicit.log"
[ "$(readlink "$tmp/bin/axure-forge")" = "$binary" ]
printf 'PASS: offline bootstrap, compatible reuse, explicit download failure, preserved entry\n'
