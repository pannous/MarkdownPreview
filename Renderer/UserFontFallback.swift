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
    /// NewGardinerOmni fits a whole quadrat into one em, so a stacked group looks cramped next to Latin text; other
    /// hieroglyph fonts (Aegyptus for extended signs) draw signs as tall, so they get the same scale
    private static let hieroglyphScale = "155%"
    private static let baseFont = CTFontCreateUIFontForLanguage(.system, 16, nil)!
    private static let systemFontsPrefix = "/System/"
    /// A1, the first sign of the standard block: a font covering it draws hieroglyphs, extended ones (Aegyptus' private use) too
    private static let hieroglyphProbe: [UniChar] = Array("\u{13000}".utf16)
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

    /// Loaded once per process; styleElement runs under the renderer's lock
    private static var cache = FontCache.load()

    /// PostScript name → file of the sequence fonts in the font folders: CoreText no longer finds user-installed fonts
    /// by name (macOS 27), though its fallback still uses them
    private static func scanFontFolders() -> [String: String] {
        let wanted = Set(sequenceFonts.map(\.postScriptName))
        let files = FontCache.fontFolders.flatMap { (try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)) ?? [] }
        let named = files.flatMap { file in
            (CTFontManagerCreateFontDescriptorsFromURL(file as CFURL) as? [CTFontDescriptor] ?? []).compactMap { descriptor -> (String, String)? in
                guard let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String, wanted.contains(name) else { return nil }
                return (name, file.path)
            }
        }
        return Dictionary(named, uniquingKeysWith: { first, _ in first })
    }

    private static func installedFontFile(_ postScriptName: String) -> URL? {
        if cache.filesByPostScriptName == nil { cache.filesByPostScriptName = scanFontFolders() }
        return cache.filesByPostScriptName?[postScriptName].map(URL.init(fileURLWithPath:))
    }

    private static func fileURL(_ font: CTFont) -> URL? {
        CTFontCopyAttribute(font, kCTFontURLAttribute) as? URL
    }

    /// The font CoreText picks for each of `scalars`, nil for system fonts: one line with all of them, so its fallback
    /// search runs once
    private static func searchFallbackFonts(for scalars: [Unicode.Scalar]) -> [UInt32: FontCache.Fallback] {
        var sample = String.UnicodeScalarView()
        sample.append(contentsOf: scalars)
        let text = String(sample) as NSString
        let line = CTLineCreateWithAttributedString(
            NSAttributedString(string: text as String, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): baseFont]))
        let pairs = (CTLineGetGlyphRuns(line) as? [CTRun] ?? []).flatMap { run -> [(UInt32, FontCache.Fallback)] in
            let font = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName as String] as! CTFont
            let userFont = fileURL(font).flatMap { $0.path.hasPrefix(systemFontsPrefix) ? nil : FontCache.Font(
                family: CTFontCopyFamilyName(font) as String, path: $0.path, drawsHieroglyphs: drawsHieroglyphs(font)) }
            let range = CTRunGetStringRange(run)
            return text.substring(with: NSRange(location: range.location, length: range.length)).unicodeScalars.map { ($0.value, FontCache.Fallback(font: userFont)) }
        }
        return Dictionary(pairs, uniquingKeysWith: { first, _ in first })
    }

    private static func drawsHieroglyphs(_ font: CTFont) -> Bool {
        var glyphs = [CGGlyph](repeating: 0, count: hieroglyphProbe.count)
        return CTFontGetGlyphsForCharacters(font, hieroglyphProbe, &glyphs, hieroglyphProbe.count)
    }

    /// Each user-installed font that draws some of `scalars`, sorted by family.
    private static func fallbackFonts(for scalars: Set<Unicode.Scalar>) -> [FontCache.Font] {
        let unknown = scalars.filter { cache.fallbackByScalar[$0.value] == nil }
        if !unknown.isEmpty { cache.fallbackByScalar.merge(searchFallbackFonts(for: Array(unknown))) { _, found in found } }
        let fonts = scalars.compactMap { cache.fallbackByScalar[$0.value]?.font }
        return Dictionary(fonts.map { ($0.family, $0) }, uniquingKeysWith: { first, _ in first }).values.sorted { $0.family < $1.family }
    }

    /// The sequence fonts `scalars` need and that are installed
    private static func neededSequenceFonts(for scalars: Set<Unicode.Scalar>) -> [(font: SequenceFont, file: URL)] {
        sequenceFonts.compactMap { font in
            guard scalars.contains(where: { scalar in font.triggers.contains { $0.contains(scalar.value) } }),
                  let file = installedFontFile(font.postScriptName) else { return nil }
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
        let cacheBefore = (cache.fallbackByScalar.count, cache.filesByPostScriptName == nil)
        let fallback = fallbackFonts(for: scalars)
        let sequence = neededSequenceFonts(for: scalars)
        if (cache.fallbackByScalar.count, cache.filesByPostScriptName == nil) != cacheBefore { cache.save() }
        guard !fallback.isEmpty || !sequence.isEmpty else { return "" }
        let faces = sequence.map { fontFace($0.font.alias, $0.file, unicodeRange: $0.font.unicodeRange, sizeAdjust: $0.font.sizeAdjust) } + fallback.map { fontFace($0.family, URL(fileURLWithPath: $0.path), sizeAdjust: $0.drawsHieroglyphs ? hieroglyphScale : nil) }
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
