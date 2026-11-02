# Homebrew Tap Auto-Sync

The app release workflow (`.github/workflows/release.yml`) builds and publishes `SattoPad.dmg`, then updates `keitao7gawa/homebrew-satto-pad/Casks/satto-pad.rb` to match that release.

## One-time credential setup

1. Create a **fine-grained personal access token** in GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens.
2. Resource owner: `keitao7gawa`. Limit repository access to **only** `homebrew-satto-pad`.
3. Grant **Contents: Read and write** permission. Keep all other permissions minimal. If the tap's `main` branch is protected, the token owner must be allowed to update it (or change this workflow to create a PR instead).
4. In `keitao7gawa/satto-pad` → Settings → Secrets and variables → Actions, create a repository secret named **`HOMEBREW_TAP_TOKEN`** containing the token. Do not commit the token.
5. Merge this change into `main`.

## Release behavior

- A push to `main` whose head commit contains `[release]`, or a manual workflow dispatch, triggers the existing release job.
- The workflow resolves the next patch version, builds the app and DMG, and publishes the GitHub Release.
- **Only after the Release step succeeds**, `scripts/update-homebrew-cask.sh` hashes the actual DMG, verifies the GitHub Release asset, and updates the Cask's `version` and `sha256` with the existing URL format.
- On exact reruns, the update is idempotent and skips an unchanged Cask.
- If the Homebrew update fails, the app GitHub Release remains published; check the job log and repair or rerun the synchronization. Rerunning the **entire release job** creates a *new patch version* with the current workflow; prefer manually syncing the failed version when needed.

## Validate

After the next release:
1. Verify GitHub Actions succeeded for `Release DMG`.
2. Verify the new GitHub Release contains `SattoPad.dmg`.
3. Inspect `homebrew-satto-pad/Casks/satto-pad.rb`; its version should match the release and its SHA256 should equal `shasum -a 256 SattoPad.dmg`.
4. On a Mac with Homebrew, run `brew update`, `brew info --cask keitao7gawa/satto-pad/satto-pad`, and perform an install or upgrade test.

## Caveats

- The current Cask was on v1.1.0 while the app's latest release was v1.1.1 at the time this workflow was prepared; this automation **does not backfill** earlier releases.
- This flow updates the tap directly (no pull request) and requires the tap's branch policy to allow the token.
- Existing app releases are unsigned. Signing and notarization are separate work.
