#!/bin/bash
set -euo pipefail

PROJECT_PATH="${PROJECT_PATH:-SattoPad.xcodeproj}"
SCHEME="${SCHEME:-SattoPad}"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="${BUILD_DIR:-$PWD/build/release}"
APP_NAME="${APP_NAME:-SattoPad}"
VERSION="${VERSION:-}"
BUILD_NUMBER="${BUILD_NUMBER:-}"
CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}"

if [[ -z "$VERSION" ]]; then
  VERSION="$(PROJECT_PATH="$PROJECT_PATH" SCHEME="$SCHEME" CONFIGURATION="$CONFIGURATION" scripts/read-version.sh)"
fi

if [[ -z "$BUILD_NUMBER" ]]; then
  BUILD_NUMBER="$(date +%Y%m%d%H%M%S)"
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  -destination "generic/platform=macOS" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  CODE_SIGNING_ALLOWED="$CODE_SIGNING_ALLOWED" \
  clean build

APP_PATH="$BUILD_DIR/DerivedData/Build/Products/$CONFIGURATION/$APP_NAME.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app not found: $APP_PATH" >&2
  exit 1
fi

rm -rf "$BUILD_DIR/$APP_NAME.app"
ditto "$APP_PATH" "$BUILD_DIR/$APP_NAME.app"

echo "$BUILD_DIR/$APP_NAME.app"
