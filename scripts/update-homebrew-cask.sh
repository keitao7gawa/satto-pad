#!/usr/bin/env bash
set -euo pipefail

# Sync the Homebrew Cask after publishing a successful DMG release.
# GH_TOKEN: fine-grained PAT with Contents (read/write) on homebrew-satto-pad.
VERSION="${1:?Usage: update-homebrew-cask.sh VERSION PATH_TO_DMG}"
DMG_PATH="${2:?Usage: update-homebrew-cask.sh VERSION PATH_TO_DMG}"
TAP_REPOSITORY="keitao7gawa/homebrew-satto-pad"
CASK_PATH="Casks/satto-pad.rb"

[[ -f "$DMG_PATH" ]] || { echo "DMG not found: $DMG_PATH" >&2; exit 1; }
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid version: $VERSION" >&2; exit 1; }
: "${GH_TOKEN:?Set GH_TOKEN with access to the Homebrew tap repository}"
command -v gh >/dev/null || { echo "GitHub CLI (gh) is required" >&2; exit 1; }

SHA256="$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
[[ "$SHA256" =~ ^[[:xdigit:]]{64}$ ]] || { echo "Failed to calculate SHA256" >&2; exit 1; }

RELEASE_TAG="v${VERSION}"
gh api "repos/keitao7gawa/satto-pad/releases/tags/${RELEASE_TAG}" --jq '.assets[].name' |
  grep -Fxq 'SattoPad.dmg' || {
    echo "Release asset SattoPad.dmg not found for ${RELEASE_TAG}" >&2
    exit 1
  }

TEMP_CASK="$(mktemp)"
trap 'rm -f "$TEMP_CASK"' EXIT
cat > "$TEMP_CASK" <<CASK
cask "satto-pad" do
  version "${VERSION}"
  sha256 "${SHA256}"

  url "https://github.com/keitao7gawa/satto-pad/releases/download/v#{version}/SattoPad.dmg"
  name "Satto Pad"
  desc "A memo application specialized for quick viewing (satto)"
  homepage "https://github.com/keitao7gawa/satto-pad"

  app "SattoPad.app"
end
CASK

CURRENT_SHA="$(gh api "repos/${TAP_REPOSITORY}/contents/${CASK_PATH}" --jq '.sha')"
CURRENT_CONTENT="$(gh api -H 'Accept: application/vnd.github.raw+json' "repos/${TAP_REPOSITORY}/contents/${CASK_PATH}")"
if [[ "$CURRENT_CONTENT" == "$(cat "$TEMP_CASK")" ]]; then
  echo "Homebrew Cask already matches ${RELEASE_TAG}; nothing to update."
  exit 0
fi

ENCODED_CONTENT="$(base64 < "$TEMP_CASK" | tr -d '\n')"
gh api --method PUT "repos/${TAP_REPOSITORY}/contents/${CASK_PATH}" \
  -f message="chore: update SattoPad to ${RELEASE_TAG}" \
  -f content="$ENCODED_CONTENT" \
  -f sha="$CURRENT_SHA" \
  -f branch=main \
  --jq '.commit.html_url'

echo "Homebrew tap updated for ${RELEASE_TAG} (${SHA256})"
