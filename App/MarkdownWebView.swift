import AppKit
import MarkdownRenderer
import SwiftUI
import WebKit

private let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn"]
private let foldingScript = WKUserScript(
    source: (try? String(contentsOf: Bundle.main.url(forResource: "folding", withExtension: "js")!, encoding: .utf8)) ?? "",
    injectionTime: .atDocumentEnd, forMainFrameOnly: true)

/// WKWebView showing the rendered file; re-renders on save by swapping the body so the scroll position stays.
struct MarkdownWebView: NSViewRepresentable {
    let fileURL: URL
    @AppStorage(Zoom.defaultsKey) private var zoom = 1.0

    func makeCoordinator() -> Coordinator { Coordinator(fileURL: fileURL) }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(foldingScript)
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        context.coordinator.attach(webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.pageZoom = zoom
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let fileURL: URL
        private weak var webView: WKWebView?
        private var watcher: FileWatcher?
        private var foldingObserver: NSObjectProtocol?

        init(fileURL: URL) { self.fileURL = fileURL }

        deinit { foldingObserver.map(NotificationCenter.default.removeObserver) }

        func attach(_ webView: WKWebView) {
            self.webView = webView
            webView.loadHTMLString(MarkdownRenderer.shared.renderPage(fileURL: fileURL), baseURL: fileURL)
            watcher = FileWatcher(url: fileURL) { [weak self] in self?.reload() }
            foldingObserver = NotificationCenter.default.addObserver(forName: Folding.notification, object: nil, queue: .main) { [weak self] note in
                guard let action = note.object as? Folding.Action, let webView = self?.webView, webView.window?.isKeyWindow == true else { return }
                webView.evaluateJavaScript(action.rawValue)
            }
        }

        private func reload() {
            let body = MarkdownRenderer.shared.renderBody(fileURL: fileURL)
            guard let json = try? JSONEncoder().encode(body), let literal = String(data: json, encoding: .utf8) else { return }
            webView?.evaluateJavaScript("document.getElementById('content').innerHTML = \(literal); refreshFolds()")
        }

        /// Focus the page so arrow keys / space / End scroll right away.
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.window?.makeFirstResponder(webView)
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard action.navigationType == .linkActivated, let url = action.request.url else { return decisionHandler(.allow) }
            if isAnchorInCurrentDocument(url) { return decisionHandler(.allow) }
            decisionHandler(.cancel)
            if url.isFileURL && markdownExtensions.contains(url.pathExtension.lowercased()) {
                NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
            } else {
                NSWorkspace.shared.open(url)
            }
        }

        private func isAnchorInCurrentDocument(_ url: URL) -> Bool {
            url.fragment != nil && url.isFileURL && url.standardizedFileURL.path == fileURL.standardizedFileURL.path
        }
    }
}
