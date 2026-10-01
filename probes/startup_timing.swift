// Where a window's first paint goes: renderer setup, rendering, WebKit page load, font loading. Offscreen, no window.
// Usage: startup_timing <file.md>   Build: see probes/test.sh
import AppKit
import MarkdownRenderer
import WebKit

@main
enum StartupTiming {
    static let start = Date()
    static func stage(_ name: String) { print(String(format: "%6.0f ms  %@", Date().timeIntervalSince(start) * 1000, name)) }

    @MainActor static func main() async {
        _ = start
        let fileURL = URL(fileURLWithPath: CommandLine.arguments[1])
        _ = MarkdownRenderer.shared; stage("renderer ready (JavaScriptCore + marked + highlight.js)")
        let page = MarkdownRenderer.shared.renderPage(fileURL: fileURL); stage("page rendered (\(page.utf8.count / 1024) KB)")
        _ = MarkdownRenderer.shared.renderPage(fileURL: fileURL); stage("page rendered again (what stays per render)")
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(UserFontSchemeHandler(), forURLScheme: UserFontSchemeHandler.scheme)
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 700), configuration: configuration); stage("web view created")
        webView.loadHTMLString(page, baseURL: fileURL)
        while (try? await webView.evaluateJavaScript("document.readyState")) as? String != "complete" { try? await Task.sleep(for: .milliseconds(5)) }
        stage("document loaded")
        _ = try? await webView.callAsyncJavaScript("return 1", contentWorld: .page); stage("trivial async call")
        while (try? await webView.evaluateJavaScript("document.fonts.status")) as? String != "loaded" { try? await Task.sleep(for: .milliseconds(5)) }
        stage("fonts loaded")
        exit(0)
    }
}
