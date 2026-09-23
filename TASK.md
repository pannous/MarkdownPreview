# Task: MarkdownPreview — native macOS Markdown viewer + Quick Look extension

Build a small native macOS Markdown preview app in Swift here (~/dev/apps/MarkdownPreview). Start a new git repo; commit as you go (conventional commits, no AI attribution trailers).

1. SwiftUI macOS app "MarkdownPreview" that opens .md files (document viewer, registered for the net.daringfireball.markdown UTI, plus .md/.markdown extensions). Render full GitHub-flavoured Markdown: tables (borders, header styling), task lists, fenced code blocks with syntax highlighting, images relative to the file, links, clean readable typography following system light/dark mode. WKWebView inside the app with a bundled renderer (swift-markdown / cmark-gfm via SwiftPM, or bundled JS, no network) is fine. It must NOT open an external browser; links open in the default browser only when clicked.
2. Live reload: watch the opened file, re-render on save keeping scroll position. `open -a MarkdownPreview file.md` on an already-open file focuses the existing window instead of duplicating it.
3. Quick Look Preview Extension (appex embedded in the app) for Markdown, so the same rendering shows in Finder space-bar Quick Look and Spotlight previews. Share the rendering code (framework/shared target), no duplication.
4. Build with xcodebuild (XcodeGen project.yml or .xcodeproj), sign ad hoc / local dev identity, install to ~/Applications/MarkdownPreview.app, register via `lsregister -f`, `pluginkit -a` / `pluginkit -e use`, `qlmanage -r`. One build+install script (install.sh).
5. Test for real: `qlmanage -p` on a sample .md with table + code block; `pluginkit -m -v | grep -i markdown` shows the extension enabled; screenshot the app window (screencapture into probes/) and verify tables and code render. Sample/test files under probes/.
6. When it works, integrate into ~/dev/script/shell/build.sh: replace the body of `preview_markdown()` (currently glow) with `open -a MarkdownPreview "$file"`, and update ~/dev/script/notes/markdown-preview.md to state this is the current solution (glow, pandoc+Chromium and MarkdownLivePreview are rejected: user dislikes glow output, wants no browser, needs tables). Commit and push in ~/dev/script — mono-repo: only touch those two files, the user has other uncommitted changes there that must not be committed.
7. Notes on tricky parts (Quick Look registration, sandbox entitlements, …) in notes/, plus a short README.

Don't ask questions; make sensible assumptions and finish the job.
