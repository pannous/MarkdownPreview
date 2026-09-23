import Foundation
import JavaScriptCore
import UniformTypeIdentifiers

/// Renders GitHub-flavoured Markdown to self-contained HTML (styles inlined, local images as data URIs),
/// shared by the app window and the Quick Look extension.
public final class MarkdownRenderer {
    public static let shared = MarkdownRenderer()

    private static let scriptNames = ["marked", "highlight", "render"]
    private static let remoteSchemes: Set<String> = ["http", "https", "data"]

    private let context = JSContext()!
    private let lock = NSLock()
    private let stylesheet: String
    private var baseDirectory: URL?

    private init() {
        let bundle = Bundle(for: MarkdownRenderer.self)
        func resource(_ name: String, _ ext: String) -> String {
            guard let url = bundle.url(forResource: name, withExtension: ext), let text = try? String(contentsOf: url, encoding: .utf8)
            else { fatalError("MarkdownRenderer: missing bundled resource \(name).\(ext)") }
            return text
        }
        // style.css comes last so it overrides the highlight.js theme padding/background
        stylesheet = resource("hljs-light", "css") + "@media (prefers-color-scheme: dark) {" + resource("hljs-dark", "css") + "}"
            + resource("style", "css")

        context.exceptionHandler = { _, exception in NSLog("MarkdownRenderer JS error: %@", exception?.toString() ?? "?") }
        let resolveImage: @convention(block) (String) -> String = { [unowned self] source in self.inlineImage(source) }
        context.setObject(resolveImage, forKeyedSubscript: "resolveImage" as NSString)
        for name in Self.scriptNames { context.evaluateScript(resource(name, "js")) }
    }

    /// HTML fragment for the document body; relative image paths resolve against `baseDirectory`.
    public func renderBody(markdown: String, baseDirectory: URL?) -> String {
        lock.lock(); defer { lock.unlock() }
        self.baseDirectory = baseDirectory
        return context.objectForKeyedSubscript("renderMarkdown").call(withArguments: [markdown]).toString() ?? ""
    }

    /// Body for a Markdown file on disk, with images relative to the file's folder.
    public func renderBody(fileURL: URL) -> String {
        renderBody(markdown: Self.readMarkdown(at: fileURL), baseDirectory: fileURL.deletingLastPathComponent())
    }

    public func renderPage(fileURL: URL) -> String {
        renderPage(markdown: Self.readMarkdown(at: fileURL), baseDirectory: fileURL.deletingLastPathComponent(), title: fileURL.lastPathComponent)
    }

    /// UTF-8 with a lossy fallback so a stray byte never blanks the preview.
    public static func readMarkdown(at fileURL: URL) -> String {
        guard let data = try? Data(contentsOf: fileURL) else { return "" }
        return String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
    }

    /// Complete standalone HTML page.
    public func renderPage(markdown: String, baseDirectory: URL?, title: String = "") -> String {
        let body = renderBody(markdown: markdown, baseDirectory: baseDirectory)
        return """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8"><meta name="color-scheme" content="light dark">
        <title>\(title)</title><style>\(stylesheet)</style></head>
        <body><article id="content" class="markdown-body">\(body)</article></body></html>
        """
    }

    private func inlineImage(_ source: String) -> String {
        let decoded = source.replacingOccurrences(of: "&amp;", with: "&")
        if let scheme = URL(string: decoded)?.scheme?.lowercased(), Self.remoteSchemes.contains(scheme) { return source }
        let path = decoded.removingPercentEncoding ?? decoded
        let url = path.hasPrefix("file://") ? URL(string: decoded) : URL(fileURLWithPath: path, relativeTo: path.hasPrefix("/") ? nil : baseDirectory)
        guard let url, let data = try? Data(contentsOf: url) else { return source }
        let mimeType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        return "data:\(mimeType);base64,\(data.base64EncodedString())"
    }
}
