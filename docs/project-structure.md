# Project Structure

## High-Level Layout
- `SattoPad/`: Swift sources grouped by responsibility. Entry points (`SattoPadApp.swift`, `AppDelegate.swift`) handle app lifecycle while managers such as `OverlayManager.swift` and stores (`MarkdownStore.swift`, `OverlaySettingsStore.swift`, `MemoStore.swift`) encapsulate behavior and persistence.
- `SattoPad.xcodeproj/`: Xcode project settings, build configurations, and shared schemes. Edit schemes here when adding targets or changing signing settings.
- `Assets.xcassets`: Central location for app icons, color sets, and design tokens referenced throughout SwiftUI views.
- `README.md`: Product-facing overview and installation steps. Keep aligned with any behavior changes noted in code.
- `SattoPad.entitlements`: Sandbox capabilities for the production build. Any entitlement change must be reviewed alongside notarization steps.

## Key Swift Modules
- **Overlay UI**: `OverlayHeaderView.swift`, `OverlayPreviewView.swift`, `OverlayTypography.swift`, and `UIComponents.swift` compose the on-screen overlay experience.
- **Data Flow**: `MarkdownStore.swift` debounces file writes, monitors external edits, and handles sandbox bookmarks. Markdown プレビューは `OverlayPreviewView.swift` が MarkdownUI を用いて描画します。
- **Preferences & State**: `OverlaySettingsStore.swift`, `KeyboardShortcutsSupport.swift`, and `UserDefaultsPropertyWrapper.swift` manage configurable settings and persistence.
- **Supporting Views**: `AboutView.swift` and `ContentView.swift` handle the settings popover and informational UI.

## Adding New Features
1. Place new view models or stores alongside existing peers inside `SattoPad/` and suffix the filename with the primary responsibility (`EditorToolbarStore.swift`).
2. Co-locate SwiftUI views with related state objects to keep feature modules cohesive.
3. Update this document whenever a new directory or significant module is introduced.
