# Release Workflow

SattoPad publishes a DMG from GitHub Actions when a commit pushed to `main`
contains `[release]` in the head commit message.

## Trigger

- Push to `main` with `[release]` in the latest commit message.
- Manual runs through `workflow_dispatch` are also allowed for validation.
- Pushes to `main` without `[release]` skip the release job.

## Versioning

The workflow reads the latest semantic tag matching `vX.Y.Z` and increments the
patch version.

Example:

- Latest tag: `v1.1.0`
- Next release: `v1.1.1`

If no semantic release tag exists yet, the workflow uses the app's
`MARKETING_VERSION` as the first release version.

## Artifact

The workflow builds `SattoPad.app`, packages it as `SattoPad.dmg`, creates a
GitHub Release, and attaches the DMG.

The current workflow builds an unsigned DMG. Developer ID signing and
notarization should be added before relying on the artifact as a polished public
distribution.

## Local Packaging

Run the same packaging path locally:

```sh
VERSION="$(scripts/read-version.sh)" scripts/build-release.sh
scripts/create-dmg.sh build/release/SattoPad.app build/release/SattoPad.dmg
```

The DMG checksum is printed by `scripts/create-dmg.sh`.
