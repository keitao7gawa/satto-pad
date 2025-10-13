# Repository Guidelines

## Development Roadmap
Follow the staged plan in [docs/development-roadmap.md](docs/development-roadmap.md) to keep deliveries lean: menu bar MVP, press-and-hold shortcut, autosave, then overlay polish. Each milestone lists acceptance criteria and QA checks so you can scope PRs accurately.

## Project Structure & Module Organization
Swift sources live in `SattoPad/`, with lifecycle code (`SattoPadApp.swift`, `AppDelegate.swift`) separated from overlay managers and stores (`OverlayManager.swift`, `MarkdownStore.swift`). UI components and constants stay co-located to keep features cohesive, while assets and entitlements sit in the project root. See [docs/project-structure.md](docs/project-structure.md) for a directory map and onboarding sequence when adding modules.

## Build, Test & Development Commands
Use `xed SattoPad.xcodeproj` for day-to-day development, or `xcodebuild -scheme SattoPad -configuration Debug build` when scripting builds. Profiling and notarization steps are outlined in [docs/build-and-test.md](docs/build-and-test.md), including common `xcodebuild test` destinations and `xctrace` tips for menu-bar diagnostics.

## Coding Style & Naming Conventions
Adopt four-space indentation and Swift API Design Guideline naming (`UpperCamelCase` types, `lowerCamelCase` members). Organize files with `// MARK:` sections, isolate side effects behind managers, and lean on `final class` for `ObservableObject`. More conventions and tooling expectations reside in [docs/coding-style.md](docs/coding-style.md).

## Testing Guidelines
Introduce a `SattoPadTests` target for new logic, name suites after their subject, and inject dependencies to avoid filesystem coupling. Manual checks remain essential for hotkeys and overlay behavior; document gaps in PRs. Detailed flows and coverage targets are captured in [docs/testing-guidelines.md](docs/testing-guidelines.md).

## Hotkey & Overlay Operations
Implement the press-and-hold shortcut with KeyboardShortcuts as described in [docs/hotkey-strategy.md](docs/hotkey-strategy.md), and keep the preview responsive using the window lifecycle in [docs/overlay-architecture.md](docs/overlay-architecture.md). For autosave and reload behaviour, rely on the guarantees in [docs/autosave-system.md](docs/autosave-system.md).

## Commit & Pull Request Guidelines
Mirror the existing `docs:` / `update:` prefixes with concise, imperative summaries, and keep unrelated changes split. PRs should outline scope, test evidence, UI captures, and any entitlement implications. Refer to [docs/commits-and-prs.md](docs/commits-and-prs.md) for branch naming patterns and review expectations.

## Configuration, Security & Refactoring Notes
`SattoPad.entitlements` governs sandbox access; audit any change and pair it with release documentation. Note updates to the default markdown path and accessibility onboarding steps whenever hotkey behavior shifts. Long-term cleanup tasks and safe sequencing live in [docs/configuration-and-security.md](docs/configuration-and-security.md) and [docs/refactoring-roadmap.md](docs/refactoring-roadmap.md).
