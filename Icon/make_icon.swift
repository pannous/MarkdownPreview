// Draws the app icon (indigo squircle, white page with rendered text lines and the Markdown "M↓" mark)
// and writes App/Assets.xcassets/AppIcon.appiconset. Run: xcrun swift Icon/make_icon.swift
import AppKit

let canvas: CGFloat = 1024
let iconSetPath = "App/Assets.xcassets/AppIcon.appiconset"
let pointSizes: [CGFloat] = [16, 32, 128, 256, 512]
let backgroundTop = NSColor(srgbRed: 0.40, green: 0.47, blue: 1.00, alpha: 1)
let backgroundBottom = NSColor(srgbRed: 0.17, green: 0.12, blue: 0.55, alpha: 1)
let ink = NSColor(srgbRed: 0.22, green: 0.20, blue: 0.62, alpha: 1)
let textLine = NSColor(srgbRed: 0.80, green: 0.82, blue: 0.90, alpha: 1)

/// Rect given in top-left based icon coordinates (like design tools), converted to AppKit's bottom-left origin.
func box(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
    NSRect(x: x, y: canvas - y - height, width: width, height: height)
}
func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x, y: canvas - y) }

func withShadow(blur: CGFloat, offset: CGFloat, alpha: CGFloat, _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = NSSize(width: 0, height: -offset)
    shadow.shadowColor = NSColor.black.withAlphaComponent(alpha)
    shadow.set()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

func drawBackground() {
    let squircle = NSBezierPath(roundedRect: box(100, 100, 824, 824), xRadius: 185, yRadius: 185)
    withShadow(blur: 28, offset: 12, alpha: 0.35) { backgroundBottom.setFill(); squircle.fill() }
    NSGradient(starting: backgroundTop, ending: backgroundBottom)!.draw(in: squircle, angle: -90)
    NSGradient(starting: NSColor.white.withAlphaComponent(0.18), ending: .clear)!.draw(in: squircle, angle: -90)
}

func drawPage() {
    let (left, top, width, height, fold, radius): (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat) = (262, 196, 500, 632, 118, 34)
    let page = NSBezierPath()
    page.move(to: point(left + radius, top))
    page.line(to: point(left + width - fold, top))
    page.line(to: point(left + width, top + fold))
    page.appendArc(from: point(left + width, top + height), to: point(left, top + height), radius: radius)
    page.appendArc(from: point(left, top + height), to: point(left, top), radius: radius)
    page.appendArc(from: point(left, top), to: point(left + width, top), radius: radius)
    page.close()
    withShadow(blur: 36, offset: 18, alpha: 0.35) { NSColor.white.setFill(); page.fill() }

    let corner = NSBezierPath()
    corner.move(to: point(left + width - fold, top))
    corner.line(to: point(left + width - fold, top + fold - 22))
    corner.appendArc(from: point(left + width - fold, top + fold), to: point(left + width, top + fold), radius: 22)
    corner.line(to: point(left + width, top + fold))
    corner.close()
    NSColor(srgbRed: 0.84, green: 0.86, blue: 0.96, alpha: 1).setFill()
    corner.fill()

    let lines: [(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: NSColor)] = [
        (322, 262, 230, 34, ink), (322, 336, 320, 20, textLine), (322, 378, 360, 20, textLine), (322, 420, 250, 20, textLine),
    ]
    for line in lines {
        line.color.setFill()
        NSBezierPath(roundedRect: box(line.x, line.y, line.width, line.height), xRadius: line.height / 2, yRadius: line.height / 2).fill()
    }
}

/// The Markdown mark: rounded frame containing "M" and a down arrow.
func drawMarkdownMark() {
    let frame = NSBezierPath(roundedRect: box(312, 500, 400, 246), xRadius: 34, yRadius: 34)
    frame.lineWidth = 26
    ink.setStroke()
    frame.stroke()

    let letter = NSBezierPath()
    letter.move(to: point(372, 680))
    letter.line(to: point(372, 566))
    letter.line(to: point(432, 632))
    letter.line(to: point(492, 566))
    letter.line(to: point(492, 680))
    letter.lineWidth = 40
    letter.lineJoinStyle = .round
    letter.lineCapStyle = .round
    letter.stroke()

    let stem = NSBezierPath(roundedRect: box(583, 562, 42, 70), xRadius: 8, yRadius: 8)
    ink.setFill()
    stem.fill()
    let arrowHead = NSBezierPath()
    arrowHead.move(to: point(548, 620))
    arrowHead.line(to: point(660, 620))
    arrowHead.line(to: point(604, 690))
    arrowHead.close()
    arrowHead.lineJoinStyle = .round
    arrowHead.lineWidth = 14
    arrowHead.fill()
    arrowHead.stroke()
}

func renderPNG(pixels: Int) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
                                  hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    bitmap.size = NSSize(width: canvas, height: canvas)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high
    drawBackground()
    drawPage()
    drawMarkdownMark()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

try FileManager.default.createDirectory(atPath: iconSetPath, withIntermediateDirectories: true)
var images: [[String: String]] = []
for size in pointSizes {
    for scale in [1, 2] {
        let name = "icon_\(Int(size))x\(Int(size))\(scale == 2 ? "@2x" : "").png"
        try renderPNG(pixels: Int(size) * scale).write(to: URL(fileURLWithPath: "\(iconSetPath)/\(name)"))
        images.append(["idiom": "mac", "size": "\(Int(size))x\(Int(size))", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: URL(fileURLWithPath: "\(iconSetPath)/Contents.json"))
try #"{"info":{"author":"xcode","version":1}}"#.write(toFile: "App/Assets.xcassets/Contents.json", atomically: true, encoding: .utf8)
print("wrote \(iconSetPath)")
