// Which font CoreText (and so Sublime, TextEdit…) picks for each character, its size in em and the font's file.
// Usage: glyph_fonts <text>
import CoreText
import Foundation
let base = CTFontCreateUIFontForLanguage(.system, 100, nil)!
for scalar in CommandLine.arguments[1].unicodeScalars where !scalar.isASCII && scalar != " " {
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: String(scalar), attributes: [NSAttributedString.Key(kCTFontAttributeName as String): base]))
    for run in CTLineGetGlyphRuns(line) as! [CTRun] {
        let font = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName as String] as! CTFont
        let bounds = CTLineGetImageBounds(line, nil)
        let file = (CTFontCopyAttribute(font, kCTFontURLAttribute) as? URL)?.lastPathComponent ?? "?"
        print(String(format: "U+%04X  %@  ink %.2f×%.2f em  ascent %.2f descent %.2f upm %d  %@", scalar.value, CTFontCopyPostScriptName(font) as String,
                     bounds.width / 100, bounds.height / 100, CTFontGetAscent(font) / 100, CTFontGetDescent(font) / 100, CTFontGetUnitsPerEm(font), file))
    }
}
