import AppKit

private let leftArrowKeyCode: UInt16 = 123
private let rightArrowKeyCode: UInt16 = 124
private let backMouseButton = 3
private let forwardMouseButton = 4

/// The browser's back and forward select the previous and next tab: ⌘← / ⌘→ and the mouse's back / forward buttons.
/// With a single tab the event passes through untouched.
enum TabNavigation {
    enum Step { case previous, next }

    static func step(for event: NSEvent) -> Step? {
        switch event.type {
        case .keyDown:
            guard event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.numericPad, .function]) == .command else { return nil }
            return [leftArrowKeyCode: .previous, rightArrowKeyCode: .next][event.keyCode]
        case .otherMouseDown:
            return [backMouseButton: .previous, forwardMouseButton: .next][event.buttonNumber]
        default:
            return nil
        }
    }

    static func installShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .otherMouseDown]) { event in
            guard let step = step(for: event), let window = NSApp.keyWindow, (window.tabbedWindows?.count ?? 0) > 1 else { return event }
            step == .previous ? window.selectPreviousTab(nil) : window.selectNextTab(nil)
            return nil
        }
    }
}
