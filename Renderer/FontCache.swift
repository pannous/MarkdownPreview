import Foundation

private let cacheFolderName = "com.pannous.MarkdownPreview"
private let cacheFileName = "user-fonts.json"

/// Font answers that cost CoreText hundreds of milliseconds per render (which user-installed font draws a character,
/// which file holds a PostScript name), kept on disk until a font file is added, removed or replaced, or macOS updates.
struct FontCache: Codable {
    struct Font: Codable, Equatable {
        let family: String
        let path: String
        /// Covers the standard hieroglyph block, so it is enlarged like the sequence hieroglyph font
        let drawsHieroglyphs: Bool
    }

    /// Characters a system font draws are stored without a font
    struct Fallback: Codable {
        let font: Font?
    }

    private(set) var signature: String
    var filesByPostScriptName: [String: String]?
    var fallbackByScalar: [UInt32: Fallback] = [:]

    static let fontFolders = FileManager.default.urls(for: .libraryDirectory, in: [.userDomainMask, .localDomainMask])
        .map { $0.appendingPathComponent("Fonts") }

    private static let fileURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(cacheFolderName).appendingPathComponent(cacheFileName)

    /// Name, size and modification date of every installed font file, plus the macOS version (system fonts)
    private static func currentSignature() -> String {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        let files = fontFolders.flatMap { (try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: keys)) ?? [] }
        let entries = files.map { file -> String in
            let values = try? file.resourceValues(forKeys: Set(keys))
            return "\(file.path) \(values?.fileSize ?? 0) \(values?.contentModificationDate?.timeIntervalSince1970 ?? 0)"
        }
        return ([ProcessInfo.processInfo.operatingSystemVersionString] + entries.sorted()).joined(separator: "\n")
    }

    static func load() -> FontCache {
        let signature = currentSignature()
        guard let data = try? Data(contentsOf: fileURL), let cache = try? JSONDecoder().decode(FontCache.self, from: data),
              cache.signature == signature else { return FontCache(signature: signature) }
        return cache
    }

    func save() {
        do {
            try FileManager.default.createDirectory(at: Self.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(self).write(to: Self.fileURL, options: .atomic)
        } catch {
            NSLog("FontCache: cannot save %@: %@", Self.fileURL.path, "\(error)")
        }
    }
}
