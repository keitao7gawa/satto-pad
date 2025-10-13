# Configuration and Security

## Entitlements & Permissions
- `SattoPad.entitlements` defines sandbox capabilities. Review every change for compatibility with App Store notarization.
- The Accessibility permission (`kAXTrustedCheckOptionPrompt`) is mandatory for global hotkeys. Update onboarding copy whenever hotkey behavior changes.

## File Storage
- Default notes are stored at `~/Documents/SattoPad.md`. Allow users to relocate the file, and persist the security-scoped bookmark via `MarkdownStore`.
- When altering default paths, ensure migration logic preserves existing bookmarks and that documentation reflects the new location.

## Hotkey Handling
- `KeyboardShortcutsSupport.swift` manages registration. Handle conflicts gracefully by surfacing errors through the UI.
- Record any new keyboard shortcuts in release notes and README tables.

## External Integrations
- The app has no network dependencies. Avoid introducing network calls without an explicit security review.
- If future integrations require network access, document API endpoints, authentication requirements, and accepted data flows here.

## Diagnostics
- Log non-sensitive warnings via `lastWarningMessage` in `MarkdownStore` and ensure user-facing alerts respect localization.
- Capture crash details with `log stream` during QA and attach sanitized logs to issue reports.

## Release Readiness
- Before shipping, run through the manual verification checklist for hotkeys, overlay rendering, and markdown synchronization.
- Keep notarization scripts or commands version-controlled if added, and note any keychain or signing prerequisites.
