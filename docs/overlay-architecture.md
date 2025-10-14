# Overlay Architecture

## Purpose
Deliver a press-and-hold preview that appears near-instantly, shows the current note, and vanishes the moment the shortcut is released. The overlay is read-only; editing happens inside the popover.

## Window Model
- Use a borderless `NSPanel` (or `NSWindow`) with `level = .floating`, `isOpaque = false`, and a clear background.
- Manage the window inside `OverlayManager`, reusing the same instance instead of recreating it each time.
- ドラッグ移動はヘッダー領域に限定し、本文は常にスクロール可能。スクロールバーは必要時に即表示されるよう `ScrollView` を常時インジケータ表示に設定。

## Position Persistence
- Default anchor: top-left of the main screen.
- Persist `screenId` (from `CGDirectDisplayID`) and normalised coordinates (0–1 range) via `OverlaySettingsStore` keys such as `sattoPad.overlay.positionX`.
- On screen changes, clamp the overlay to safe margins inside the visible frame.

## Rendering Pipeline
- `OverlayPreviewView` consumes the latest markdown text and renders it via MarkdownUI with the custom `Theme.sattoPad` defined in `OverlayTypography`.
- MarkdownUI に渡す前に、単一改行を `  \n` に変換し、通常リストとチェックボックスリストの境界に空行を挿入する前処理を実施。
- Throttle updates (≈150ms) to avoid unnecessary re-layout while typing。

## Interaction Flow
1. `KeyboardShortcuts.onKeyDown` → `OverlayManager.show()` orders the window front and updates content.
2. `KeyboardShortcuts.onKeyUp` → `OverlayManager.hide()` calls `orderOut` without destroying the window.
3. When the settings popover opens, enable adjustment mode so users can drag the overlay and store the new coordinates.

## Performance Targets
- Show/hide latency <50ms.
- Idle CPU usage <1%; memory footprint <100MB.
- Rendering should avoid heavy animations; prefer static opacity transitions.

## Testing Checklist
- Verify show/hide timing across Finder, Safari, Xcode, and Mission Control contexts.
- Adjust the overlay position, restart the app, and confirm persistence.
- Exercise multi-display setups to ensure correct screen tracking.
- Test Markdown content variations (headings, lists, code) for legibility.
