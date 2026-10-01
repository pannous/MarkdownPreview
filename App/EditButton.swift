import AppKit
import SwiftUI

/// First installed editor wins; override with `defaults write com.pannous.MarkdownPreview editorBundleIdentifier <bundle id>`.
private let editorOverrideKey = "editorBundleIdentifier"
/// Keeps the button clear of the web view's overlay scroller.
private let scrollerClearance: CGFloat = 20
private let preferredEditorBundleIdentifiers = ["com.sublimetext.4", "com.sublimetext.3", "com.microsoft.VSCode", "com.apple.TextEdit"]

enum Editor {
    static var applicationURL: URL? {
        let override = UserDefaults.standard.string(forKey: editorOverrideKey)
        return ([override].compactMap { $0 } + preferredEditorBundleIdentifiers)
            .lazy.compactMap(NSWorkspace.shared.urlForApplication(withBundleIdentifier:)).first
    }

    static var name: String { applicationURL.map { FileManager.default.displayName(atPath: $0.path) } ?? "editor" }

    static func open(_ fileURL: URL) {
        guard let applicationURL else { return NSSound.beep() }
        NSWorkspace.shared.open([fileURL], withApplicationAt: applicationURL, configuration: NSWorkspace.OpenConfiguration())
    }
}

/// Small floating button (and ⌘E) that opens the previewed file in the text editor.
struct EditButton: View {
    let fileURL: URL

    var body: some View {
        Button { Editor.open(fileURL) } label: { Label("Edit", systemImage: "square.and.pencil") }
            .keyboardShortcut("e")
            .help("Edit in \(Editor.name) (⌘E)")
            .floating()
    }
}

/// Fix (⌘⇧L) rewrites the file so every newline inside a paragraph becomes a hard line break; live reload shows the result.
struct FixLineBreaksButton: View {
    let fileURL: URL

    var body: some View {
        Button { LineBreaks.fix(fileURL) } label: { Label("Fix", systemImage: "text.append") }
            .keyboardShortcut("l", modifiers: [.command, .shift])
            .help("Add two trailing spaces so every newline shows as a line break (⌘⇧L)")
            .floating()
    }
}

/// The buttons floating over the top right corner of the page.
struct FileButtons: View {
    let fileURL: URL

    var body: some View {
        HStack {
            FixLineBreaksButton(fileURL: fileURL)
            EditButton(fileURL: fileURL)
        }
        .padding(12)
        .padding(.trailing, scrollerClearance)
    }
}

private extension View {
    func floating() -> some View {
        buttonStyle(.bordered).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}
