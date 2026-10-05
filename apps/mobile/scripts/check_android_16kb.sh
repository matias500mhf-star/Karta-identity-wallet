#!/usr/bin/env bash
set -euo pipefail

APK="${1:-build/app/outputs/flutter-apk/app-debug.apk}"
if [ ! -f "$APK" ]; then
  echo "APK not found: $APK" >&2
  exit 1
fi

SETTINGS="android/settings.gradle.kts"
if [ ! -f "$SETTINGS" ]; then
  echo "Android settings file not found: $SETTINGS" >&2
  exit 1
fi

python3 - "$SETTINGS" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(
    r'id\(["\']com\.android\.application["\']\)\s+version\s+["\']([^"\']+)',
    text,
)
if not match:
    raise SystemExit("Could not determine Android Gradle Plugin version.")

raw = match.group(1)
parts = raw.split("-")[0].split(".")
try:
    version = tuple(int(part) for part in parts[:3])
except ValueError as exc:
    raise SystemExit(f"Unparseable Android Gradle Plugin version: {raw}") from exc

version = version + (0,) * (3 - len(version))
minimum = (8, 5, 1)
print(f"Android Gradle Plugin: {raw}")
if version < minimum:
    raise SystemExit(
        f"Android Gradle Plugin {raw} is below the 16 KB packaging baseline 8.5.1."
    )
PY

command -v readelf >/dev/null || {
  echo "readelf is required for ELF alignment validation." >&2
  exit 1
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

unzip -qq "$APK" 'lib/*/*.so' -d "$TMP_DIR" || true

FOUND=0
while IFS= read -r -d '' SO; do
  case "$SO" in
    */lib/arm64-v8a/*.so|*/lib/x86_64/*.so)
      FOUND=1
      echo "Checking ELF alignment: ${SO#"$TMP_DIR"/}"
      while read -r ALIGN; do
        [ -z "$ALIGN" ] && continue
        VALUE=$((ALIGN))
        if [ "$VALUE" -lt 16384 ]; then
          echo "ELF LOAD alignment below 16 KB: $ALIGN in $SO" >&2
          exit 1
        fi
      done < <(readelf -lW "$SO" | awk '$1 == "LOAD" { print $NF }')
      ;;
  esac
done < <(find "$TMP_DIR/lib" -type f -name '*.so' -print0 2>/dev/null || true)

if [ "$FOUND" -ne 1 ]; then
  echo "No arm64-v8a/x86_64 native libraries found; ELF alignment check not applicable."
fi

ZIPALIGN="$(find "${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}" -path '*/build-tools/*/zipalign' -type f 2>/dev/null | sort -V | tail -n 1)"
if [ -z "$ZIPALIGN" ]; then
  echo "zipalign was not found in Android SDK build-tools." >&2
  exit 1
fi

echo "Using zipalign: $ZIPALIGN"
"$ZIPALIGN" -c -P 16 -v 4 "$APK"

echo "KARTA Android 16 KB compatibility gate: PASS"
