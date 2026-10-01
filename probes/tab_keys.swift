// Headless check of App/TabNavigation.swift: synthetic key and mouse events → previous / next tab (no windows).
// Build: see probes/test.sh
import AppKit

@main
enum TabKeysProbe {
    static var failures = 0

    static func key(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: 0, windowNumber: 0, context: nil,
                         characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: keyCode)!
    }

    static func mouse(_ button: Int) -> NSEvent {
        NSEvent(cgEvent: CGEvent(mouseEventSource: nil, mouseType: .otherMouseDown, mouseCursorPosition: .zero,
                                 mouseButton: CGMouseButton(rawValue: UInt32(button))!)!)!
    }

    static func expect(_ description: String, _ event: NSEvent, _ expected: TabNavigation.Step?) {
        let ok = TabNavigation.step(for: event) == expected
        print(ok ? "ok  " : "FAIL", description)
        if !ok { failures += 1 }
    }

    static func main() {
        let arrow: NSEvent.ModifierFlags = [.numericPad, .function]  // arrow keys carry these
        expect("⌘← previous tab", key(123, arrow.union(.command)), .previous)
        expect("⌘→ next tab", key(124, arrow.union(.command)), .next)
        expect("← alone scrolls", key(123, arrow), nil)
        expect("⌥⌘← is not tab navigation", key(123, arrow.union([.command, .option])), nil)
        expect("⌘↑ is not tab navigation", key(126, arrow.union(.command)), nil)
        expect("mouse back button previous tab", mouse(3), .previous)
        expect("mouse forward button next tab", mouse(4), .next)
        expect("middle button ignored", mouse(2), nil)
        exit(Int32(failures))
    }
}
