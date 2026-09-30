import AppKit
import MarkdownRenderer
import WebKit

private let markdown = """
# Start
Intro
## Child *heading*
Child text
### Deep
Deep text
## Child *heading*
Another child
# End
End text
"""
private let probesDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
private let readinessAttempts = 100

@main
enum TableOfContentsProbe {
    static var failures = 0

    @MainActor static func evaluate(_ webView: WKWebView, _ script: String) async -> String {
        do {
            guard let value = try await webView.evaluateJavaScript(script) else { return "undefined" }
            return String(describing: value)
        }
        catch { return "JavaScript error: \(error)" }
    }

    @MainActor static func expect(_ webView: WKWebView, _ description: String, _ script: String) async {
        let result = await evaluate(webView, script)
        print(result == "1" ? "ok  \(description)" : "FAIL \(description): \(result)")
        if result != "1" { failures += 1 }
    }

    @MainActor static func main() async throws {
        let script = try String(contentsOf: probesDirectory.appendingPathComponent("../App/folding.js"), encoding: .utf8)
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), configuration: configuration)
        webView.loadHTMLString(MarkdownRenderer.shared.renderPage(markdown: markdown, baseDirectory: nil), baseURL: nil)
        for _ in 0..<readinessAttempts {
            if await evaluate(webView, "!!document.querySelector('#table-of-contents')") == "1" { break }
            try await Task.sleep(for: .milliseconds(50))
        }
        await expect(webView, "Contents starts collapsed", "document.querySelector('#table-of-contents')?.open === false")
        await expect(webView, "all headings appear in document order with plain labels", "[...document.querySelectorAll('#table-of-contents a')].map(a => a.textContent).join('|') === 'Start|Child heading|Deep|Child heading|End'")
        await expect(webView, "levels are indented", "getComputedStyle(document.querySelectorAll('#table-of-contents a')[2]).paddingLeft !== getComputedStyle(document.querySelector('#table-of-contents a')).paddingLeft")
        await expect(webView, "summary expands and collapses", "(() => { const panel = document.querySelector('#table-of-contents'); panel.querySelector('summary').click(); const expanded = panel.open; panel.querySelector('summary').click(); return expanded && !panel.open; })()")
        await expect(webView, "navigation reveals folded ancestors and focuses target", "foldDeepest(); foldDeepest(); foldDeepest(); document.querySelectorAll('#table-of-contents a')[2].click(); document.querySelector('#deep').offsetParent !== null && document.activeElement.id === 'deep'")
        await expect(webView, "duplicate heading labels navigate to the exact heading", "document.querySelectorAll('#table-of-contents a')[3].click(); document.activeElement === document.querySelectorAll('#content h2')[1]")
        await expect(webView, "panel stays at upper right while scrolling", "(() => { const panel = document.querySelector('#table-of-contents'); const bounds = panel.getBoundingClientRect(); return getComputedStyle(panel).position === 'fixed' && bounds.top === 12 && Math.abs(bounds.right - (document.documentElement.clientWidth - 112)) < 1; })()")
        await expect(webView, "reload updates headings and preserves expansion", "document.querySelector('#table-of-contents').open = true; document.querySelector('#content').innerHTML = '<h1 id=updated>Updated</h1><p>New text</p>'; refreshFolds(); document.querySelector('#table-of-contents').open && document.querySelector('#table-of-contents a').textContent === 'Updated' && document.querySelectorAll('#table-of-contents a').length === 1")
        await expect(webView, "no headings hides the panel", "document.querySelector('#content').innerHTML = '<p>No headings</p>'; refreshFolds(); document.querySelector('#table-of-contents').hidden")
        await expect(webView, "headings returning restores the panel", "document.querySelector('#content').innerHTML = '<h2 id=back>Back</h2>'; refreshFolds(); !document.querySelector('#table-of-contents').hidden && document.querySelector('#table-of-contents').open")
        print("\(failures) failure(s)")
        exit(Int32(failures))
    }
}
