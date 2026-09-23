import AppKit
import SwiftUI

/// Page zoom shared by all windows and persisted. ⌘ or ⌃ with =/+ zooms in, -/_ zooms out, 0 resets (Shift optional).
enum Zoom {
    static let defaultsKey = "pageZoom"
    static let step = 0.1
    static let range = 0.5...3.0
    private static let zoomInKeys: Set<String> = ["=", "+"]
    private static let zoomOutKeys: Set<String> = ["-", "_"]
    private static let resetKeys: Set<String> = ["0"]
    private static let triggerModifiers: NSEvent.ModifierFlags = [.command, .control]

    enum Action { case zoomIn, zoomOut, reset }

    static func perform(_ action: Action) {
        let current = UserDefaults.standard.object(forKey: defaultsKey) as? Double ?? 1
        let target: Double = switch action {
        case .zoomIn: current + step
        case .zoomOut: current - step
        case .reset: 1
        }
        UserDefaults.standard.set((min(max(target, range.lowerBound), range.upperBound) * 10).rounded() / 10, forKey: defaultsKey)
    }

    static func action(for event: NSEvent) -> Action? {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.shift, .numericPad, .function])
        guard modifiers == .command || modifiers == .control, let key = event.charactersIgnoringModifiers else { return nil }
        if zoomInKeys.contains(key) { return .zoomIn }
        if zoomOutKeys.contains(key) { return .zoomOut }
        if resetKeys.contains(key) { return .reset }
        return nil
    }

    /// A local monitor sees every variant (⌃, unshifted =) that menu key equivalents alone would miss.
    static func installKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let action = action(for: event) else { return event }
            perform(action)
            return nil
        }
    }
}

/// View menu entries; the shortcuts shown here are handled by `Zoom.installKeyboardShortcuts`.
struct ZoomCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button("Zoom In") { Zoom.perform(.zoomIn) }.keyboardShortcut("+")
            Button("Zoom Out") { Zoom.perform(.zoomOut) }.keyboardShortcut("-")
            Button("Actual Size") { Zoom.perform(.reset) }.keyboardShortcut("0")
        }
    }
}
