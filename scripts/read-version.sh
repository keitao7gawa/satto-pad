#!/bin/bash
set -euo pipefail

PROJECT_PATH="${PROJECT_PATH:-SattoPad.xcodeproj}"
SCHEME="${SCHEME:-SattoPad}"
CONFIGURATION="${CONFIGURATION:-Release}"

xcodebuild -showBuildSettings \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  2>/dev/null |
  awk -F '= ' '/MARKETING_VERSION/ { print $2; exit }'
