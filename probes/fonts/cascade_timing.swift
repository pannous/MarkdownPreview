// Times CoreText's fallback lookup (CTFontCreateForString) for rare codepoints, cold and warm.
import CoreText
import Foundation
let base = CTFontCreateUIFontForLanguage(.system, 16, nil)!
func lookup(_ value: UInt32) -> String {
    let text = String(Unicode.Scalar(value)!) as CFString
    let font = CTFontCreateForString(base, text, CFRange(location: 0, length: CFStringGetLength(text)))
    let url = CTFontCopyAttribute(font, kCTFontURLAttribute) as? URL
    return "\(CTFontCopyFamilyName(font)) \(url?.path ?? "-")"
}
for value: UInt32 in [0xF50D7, 0xF5021, 0x3F27C, 0x3F890, 0xE000, 0x4E2D, 0x10FFFD] {
    let start = Date()
    let result = lookup(value)
    print(String(format: "U+%X %.1f ms %@", value, Date().timeIntervalSince(start) * 1000, result))
}
