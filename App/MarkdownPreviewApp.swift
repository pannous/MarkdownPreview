import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let markdownText = UTType(importedAs: "net.daringfireball.markdown", conformingTo: .plainText)
}

struct MarkdownDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.markdownText]

    init(configuration: ReadConfiguration) throws {}

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.featureUnsupported)
    }
}

@main
struct MarkdownPreviewApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            if let fileURL = file.fileURL {
                MarkdownWebView(fileURL: fileURL).frame(minWidth: 480, minHeight: 360)
            }
        }
        .defaultSize(width: 980, height: 1100)
    }
}
