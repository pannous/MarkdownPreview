// Ink height and width (in em) of hieroglyphs and stacked groups as NewGardinerOmni shapes them. Usage: group_ink <text>...
import CoreText
import Foundation
let file = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Fonts/NewGardinerOmni2d4.ttf") as CFURL
let font = CTFontCreateWithFontDescriptor((CTFontManagerCreateFontDescriptorsFromURL(file) as! [CTFontDescriptor])[0], 100, nil)
for text in CommandLine.arguments.dropFirst() {
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]))
    let ink = CTLineGetImageBounds(line, nil)
    print(String(format: "%@  ink %.2f × %.2f em (bottom %.2f)  advance %.2f em", text, ink.width / 100, ink.height / 100, ink.minY / 100, CTLineGetTypographicBounds(line, nil, nil, nil) / 100))
}
