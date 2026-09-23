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

/// A viewer has nothing to show once its last window (or tab) is closed, so quit instead of idling in the Dock.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct MarkdownPreviewApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            if let fileURL = file.fileURL {
                MarkdownWebView(fileURL: fileURL)
                    .overlay(alignment: .topTrailing) { EditButton(fileURL: fileURL) }
                    .frame(minWidth: 480, minHeight: 360)
            }
        }
        .defaultSize(width: 980, height: 1100)
    }
}
