#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
binary=${1:?Usage: tests/environment.sh BINARY}
S="$ROOT/skills/axure-forge/scripts"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export AXURE_APPLICATIONS_DIR="$tmp/apps"
mkdir -p "$AXURE_APPLICATIONS_DIR"
check_default() {
  local expected=$1; shift
  bash "$S/doctor.sh" --app-only "$@" > "$tmp/env"
  grep -q "^default_format_version=$expected$" "$tmp/env"
}
create_app() {
  local major=$1 app="$AXURE_APPLICATIONS_DIR/Axure RP $1.app"
  mkdir -p "$app/Contents/MacOS"
  cp /usr/bin/true "$app/Contents/MacOS/Axure"
  cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>CFBundleIdentifier</key><string>com.axure.AxureRP$major</string><key>CFBundleVersion</key><string>$major.0.0</string><key>CFBundleExecutable</key><string>Axure</string></dict></plist>
PLIST
}
check_default 9
grep -q '^available_format_versions=none$' "$tmp/env"
check_default 11 --format-version 11
create_app 11
check_default 11
create_app 9
check_default 9
check_default 11 --format-version 11
rm -rf "$AXURE_APPLICATIONS_DIR/Axure RP 11.app"
check_default 9
mv "$AXURE_APPLICATIONS_DIR/Axure RP 9.app" "$tmp/Renamed.app"
check_default 9 --axure-path "$tmp/Renamed.app"
# Same CLI version but an old protocol must be refused.
cat > "$tmp/old-cli" <<'MOCK'
#!/bin/bash
printf '%s\n' '{"schema_version":2,"result":{"version":"0.3.0"}}'
MOCK
chmod +x "$tmp/old-cli"
if bash "$S/doctor.sh" --binary-path "$tmp/old-cli" > "$tmp/old.log" 2>&1; then exit 1; fi
grep -q 'protocol-v3' "$tmp/old.log"
# Real v3 build is accepted without any editor installed.
bash "$S/doctor.sh" --binary-path "$binary" > "$tmp/v3.log"
grep -q '^protocol_version=3$' "$tmp/v3.log"
# A protocol-v3 CLI with legacy command spellings is no longer compatible.
"$binary" capabilities --json > "$tmp/current.json"
node -e 'const fs=require("fs"); const p=JSON.parse(fs.readFileSync(process.argv[1])); delete p.result.cli["master-instance get"]; fs.writeFileSync(process.argv[2], JSON.stringify(p));' "$tmp/current.json" "$tmp/legacy.json"
printf '#!/bin/bash\ncat %q\n' "$tmp/legacy.json" > "$tmp/legacy-cli"
chmod +x "$tmp/legacy-cli"
if bash "$S/doctor.sh" --binary-path "$tmp/legacy-cli" > "$tmp/legacy.log" 2>&1; then exit 1; fi
grep -q 'CLI lacks master-instance get' "$tmp/legacy.log"
printf 'PASS: no editor, RP9 only, RP11 only, both, explicit selection, renamed app, v2 rejection and editor-free v3 checks\n'
