# Development Roadmap

## Product Vision
SattoPad is a macOS menu bar memo app that prioritizes rapid capture and recall. Users press a global shortcut (default `Cmd + Shift + T`) to surface a lightweight overlay, while editing lives in a focused popover. The roadmap keeps the experience fast, distraction-free, and reliable.

## Milestones
- **M1 – Menu Bar MVP**: Implement `MenuBarExtra`, hide the Dock (`LSUIElement = YES`), and provide a sized popover with `TextEditor`. Acceptance: open/close from the menu bar and edit multi-line text without glitches.
- **M2 – Global Shortcut Toggle**: Register the press-and-hold shortcut, ideally via KeyboardShortcuts. Acceptance: `Cmd + Shift + T` shows the overlay while pressed, hides on key up, and detects conflicts gracefully.
- **M3 – Autosave & Load**: Persist notes at `~/Documents/SattoPad.md`, debounce writes (~1s), reload on launch, and let users pick a custom location through `NSOpenPanel`. Acceptance: restart restores content; path changes persist; errors surface to the user.
- **M4 – Overlay Polish**: Refine visuals (transparency, spacing) and deliver markdown preview parity. Acceptance: overlay remains responsive (<50ms show/hide) and aesthetically consistent.

## Delivery Principles
- Ship smallest viable increments and document manual test steps per milestone.
- Keep global state minimal; rely on `ObservableObject` bridges to propagate state between SwiftUI and AppKit.
- Perform disk I/O off the main thread; update UI on the main queue.
- Treat KeyboardShortcuts and markdown persistence as first-class dependencies to ensure future maintainability.

## Manual QA Checklist
- Launch → menu bar icon → popover edit → close/reopen smoothly.
- Shortcut works across Finder, Safari, Xcode, and respects accessibility permissions.
- Autosave flushes within 1s; relaunch recovers text; location changes propagate.
- Overlay stays within performance targets (CPU <1%, instant transitions).

## Branch & PR Strategy
- Use milestone-aligned branches (`feature/m1-menubar`, `feature/m3-autosave`).
- Keep PRs focused with self-review notes covering build status, manual checks, and outstanding risks.
- Require screenshot or video evidence for UI adjustments and document follow-up tasks in the PR body.
