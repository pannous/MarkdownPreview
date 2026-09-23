// Headless check of the zoom shortcuts: feeds synthetic key events to App/Zoom.swift (no windows, nothing posted).
// Build: xcrun swiftc -parse-as-library App/Zoom.swift probes/zoom_keys.swift -o probes/zoom_keys
import AppKit

@main
enum ZoomKeysProbe {
    static var failures = 0

    static func key(_ characters: String, _ modifiers: NSEvent.ModifierFlags) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: 0, windowNumber: 0, context: nil,
                         characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: 0)!
    }

    static func expect(_ description: String, _ condition: Bool) {
        print(condition ? "ok  " : "FAIL", description)
        if !condition { failures += 1 }
    }

    static var zoom: Double { UserDefaults.standard.double(forKey: Zoom.defaultsKey) }

    static func main() {
        let cases: [(String, NSEvent.ModifierFlags, Zoom.Action?)] = [
            ("=", .command, .zoomIn), ("+", [.command, .shift], .zoomIn), ("=", .control, .zoomIn), ("+", [.control, .shift], .zoomIn),
            ("-", .command, .zoomOut), ("_", [.command, .shift], .zoomOut), ("-", .control, .zoomOut), ("_", [.control, .shift], .zoomOut),
            ("0", .command, .reset), ("0", .control, .reset),
            ("=", [], nil), ("=", [.command, .control], nil), ("-", .option, nil), ("e", .command, nil),
        ]
        for (characters, modifiers, expected) in cases {
            expect("\(modifiers.rawValue) '\(characters)' → \(expected.map { "\($0)" } ?? "ignored")", Zoom.action(for: key(characters, modifiers)) == expected)
        }

        Zoom.perform(.reset)
        expect("reset → 1.0", zoom == 1.0)
        Zoom.perform(.zoomIn); Zoom.perform(.zoomIn)
        expect("two steps in → 1.2", zoom == 1.2)
        for _ in 0..<50 { Zoom.perform(.zoomOut) }
        expect("clamped at 0.5", zoom == 0.5)
        for _ in 0..<50 { Zoom.perform(.zoomIn) }
        expect("clamped at 3.0", zoom == 3.0)
        Zoom.perform(.reset)
        UserDefaults.standard.removeObject(forKey: Zoom.defaultsKey)
        print("\(failures) failure(s)")
        exit(Int32(failures))
    }
}
