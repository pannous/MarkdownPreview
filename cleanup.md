# Table of contents implementation

- Reuse the app's heading/folding script and existing live-reload hook.
- Position Contents against the right edge below Edit and collapse it on Escape.
- Add an offscreen probe for dismissal, keyboard focus, and the new position; preserve existing tests.
- Navigate to headings while revealing folded ancestors; rebuild links on reload without resetting the panel.
- Verify with a new offscreen WKWebView probe and the existing headless suite, then build and commit.
- Preserve the existing user change to `probes/app_window.png` and all existing tests.
