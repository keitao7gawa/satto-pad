# Refactoring Roadmap

## Guiding Principles
- Preserve all existing behaviour, shortcut flows, and autosave semantics.
- Maintain performance budgets: overlay transitions <50ms, idle CPU <1%, memory <100MB.
- Submit incremental, reviewable changes with clear manual test notes.

## Focus Areas
- **ContentView Decomposition**: Extract header/UI controls into dedicated views (`OverlayHeaderView`, `TrailingMenuButtons`, `FontStepperView`). Centralise layout constants in `HeaderLayoutConstants` and move reusable controls such as `RepeatButton` into shared components.
- **Overlay Preview Cleanup**: 既存の MarkdownUI テーマ設定を見直し、`OverlayPreviewView` の責務を描画ロジックとレイアウト調整に集中させる。`@AppStorage` の利用を最小限にし、テスト可能性を高める。
- **OverlayManager Simplification**: Isolate window creation, state toggling, and delegate callbacks. Persist positions during `windowDidEndLiveResize`, and ensure adjustments toggle as a single mode.
- **OverlaySettingsStore Hygiene**: Namespace `UserDefaults` keys in a private `Keys` enum and consider property wrappers to reduce boilerplate.
- **MarkdownStore Maintenance**: Separate debounce scheduling, file monitoring, and bookmark handling into dedicated helpers. Keep Combine adoption optional but ensure retry/backoff logic remains intact.
- **UI Styles & Utilities**: Group menu/button styles under a shared module (`UI/Styles`), and expose common behaviour (e.g., hiding menu indicators) as reusable modifiers.

## Suggested Sequence
1. Introduce layout constants and shared UI components.
2. Extract header/tooling views and adopt them across both popover variants.
3. Refactor overlay preview rendering helpers.
4. Reorganise `OverlayManager` responsibilities.
5. Tidy settings store keys and wrappers.
6. Break out `MarkdownStore` helpers, verifying autosave tests after each change.

## Regression Suite
- Popover open/close, Escape dismissal, and shortcut toggling behave identically pre/post refactor.
- Overlay visibility, movement, resize, opacity, and font adjustments remain instant and precise.
- Autosave continues to debounce writes, reload, and detect external edits.
- UI layout, hit areas, and icon alignment remain unchanged compared with screenshots.
