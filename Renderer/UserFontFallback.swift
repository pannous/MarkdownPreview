import CoreText
import Foundation
import WebKit

/// WebKit's per-character font fallback only considers system fonts, and WebKit no longer resolves user-installed fonts
/// by family name either (macOS 27), so characters covered solely by a font in ~/Library/Fonts render as boxes.
/// CoreText's fallback does search every installed font (backed by the system's own coverage index), so lay the
/// document's distinct characters out once, collect the fonts it picked from outside /System, and hand WebKit their
/// files through `@font-face` rules on the `userfont:` scheme (served by `UserFontSchemeHandler`, or attached by Quick Look).
///
/// Uniscript sequences only shape when one font draws the whole sequence, which per-character fallback never does:
/// a hieroglyph group (joiners U+13430…) or an ideographic description ⿰犭句. Their fonts come first in the stack, each
/// behind a unicode-range so it only draws its script (NewGardinerOmni also has brackets).
enum UserFontFallback {
    struct SequenceFont {
        let alias: String
        let postScriptName: String
        let triggers: [ClosedRange<UInt32>]
        let unicodeRange: String
        var sizeAdjust: String? = nil
    }

    static let scheme = "userfont"
    /// NewGardinerOmni fits a whole quadrat into one em, so a stacked group looks cramped next to Latin text
    private static let hieroglyphScale = "155%"
    private static let baseFont = CTFontCreateUIFontForLanguage(.system, 16, nil)!
    private static let systemFontsPrefix = "/System/"
    private static let sequenceFonts = [
        SequenceFont(alias: "Sequence Hieroglyphs", postScriptName: "NewGardinerOmni-Regular",
                     triggers: [0x13430...0x1345F], unicodeRange: "U+13000-143FF", sizeAdjust: hieroglyphScale),
        // composes IDS of its ~1,900 parts into new characters (⿰讠尤); characters it lacks fall through to Uniscript CJK
        SequenceFont(alias: "Sequence New Ideographs", postScriptName: "UniscriptHanzi-Regular",
                     triggers: [0x2FF0...0x2FFF], unicodeRange: "U+2E80-2FFF, U+3000-9FFF, U+F900-FAFF, U+20000-3FFFF"),
        SequenceFont(alias: "Sequence Ideographs", postScriptName: "UniscriptCJK-Regular",
                     triggers: [0x2FF0...0x2FFF, 0x31EF...0x31EF], unicodeRange: "U+2E80-2FFF, U+3000-9FFF, U+F900-FAFF, U+20000-3FFFF"),
    ]

    private static func distinctScalars(_ text: String) -> Set<Unicode.Scalar> {
        Set(text.unicodeScalars.lazy.filter { !$0.isASCII })
    }

    /// PostScript name → file of the sequence fonts in the font folders, scanned once: CoreText no longer finds
    /// user-installed fonts by name (macOS 27), though its fallback still uses them
    private static let installedFontFiles: [String: URL] = {
        let wanted = Set(sequenceFonts.map(\.postScriptName))
        let folders = FileManager.default.urls(for: .libraryDirectory, in: [.userDomainMask, .localDomainMask]).map { $0.appendingPathComponent("Fonts") }
        let files = folders.flatMap { (try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)) ?? [] }
        let named = files.flatMap { file in
            (CTFontManagerCreateFontDescriptorsFromURL(file as CFURL) as? [CTFontDescriptor] ?? []).compactMap { descriptor -> (String, URL)? in
                guard let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String, wanted.contains(name) else { return nil }
                return (name, file)
            }
        }
        return Dictionary(named, uniquingKeysWith: { first, _ in first })
    }()

    private static func fileURL(_ font: CTFont) -> URL? {
        CTFontCopyAttribute(font, kCTFontURLAttribute) as? URL
    }

    /// Family name and file of each user-installed font CoreText picks to draw `scalars`, sorted by family.
    private static func fallbackFonts(for scalars: Set<Unicode.Scalar>) -> [(family: String, file: URL)] {
        guard !scalars.isEmpty else { return [] }
        var sample = String.UnicodeScalarView()
        sample.append(contentsOf: scalars)
        let line = CTLineCreateWithAttributedString(
            NSAttributedString(string: String(sample), attributes: [NSAttributedString.Key(kCTFontAttributeName as String): baseFont]))
        let fonts = (CTLineGetGlyphRuns(line) as? [CTRun] ?? []).compactMap { run -> (String, URL)? in
            let font = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName as String] as! CTFont
            guard let file = fileURL(font), !file.path.hasPrefix(systemFontsPrefix) else { return nil }
            return (CTFontCopyFamilyName(font) as String, file)
        }
        return Dictionary(fonts, uniquingKeysWith: { first, _ in first }).map { ($0.key, $0.value) }.sorted { $0.family < $1.family }
    }

    /// The sequence fonts `scalars` need and that are installed
    private static func neededSequenceFonts(for scalars: Set<Unicode.Scalar>) -> [(font: SequenceFont, file: URL)] {
        sequenceFonts.compactMap { font in
            guard scalars.contains(where: { scalar in font.triggers.contains { $0.contains(scalar.value) } }),
                  let file = installedFontFiles[font.postScriptName] else { return nil }
            return (font, file)
        }
    }

    private static func cssString(_ text: String) -> String {
        "\"\(text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\""
    }

    private static func fontFace(_ family: String, _ file: URL, unicodeRange: String? = nil, sizeAdjust: String? = nil) -> String {
        let source = "\(scheme)://\(file.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? file.path)"
        let descriptors = [unicodeRange.map { "unicode-range: \($0);" }, sizeAdjust.map { "size-adjust: \($0);" }].compactMap { $0 }
        return "@font-face { font-family: \(cssString(family)); src: url(\"\(source)\"); \(descriptors.joined(separator: " ")) }"
    }

    /// `<style>` with the `@font-face` rules and the `--sequence-fonts` / `--fallback-fonts` variables that style.css puts
    /// before and after its font stacks; empty when not needed.
    static func styleElement(for text: String) -> String {
        let scalars = distinctScalars(text)
        let fallback = fallbackFonts(for: scalars)
        let sequence = neededSequenceFonts(for: scalars)
        guard !fallback.isEmpty || !sequence.isEmpty else { return "" }
        let faces = sequence.map { fontFace($0.font.alias, $0.file, unicodeRange: $0.font.unicodeRange, sizeAdjust: $0.font.sizeAdjust) } + fallback.map { fontFace($0.family, $0.file) }
        var variables: [String] = []
        if !sequence.isEmpty { variables.append("--sequence-fonts: \(sequence.map { cssString($0.font.alias) }.joined(separator: ", ")),;") }
        if !fallback.isEmpty { variables.append("--fallback-fonts: \(fallback.map { cssString($0.family) }.joined(separator: ", "));") }
        return "<style>\(faces.joined(separator: "\n"))\n:root { \(variables.joined(separator: " ")) }</style>\n"
    }

    /// The font file a `userfont:` URL names
    static func file(for url: URL) -> URL? {
        url.scheme == scheme ? URL(fileURLWithPath: url.path) : nil
    }
}

/// Serves the font files the page's `userfont:` URLs name; register it on the web view's configuration.
public final class UserFontSchemeHandler: NSObject, WKURLSchemeHandler {
    public static let scheme = UserFontFallback.scheme

    public func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
        guard let url = task.request.url, let file = UserFontFallback.file(for: url), let data = try? Data(contentsOf: file) else {
            NSLog("UserFontSchemeHandler: cannot read %@", task.request.url?.absoluteString ?? "?")
            return task.didFailWithError(URLError(.fileDoesNotExist))
        }
        let headers = ["Content-Type": "application/octet-stream", "Access-Control-Allow-Origin": "*"]
        task.didReceive(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)!)
        task.didReceive(data)
        task.didFinish()
    }

    public func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {}
}
