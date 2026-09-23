import CoreText
import Foundation

let codepoints: [UInt32] = CommandLine.arguments.dropFirst().compactMap { UInt32($0.replacingOccurrences(of: "U+", with: ""), radix: 16) }
let descriptors = CTFontManagerCopyAvailableFontFamilyNames() as! [String]
for family in descriptors {
    let font = CTFontCreateWithName(family as CFString, 12, nil)
    let charset = CTFontCopyCharacterSet(font) as CharacterSet
    let covered = codepoints.filter { charset.contains(Unicode.Scalar($0)!) }
    if !covered.isEmpty {
        let url = CTFontCopyAttribute(font, kCTFontURLAttribute) as? URL
        print(family, covered.map { String($0, radix: 16) }, url?.path ?? "")
    }
}
