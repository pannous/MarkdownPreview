import AppKit
import os

private let leftArrowKeyCode: UInt16 = 123
private let rightArrowKeyCode: UInt16 = 124
private let backMouseButton = 3
private let forwardMouseButton = 4
/// ⌘[ / ⌘]: the Mac's back / forward, also what SteerMouse sends for its Back / Forward buttons
/// `log stream --predicate 'subsystem == "com.pannous.MarkdownPreview"'` shows which form a mouse utility sends
private let log = Logger(subsystem: "com.pannous.MarkdownPreview", category: "tabs")
private let backKeys: Set<String> = ["["], forwardKeys: Set<String> = ["]"]

/// The browser's back and forward select the previous and next tab, in every form they arrive: ← / →, ⌘← / ⌘→, ⌘[ / ⌘],
/// the mouse's back / forward buttons and swipes (trackpads, mouse utilities like SteerMouse).
/// With a single tab the event passes through untouched.
enum TabNavigation {
    enum Step { case previous, next }

    static func step(for event: NSEvent) -> Step? {
        switch event.type {
        case .keyDown:
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.numericPad, .function])
            guard modifiers.isEmpty || modifiers == .command else { return nil }
            let key = event.charactersIgnoringModifiers ?? ""
            if modifiers == .command && (backKeys.contains(key) || forwardKeys.contains(key)) { log.info("command \(key)") }
            if modifiers == .command && backKeys.contains(key) { return .previous }
            if modifiers == .command && forwardKeys.contains(key) { return .next }
            return [leftArrowKeyCode: .previous, rightArrowKeyCode: .next][event.keyCode]
        case .otherMouseDown:
            log.info("mouse button \(event.buttonNumber)")
            return [backMouseButton: .previous, forwardMouseButton: .next][event.buttonNumber]
        case .swipe:
            log.info("swipe deltaX \(event.deltaX)")
            return step(forSwipe: event.deltaX)
        default:
            return nil
        }
    }

    /// A swipe to the right (positive deltaX) goes back, as in Safari
    static func step(forSwipe deltaX: CGFloat) -> Step? { deltaX > 0 ? .previous : deltaX < 0 ? .next : nil }

    static func installShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .otherMouseDown, .swipe]) { event in
            guard let step = step(for: event), let window = NSApp.keyWindow, (window.tabbedWindows?.count ?? 0) > 1 else { return event }
            step == .previous ? window.selectPreviousTab(nil) : window.selectNextTab(nil)
            return nil
        }
    }
}
