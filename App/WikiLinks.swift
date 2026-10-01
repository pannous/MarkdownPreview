import Foundation

/// Directories never searched for a page: version control, build output, dependencies.
private let skippedDirectories: Set<String> = ["build", "target", "node_modules", "DerivedData"]
private let wordSeparators = CharacterSet(charactersIn: " -_")
private let markdownExtension = "md"

/// [[page]] links to files that are not next to the document, resolved like Sublime's MarkdownEditing wiki_page.py:
/// the document's folder tree is searched, ignoring case and treating " ", "-" and "_" alike; a "dir/page" link only
/// matches inside a folder ending in dir. A page found nowhere opens as a new file in the editor.
enum WikiLinks {
    static func resolve(_ link: URL, from document: URL) -> URL? {
        let root = document.deletingLastPathComponent()
        let subdirectory = link.deletingLastPathComponent().path.dropFirst(root.path.count).trimmingCharacters(in: ["/"])
        let wanted = comparable(link.lastPathComponent)
        guard let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey],
                                                         options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { return nil }
        var matches: [URL] = []
        for case let file as URL in files {
            if skippedDirectories.contains(file.lastPathComponent) { files.skipDescendants(); continue }
            guard comparable(file.lastPathComponent) == wanted else { continue }
            if subdirectory.isEmpty || file.deletingLastPathComponent().path.hasSuffix("/" + subdirectory) { matches.append(file) }
        }
        return matches.min { $0.pathComponents.count < $1.pathComponents.count }
    }

    /// Where a page found nowhere goes: next to the link's target, spaces become dashes
    static func newPage(_ link: URL) -> URL {
        let page = link.deletingPathExtension().lastPathComponent.replacingOccurrences(of: " ", with: "-")
        return link.deletingLastPathComponent().appendingPathComponent(page).appendingPathExtension(markdownExtension)
    }

    /// The new page on disk with a "# page" title, for editors that cannot open a file that does not exist yet
    static func create(_ page: URL) throws {
        try FileManager.default.createDirectory(at: page.deletingLastPathComponent(), withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: page.path) {
            try "# \(page.deletingPathExtension().lastPathComponent)\n".write(to: page, atomically: true, encoding: .utf8)
        }
    }

    private static func comparable(_ name: String) -> String {
        name.lowercased().components(separatedBy: wordSeparators).joined(separator: "-")
    }
}
