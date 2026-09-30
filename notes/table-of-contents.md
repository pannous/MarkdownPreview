# Collapsible table of contents

The app's `App/folding.js` builds a native HTML `details` control beside the floating Edit button. It starts collapsed, uses plain heading text for accessible navigation labels, and indents links by heading level. The fixed panel scrolls independently and follows the renderer's light/dark colors.

`refreshFolds()` also refreshes its links, so the existing file-watcher content swap updates Contents while preserving the expanded/collapsed state. Selecting a link reveals the target's folded ancestor chain, focuses the exact heading element, and scrolls it into view. Exact element references also handle repeated heading labels. Documents with no headings hide the control.

The panel is app-only: Quick Look uses the shared CSS but does not inject the folding script.

Verification: `probes/table_of_contents.swift` loads actual MarkdownRenderer output in an offscreen WKWebView and checks toggling, ordered labels, indentation, folded navigation, duplicate labels, fixed positioning, reload, and heading-free documents. Compile/run commands are in README. The existing headless suite also passes.

Position assertions must use the document viewport width rather than the WKWebView frame width: native scrollbar space affects layout.
