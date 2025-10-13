# Testing Guidelines

## Unit & Integration Tests
- Create a `SattoPadTests` target when introducing testable logic. Group tests by subject (`MarkdownStoreTests`, `OverlayManagerTests`).
- Follow XCTest naming: `testSaveDebouncesWrites`, `testOverlayHidesWhenHotkeyReleased`.
- Inject dependencies (e.g., file URLs, timers) to avoid disk or timing flakiness.
- For file monitoring logic, simulate filesystem events with temporary directories under `NSTemporaryDirectory()`.

## UI Verification
- Menu bar interactions rely on AppKit APIs that are hard to automate. Perform manual spot checks for:
  - Global hotkey registration and release behavior.
  - Overlay fade in/out timings and opacity controls.
  - Markdown file selection and autosave feedback.

## Regression Checks
- Confirm that external edits to `~/Documents/SattoPad.md` are detected without UI stalls.
- Ensure user defaults migrations preserve existing paths when adding new settings keys.
- Document known limitations or intentionally skipped cases in pull requests.

## Coverage Expectations
- Aim for >70% coverage on pure logic modules (`MarkdownStore`, `OverlaySettingsStore`).
- For AppKit bridges (`OverlayManager`), focus on smoke tests that ensure critical hooks do not throw.

## Tooling
- Use `xcodebuild test -scheme SattoPad` locally and in CI once tests exist.
- Capture crash logs with the `Console` app or `log stream --predicate 'process == "SattoPad"'` when diagnosing failures.
