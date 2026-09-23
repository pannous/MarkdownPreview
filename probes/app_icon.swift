// Writes the icon macOS currently shows for an app bundle (what Finder, Dock and the app switcher use) to a PNG.
import AppKit
let icon = NSWorkspace.shared.icon(forFile: CommandLine.arguments[1])
icon.size = NSSize(width: 256, height: 256)
let bitmap = NSBitmapImageRep(data: icon.tiffRepresentation!)!
try! bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
