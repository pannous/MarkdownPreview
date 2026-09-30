import AppKit
import MarkdownRenderer
import WebKit

private let probesDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
private let readinessAttempts = 100
private let checks = [
    ("Contents is fixed beneath Edit at the right edge", "const bounds = panel.getBoundingClientRect(); return getComputedStyle(panel).position === 'fixed' && bounds.top === 52 && Math.abs(bounds.right - (document.documentElement.clientWidth - 12)) < 1;"),
    ("Escape closes Contents from a link and returns focus", "panel.open = true; panel.querySelector('a').focus(); const event = new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true }); document.activeElement.dispatchEvent(event); return !panel.open && event.defaultPrevented && document.activeElement === panel.querySelector('summary');"),
    ("Escape closes Contents from the document without moving focus", "panel.open = true; const heading = document.querySelector('#content h1'); heading.tabIndex = -1; heading.focus(); heading.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true })); return !panel.open && document.activeElement === heading;"),
    ("other keys leave Contents open", "panel.open = true; document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true })); return panel.open;"),
    ("Escape leaves a closed panel untouched", "panel.open = false; const event = new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true }); document.dispatchEvent(event); return !panel.open && !event.defaultPrevented;"),
]

@main
enum ContentsDismissalProbe {
    @MainActor static func main() async throws {
        let script = try String(contentsOf: probesDirectory.appendingPathComponent("../App/folding.js"), encoding: .utf8)
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 480, height: 360), configuration: configuration)
        webView.loadHTMLString(MarkdownRenderer.shared.renderPage(markdown: "# Heading\nText", baseDirectory: nil), baseURL: nil)
        for _ in 0..<readinessAttempts {
            if (try? await webView.evaluateJavaScript("!!document.querySelector('#table-of-contents')")) as? Bool == true { break }
            try await Task.sleep(for: .milliseconds(50))
        }
        var failures = 0
        for (description, check) in checks {
            let result = try await webView.evaluateJavaScript("(() => { const panel = document.querySelector('#table-of-contents'); \(check) })()") as? Bool == true
            print("\(result ? "ok  " : "FAIL") \(description)")
            if !result { failures += 1 }
        }
        exit(Int32(failures))
    }
}
