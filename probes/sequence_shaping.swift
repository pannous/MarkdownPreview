// Renders a page in an offscreen WKWebView (no window) and prints, per list item, its width in em: a composed hieroglyph
// group or ideographic description sequence is about one sign wide, a broken one three. Saves a snapshot PNG.
// Usage: sequence_shaping <page.html> <snapshot.png>
import AppKit
import MarkdownRenderer
import WebKit

private let widthsInEm = """
[...document.querySelectorAll('li')].map(item => {
  const range = document.createRange(); range.selectNodeContents(item);
  return (range.getBoundingClientRect().width / parseFloat(getComputedStyle(item).fontSize)).toFixed(2) + ' ' + item.textContent;
}).join('\\n')
"""

@main
enum SequenceShaping {
    @MainActor static func main() async {
        let arguments = CommandLine.arguments
        let html = try! String(contentsOfFile: arguments[1], encoding: .utf8)
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(UserFontSchemeHandler(), forURLScheme: UserFontSchemeHandler.scheme)
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 700, height: 300), configuration: configuration)
        webView.loadHTMLString(html, baseURL: URL(fileURLWithPath: arguments[1]))
        while (try? await webView.evaluateJavaScript("document.readyState")) as? String != "complete" { try? await Task.sleep(for: .milliseconds(50)) }
        _ = try? await webView.callAsyncJavaScript("await document.fonts.ready; return 1", contentWorld: .page)
        try? await Task.sleep(for: .milliseconds(500))
        print((try? await webView.evaluateJavaScript(widthsInEm)) as? String ?? "<error>")
        if let image = try? await webView.takeSnapshot(configuration: nil), let tiff = image.tiffRepresentation,
           let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: arguments[2]))
        }
    }
}
