# Partial Clipboard Clearing

## Confirmed Behavior

- Yippy should support clearing only selected kinds of clipboard content instead of always clearing the entire clipboard.
- The first planned rule is: when macOS enters sleep, remove image content from the current system clipboard.
- The initial image-clearing behavior should be conservative:
  - Remove direct image representations from `NSPasteboard.general`.
  - Preserve non-image clipboard content when possible.
  - Preserve file URLs by default, even when they point to image files, because file URLs may represent a file-copy operation rather than direct image data.
- After Yippy rewrites or clears the system pasteboard, it should record the new pasteboard change count so the internal pasteboard monitor does not save Yippy's own cleanup as a new history item.

## Examples

- Clipboard contains only PNG image data.
  - Sleep begins.
  - Yippy clears the system clipboard.
  - Yippy records the new pasteboard change count.

- Clipboard contains text and an image representation in the same pasteboard item.
  - Sleep begins.
  - Yippy rewrites the pasteboard item with the text representation only.
  - The user can still paste the text after waking.

- Clipboard contains a file URL pointing to an image file.
  - Sleep begins.
  - Yippy keeps the file URL in the clipboard for the initial version.

## Implementation Notes

- Observe `NSWorkspace.willSleepNotification` to trigger sleep-time cleanup.
- `NSPasteboard` does not provide an API for deleting a single type in place. The expected implementation is:
  - Read `NSPasteboard.general.pasteboardItems`.
  - Create replacement `NSPasteboardItem` values containing only allowed types.
  - Call `clearContents()`.
  - Write the replacement items back when any allowed content remains.
  - Record the resulting change count in `History`.
- Candidate direct image types include:
  - `NSPasteboard.PasteboardType.png`
  - `NSPasteboard.PasteboardType.tiff`
  - `NSPasteboard.PasteboardType.pdf`, when used as image-like pasteboard data
  - `NSPasteboard.PasteboardType.fileContents`, when the data can be identified as image content
- This behavior should live outside the Yippy panel view controller. A dedicated model/service, for example `ClipboardCleanup` or `PasteboardCleaner`, would keep sleep-triggered cleanup separate from panel UI actions.
- User-facing option text should use the project's localization approach when localization infrastructure exists. If the project still lacks localization resources, note the gap rather than expanding this feature into a full app-wide localization migration.

## Open Decisions

- Should users be able to choose which pasteboard types are removed on sleep?
- Should image file URLs be removable behind a separate option?
- Should cleanup also run on lock screen, logout, app quit, or after a timer?
- Should Yippy remove matching items from saved clipboard history, or only clean the live system clipboard?
- Should pinned items be protected from any automatic cleanup?
- Should Yippy show a notification after automatic cleanup, or keep it silent?
- Should cleanup rules be global toggles or per-trigger rules?

## Future Ideas

- Remove images from clipboard after a configurable timeout.
- Remove sensitive-looking text after sleep, such as one-time codes or password-manager concealed pasteboard types.
- Clear large clipboard payloads automatically to reduce memory or disk usage.
- Add cleanup presets:
  - Privacy: remove images, concealed types, and transient types.
  - Lightweight: remove large binary payloads.
  - Text only: preserve plain text and remove everything else.
- Add a manual panel action that offers selective cleanup options instead of only clearing everything.
- Add a dry-run/debug log for cleanup decisions while the feature is being developed.

## Release Verification Checks

- [ ] With image-only clipboard content, sleep-triggered cleanup leaves the system clipboard empty.
- [ ] With mixed text and image content, sleep-triggered cleanup preserves pasteable text and removes image data.
- [ ] With file URL clipboard content, the initial version preserves the file URL.
- [ ] Yippy does not add a new history item for its own automatic cleanup.
- [ ] Existing manual clear clipboard behavior still clears the full clipboard and history.
- [ ] Cleanup does not run while the feature option is disabled.
