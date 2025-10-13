# Autosave System

## Objectives
Persist user notes to a Markdown file automatically and reliably, supporting both sandboxed and non-sandboxed builds. Preserve the user’s chosen location, debounce writes, and surface clear feedback on failures.

## Default Behaviour
- Initial path: `~/Documents/SattoPad.md`; create the file and parent directory on first save.
- Debounce: save ~1s after the last edit to avoid excessive disk writes.
- Encoding: UTF-8 without BOM; normalise line endings to `\n` when reading.
- Atomic writes: use temporary files or `write(to:options:.atomic)` to prevent corruption.

## Configurability
- `selectSaveLocation()` opens `NSOpenPanel`; directories append `SattoPad.md` automatically.
- Store `sattoPad.markdownPath` and security-scoped bookmarks (`sattoPad.markdownBookmark`) in `UserDefaults`.
- Always call `startAccessingSecurityScopedResource()` / `stopAccessing…` around sandbox file access.

## Runtime Behaviour
- Compare text with `lastSavedText` to skip no-op writes.
- Flush pending work on explicit `saveNow()` (e.g., when closing the popover).
- Provide a manual “Reload from File” action that warns if unsaved edits exist.
- Watch for external changes via `DispatchSourceFileSystemObject`; ignore events within ~1s of SattoPad’s own writes, then reload or prompt the user.

## Error Handling
- Read failures: keep existing text visible, set `lastErrorMessage`, and prompt users to reselect a path.
- Write failures: retry twice with exponential backoff; on final failure, display an alert and expose the destination picker.
- Bookmark failures: request the user to re-authorise the location.

## Testing Checklist
- Default path: edit → wait 1s → quit → relaunch → content restored.
- Change location: pick Desktop, verify subsequent saves and reload persistence.
- External edit: modify the file in another editor; confirm SattoPad notices and prompts appropriately.
- Permission loss: revoke access and observe error messaging, ensuring no data loss.
