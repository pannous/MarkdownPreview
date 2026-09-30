# Table of contents implementation

- Reuse the app's heading/folding script and existing live-reload hook.
- Add an accessible, initially collapsed Contents panel beside Edit in the upper-right corner.
- Navigate to headings while revealing folded ancestors; rebuild links on reload without resetting the panel.
- Verify with a new offscreen WKWebView probe and the existing headless suite, then build and commit.
- Preserve the existing user change to `probes/app_window.png` and all existing tests.
