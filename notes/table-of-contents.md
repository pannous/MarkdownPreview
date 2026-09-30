# Collapsible table of contents

The app's `App/folding.js` builds a native HTML `details` control at the right edge below the floating Edit button. It starts collapsed, uses plain heading text for accessible navigation labels, and indents links by heading level. The fixed panel scrolls independently and follows the renderer's light/dark colors. Escape collapses it; focus returns to its summary when focus was inside the panel, and stays in the document otherwise.

`refreshFolds()` also refreshes its links, so the existing file-watcher content swap updates Contents while preserving the expanded/collapsed state. Selecting a link reveals the target's folded ancestor chain, focuses the exact heading element, and scrolls it into view. Exact element references also handle repeated heading labels. Documents with no headings hide the control.

The panel is app-only: Quick Look uses the shared CSS but does not inject the folding script.

Verification: `probes/table_of_contents.swift` loads actual MarkdownRenderer output in an offscreen WKWebView and checks toggling, ordered labels, indentation, folded navigation, duplicate labels, fixed positioning, reload, and heading-free documents. Compile/run commands are in README. The existing headless suite also passes.

Position assertions must use the document viewport width rather than the WKWebView frame width: native scrollbar space affects layout.

`probes/contents_dismissal.swift` checks the right-edge position and Escape behavior in a narrow offscreen WKWebView, including focus handling and unrelated keys.

The original Contents probe still asserts the previous position (top 12/right 112). Its other checks pass; that single obsolete assertion requires permission to update under the repository's test-preservation instructions. The new dismissal probe verifies the current position (top 52/right 12). The existing main headless suite passes.
