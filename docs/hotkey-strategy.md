# Hotkey Strategy

## Goal
Adopt the [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) package to manage SattoPad’s press-and-hold global shortcut. The library standardises recording, persistence, and activation while avoiding the pitfalls of Carbon APIs.

## Scope
- Add KeyboardShortcuts via Swift Package Manager.
- Use `KeyboardShortcuts.onKeyDown`/`onKeyUp` to show and hide the overlay.
- Embed `KeyboardShortcuts.Recorder` in the settings UI with reset/clear controls.
- Remove legacy Carbon/EventTap/GlobalMonitor code paths once parity is confirmed.

## Implementation Notes
- Declare the toggle identifier in `KeyboardShortcuts.Name`:
  ```swift
  extension KeyboardShortcuts.Name {
      static let toggleSattoPad = Self("toggleSattoPad")
  }
  ```
- Initialise the default shortcut (`Cmd + Shift + T`) only when unset, typically in debug builds:
  ```swift
  if KeyboardShortcuts.getShortcut(for: .toggleSattoPad) == nil {
      KeyboardShortcuts.setShortcut(.init(.t, modifiers: [.command, .shift]), for: .toggleSattoPad)
  }
  ```
- Register listeners during app launch:
  ```swift
  KeyboardShortcuts.onKeyDown(for: .toggleSattoPad) { [weak self] in self?.overlayManager.show() }
  KeyboardShortcuts.onKeyUp(for: .toggleSattoPad) { [weak self] in self?.overlayManager.hide() }
  ```
- Integrate the Recorder within SwiftUI settings and expose `Reset` and `Clear` buttons via `KeyboardShortcuts.reset`.
- ホットキー押下時は `OverlayManager.update(text:)` を通じて MarkdownUI プレビュー用のテキスト変換とテーマ適用を行い、オーバーレイ表示をブロックしないようにする。

## UX Requirements
- Provide guidance copy: “Press-and-hold shortcut to show SattoPad.”
- Suggest conflict-safe combinations (e.g., `Ctrl + Option + Cmd + Y`).
- Reflect the current shortcut in the UI and allow clearing to disable the gesture.

## QA Checklist
- Record → fire the shortcut across common apps (Finder, Safari, Xcode).
- Verify reset/clear behaviour and persistence across restarts.
- Ensure no duplicate firing after removing legacy handlers.
- Confirm the overlay hides immediately on key up even when menus are open.

## Risks & Mitigations
- Shortcut conflicts: call out safe defaults and allow quick reassignment.
- Corporate-managed Macs: document any policy restrictions around custom shortcuts.
- Media keys unsupported: keep scope limited to standard key combinations.
