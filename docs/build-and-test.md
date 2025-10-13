# Build and Test Workflow

## Local Setup
1. Install Xcode 15 or newer on macOS 12+. Ensure the `Command Line Tools` component is enabled from Xcode preferences.
2. Clone the repository and open it in Xcode with `xed SattoPad.xcodeproj` or by double-clicking the project file.

## Common Commands
- `xcodebuild -scheme SattoPad -configuration Debug build`: Compiles the app for local development. Use the `Release` configuration before distributing binaries.
- `xcodebuild test -scheme SattoPad -destination "platform=macOS"`: Runs the XCTest suite once a test target exists. Pass `-only-testing:SattoPadTests/MarkdownStoreTests` to focus on a subset.
- `xcrun xctrace record --template 'Time Profiler' --launch SattoPad.app`: Profiles CPU usage during overlay activation.

## IDE Tips
- Use the SattoPad scheme’s Run configuration to target `My Mac (Designed for)` and ensure the menu bar app launches correctly.
- Toggle the Environment Overrides panel in Xcode to simulate different Accessibility permission states during debugging.

## Continuous Integration
- Reproduce the GitHub Actions workflow locally with `xcodebuild` to avoid CI regressions.
- When adding new schemes or targets, mark them as shared so automation can discover them.

## Packaging & Distribution
- Update signing identities in `SattoPad.xcodeproj` when preparing TestFlight or direct distribution builds.
- Export notarized builds using `xcodebuild -scheme SattoPad -configuration Release archive` followed by `xcodebuild -exportArchive`. Document any required entitlements in the release notes.
