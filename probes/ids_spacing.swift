// Composed ideographic description sequences: WebKit measures every ideograph as a possible line break on its own, so each
// zero-width component kept a full em (a gap of 4 em after ⿰讠⿱人工 before a double space or at the end of bold text).
// Renders probes/hanzi/spacing.md in an offscreen WKWebView and expects each item "x <sequence> y" to span what
// "x 人 y" spans: from the left edge of x to the right edge of y. Build: see probes/test.sh
import AppKit
import MarkdownRenderer
import WebKit

private let maximumExtraWidthInEm = 0.3
private let spansInEm = """
[...document.querySelectorAll('li')].map(item => {
  const texts = document.createTreeWalker(item, NodeFilter.SHOW_TEXT), first = texts.nextNode(), range = document.createRange();
  let last = first; while (texts.nextNode()) last = texts.currentNode;
  range.setStart(first, 0); range.setEnd(first, 1); const left = range.getBoundingClientRect().left;
  range.setStart(last, last.length - 1); range.setEnd(last, last.length);
  return [(range.getBoundingClientRect().right - left) / parseFloat(getComputedStyle(item).fontSize), item.textContent];
})
"""

@main
enum IdsSpacing {
    @MainActor static func main() async {
        let markdownURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("hanzi/spacing.md")
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(UserFontSchemeHandler(), forURLScheme: UserFontSchemeHandler.scheme)
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 600), configuration: configuration)
        webView.loadHTMLString(MarkdownRenderer.shared.renderPage(fileURL: markdownURL), baseURL: markdownURL)
        while (try? await webView.evaluateJavaScript("document.readyState")) as? String != "complete" { try? await Task.sleep(for: .milliseconds(50)) }
        _ = try? await webView.callAsyncJavaScript("await document.fonts.ready; return 1", contentWorld: .page)
        try? await Task.sleep(for: .milliseconds(500))
        let spans = (try? await webView.evaluateJavaScript(spansInEm)) as? [[Any]] ?? []
        guard let reference = spans.first?[0] as? Double else { print("FAIL no list items"); exit(1) }
        var failures = 0
        for span in spans.dropFirst() {
            guard let width = span[0] as? Double, let text = span[1] as? String else { continue }
            let fits = width - reference < maximumExtraWidthInEm
            print(fits ? "ok  " : "FAIL", String(format: "%.2f em (reference %.2f)", width, reference), text)
            if !fits { failures += 1 }
        }
        print("\(failures) failure(s)")
        exit(Int32(failures))
    }
}
