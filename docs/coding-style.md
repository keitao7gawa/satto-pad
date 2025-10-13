# Coding Style Guide

## Formatting
- Indentation uses four spaces. Align chained modifiers and parameters for readability.
- Keep imports ordered from system frameworks to third-party packages (`SwiftUI`, `AppKit`, then external frameworks).
- Prefer `// MARK:` separators to outline logical sections inside types (e.g., lifecycle, public API, private helpers).

## Naming
- Types: `UpperCamelCase` (`OverlayManager`, `MarkdownStore`).
- Properties and functions: `lowerCamelCase` (`startFileMonitor`, `overlayOpacity`).
- Enumerations: use descriptive cases (`case overlayHidden`, not `case hidden`). Attach raw values only when necessary for persistence.

## Patterns & Conventions
- Favor `struct` for value semantics in view models; use `final class` when reference semantics or `ObservableObject` is required.
- Store constants in dedicated types such as `HeaderLayoutConstants` to avoid scattering magic numbers. Mark them `internal` unless cross-module access is required.
- Encapsulate side effects behind managers (e.g., `OverlayManager`) to keep SwiftUI views declarative.
- Use property wrappers like `@AppStorage` only when user-default keys are isolated; otherwise rely on custom wrappers (`UserDefaultsPropertyWrapper.swift`).

## Documentation & Comments
- Add concise comments only when intent is non-obvious, such as debouncing strategies or file-monitoring quirks.
- Prefer doc comments (`///`) on public APIs and anything consumed outside the defining file.

## Tooling
- Run Xcode’s `Editor > Structure > Re-Indent` before committing.
- SwiftLint is not currently enforced; if you add it, capture the configuration in `swiftlint.yml` and update this guide.
