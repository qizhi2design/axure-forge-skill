#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
binary=${1:?Usage: tests/run.sh /absolute/path/axure-forge}
S="$ROOT/skills/axure-forge/scripts"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export AXURE_APPLICATIONS_DIR="$tmp/no-editors"
expect_failure() { if "$@" >"$tmp/failure.out" 2>&1; then printf 'unexpected success: %s\n' "$*" >&2; exit 1; fi; }
for file in "$S"/*.sh; do bash -n "$file"; done
bash "$S/doctor.sh" --binary-path "$binary"
expect_failure bash "$S/doctor.sh" --axure-path "$tmp/missing.app"
expect_failure bash "$S/doctor.sh" --unknown
expect_failure bash "$S/install.sh" --version
app="$tmp/Renamed.app"
mkdir -p "$app/Contents/MacOS"
cp /usr/bin/true "$app/Contents/MacOS/Axure"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleIdentifier</key><string>com.axure.AxureRP9</string><key>CFBundleVersion</key><string>9.0.0.3746</string><key>CFBundleExecutable</key><string>Axure</string></dict></plist>
PLIST
bash "$S/doctor.sh" --axure-path "$app" --app-only
/usr/libexec/PlistBuddy -c 'Set :CFBundleVersion 11.0.0' "$app/Contents/Info.plist"
expect_failure bash "$S/doctor.sh" --axure-path "$app" --app-only
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.axure.AxureRP11' "$app/Contents/Info.plist"
bash "$S/doctor.sh" --axure-path "$app" --app-only | grep -q 'default_format_version=11'
/usr/libexec/PlistBuddy -c 'Set :CFBundleVersion 9.0.0.3746' "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.axure.AxureRP9' "$app/Contents/Info.plist"
rm "$app/Contents/MacOS/Axure"
expect_failure bash "$S/doctor.sh" --axure-path "$app" --app-only
printf '\254\357\011\000' > "$tmp/header9.rp"
printf '\254\357\013\000' > "$tmp/header11.rp"
printf '\254\357\011' > "$tmp/short.rp"
printf 'wrong' > "$tmp/invalid.rp"
bash "$S/inspect-rp.sh" --project "$tmp/header9.rp"
bash "$S/inspect-rp.sh" --project "$tmp/header11.rp"
expect_failure bash "$S/inspect-rp.sh" --project "$tmp/short.rp"
expect_failure bash "$S/inspect-rp.sh" --project "$tmp/invalid.rp"
expect_failure "$binary" project open --path "$tmp/header9.rp"
cp -RL "$(dirname "$binary")" "$tmp/package"
(cd "$tmp/package" && find . -type f -print | sed 's#^./##' | while IFS= read -r member; do shasum -a 256 "$member"; done) > "$tmp/SHA256SUMS"
# Installation scripts see only stock system tools: no Python, pip, uv, npm or Node.
PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/bash "$S/install.sh" --package-dir "$tmp/package" --checksum-path "$tmp/SHA256SUMS" --bin-dir "$tmp/bin"
PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/bash "$S/install.sh" --bin-dir "$tmp/bin"
before=$(shasum -a 256 "$tmp/bin/axure-forge")
printf '%064d  axure-forge\n' 0 > "$tmp/bad-sums"
expect_failure bash "$S/install.sh" --package-dir "$tmp/package" --checksum-path "$tmp/bad-sums" --bin-dir "$tmp/bin" --force
[ "$before" = "$(shasum -a 256 "$tmp/bin/axure-forge")" ]
expect_failure bash "$S/install.sh" --package-dir "$tmp/package" --bin-dir "$tmp/bin" --force
expect_failure bash "$S/install.sh" --version ../../invalid --bin-dir "$tmp/bin"
bash "$ROOT/tests/environment.sh" "$binary"
node "$ROOT/tests/smoke.mjs" "$tmp/bin/axure-forge"
printf 'PASS: environment, header gates, offline install, reuse, checksum preservation and business smoke\n'
