# MarkdownPreview

Native macOS Markdown viewer plus a Quick Look extension, both backed by one renderer.

- GitHub-flavoured Markdown: bordered tables, fenced code with syntax highlighting, task lists, strikethrough, autolinks, heading anchors.
- Images relative to the file are inlined; follows system light/dark mode; no network needed for rendering.
- Live reload on save (also atomic saves), scroll position kept. Links open in the default browser only when clicked; relative `.md` links open in the app.
- `open -a MarkdownPreview file.md` on an already open file focuses its window.
- Finder space bar and Spotlight show the same rendering through the embedded Quick Look extension.

## Build & install

```sh
./install.sh   # xcodegen + xcodebuild, installs ~/Applications/MarkdownPreview.app, registers app and extension
probes/test.sh # end-to-end checks; writes probes/quicklook.png and probes/app_window.png
```

Needs Xcode and XcodeGen (`brew install xcodegen`). Signing uses the local "Apple Development" identity; override with `SIGN_IDENTITY=-` for ad hoc.

## Layout

| Path | What |
|------|------|
| `Renderer/` | `MarkdownRenderer.framework`: marked + highlight.js run in JavaScriptCore, CSS, HTML page template |
| `App/` | SwiftUI `DocumentGroup` viewer, `WKWebView`, file watcher |
| `QuickLook/` | data-based Quick Look preview extension returning the rendered HTML |
| `probes/` | sample files and test script |
| `notes/` | tricky parts (signing, Quick Look, sandbox, testing) |
