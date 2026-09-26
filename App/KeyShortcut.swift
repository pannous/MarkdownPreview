import AppKit

extension NSEvent {
    /// The key pressed together with exactly ⌘ or exactly ⌃ (Shift allowed), nil for any other combination.
    var commandOrControlKey: String? {
        let modifiers = modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.shift, .numericPad, .function])
        guard modifiers == .command || modifiers == .control else { return nil }
        return charactersIgnoringModifiers
    }
}
