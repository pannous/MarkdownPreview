import CoreText
import Foundation

/// WebKit's per-character font fallback only considers system fonts, so characters covered solely by a user-installed
/// font (private-use scripts, rare CJK planes) render as boxes unless that font is named in CSS.
/// CoreText's fallback does search every installed font (backed by the system's own coverage index), so lay the
/// document's distinct characters out once and collect the fonts it picked from outside /System.
enum UserFontFallback {
    private static let baseFont = CTFontCreateUIFontForLanguage(.system, 16, nil)!
    private static let systemFontsPrefix = "/System/"

    /// CSS family names of the user-installed fonts needed to draw `text`, sorted.
    static func families(for text: String) -> [String] {
        let distinctScalars = Set(text.unicodeScalars.lazy.filter { !$0.isASCII })
        guard !distinctScalars.isEmpty else { return [] }
        var sample = String.UnicodeScalarView()
        sample.append(contentsOf: distinctScalars)
        let line = CTLineCreateWithAttributedString(
            NSAttributedString(string: String(sample), attributes: [NSAttributedString.Key(kCTFontAttributeName as String): baseFont]))
        let families = (CTLineGetGlyphRuns(line) as? [CTRun] ?? []).compactMap { run -> String? in
            let font = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName as String] as! CTFont
            guard let url = CTFontCopyAttribute(font, kCTFontURLAttribute) as? URL, !url.path.hasPrefix(systemFontsPrefix) else { return nil }
            return CTFontCopyFamilyName(font) as String
        }
        return Set(families).sorted()
    }

    /// `<style>` setting the `--fallback-fonts` variable that style.css appends to its font stacks; empty when not needed.
    static func styleElement(for text: String) -> String {
        let families = families(for: text)
        guard !families.isEmpty else { return "" }
        let list = families.map { "\"\($0.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\"" }
        return "<style>:root { --fallback-fonts: \(list.joined(separator: ", ")); }</style>\n"
    }
}
