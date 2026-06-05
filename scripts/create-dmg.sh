#!/bin/bash
set -euo pipefail

APP_PATH="${1:-}"
OUTPUT_PATH="${2:-build/release/SattoPad.dmg}"
VOLUME_NAME="${VOLUME_NAME:-SattoPad}"

if [[ -z "$APP_PATH" ]]; then
  echo "Usage: scripts/create-dmg.sh path/to/SattoPad.app [path/to/SattoPad.dmg]" >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found: $APP_PATH" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"
rm -f "$OUTPUT_PATH"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$APP_PATH" \
  -ov \
  -format UDZO \
  "$OUTPUT_PATH"

shasum -a 256 "$OUTPUT_PATH"
