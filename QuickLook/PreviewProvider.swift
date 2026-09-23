import MarkdownRenderer
import QuickLookUI

private let previewSize = CGSize(width: 980, height: 1100)

/// Data-based Quick Look preview (Finder space bar, Spotlight): hands the rendered HTML to Quick Look's WebKit view.
final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let fileURL = request.fileURL
        let page = MarkdownRenderer.shared.renderPage(fileURL: fileURL)
        return QLPreviewReply(dataOfContentType: .html, contentSize: previewSize) { reply in
            reply.stringEncoding = .utf8
            reply.title = fileURL.lastPathComponent
            return Data(page.utf8)
        }
    }
}
