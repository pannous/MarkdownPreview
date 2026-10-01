// Headless check of App/TabNavigation.swift: synthetic key and mouse events → previous / next tab (no windows).
// Build: see probes/test.sh
import AppKit

@main
enum TabKeysProbe {
    static var failures = 0

    static func key(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags, _ characters: String = "") -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: 0, windowNumber: 0, context: nil,
                         characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: keyCode)!
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
        expect("← previous tab", key(123, arrow), .previous)
        expect("→ next tab", key(124, arrow), .next)
        expect("⇧← selects text, not tabs", key(123, arrow.union(.shift)), nil)
        expect("⌥⌘← is not tab navigation", key(123, arrow.union([.command, .option])), nil)
        expect("⌘↑ is not tab navigation", key(126, arrow.union(.command)), nil)
        expect("⌘[ previous tab (SteerMouse Back)", key(33, .command, "["), .previous)
        expect("⌘] next tab (SteerMouse Forward)", key(30, .command, "]"), .next)
        expect("⌃[ folds, not tabs", key(33, .control, "["), nil)
        expect("[ alone types", key(33, [], "["), nil)
        expect("mouse back button previous tab", mouse(3), .previous)
        expect("mouse forward button next tab", mouse(4), .next)
        expect("middle button ignored", mouse(2), nil)
        let swipes = TabNavigation.step(forSwipe: 1) == .previous && TabNavigation.step(forSwipe: -1) == .next && TabNavigation.step(forSwipe: 0) == nil
        print(swipes ? "ok  " : "FAIL", "swipe right previous tab, left next tab")
        if !swipes { failures += 1 }
        exit(Int32(failures))
    }
}
