import AppKit
import SwiftUI

/// Section folding in the key window: ⌘[ or ⌃[ collapses the deepest open heading level, ⌘] or ⌃] expands the
/// shallowest collapsed one (Shift optional, so { and } work too). The page side lives in folding.js.
enum Folding {
    static let notification = Notification.Name("MarkdownPreviewFolding")
    private static let collapseKeys: Set<String> = ["[", "{"]
    private static let expandKeys: Set<String> = ["]", "}"]

    /// Raw value is the folding.js call that performs it.
    enum Action: String {
        case collapse = "foldDeepest()"
        case expand = "unfoldShallowest()"
    }

    static func perform(_ action: Action) { NotificationCenter.default.post(name: notification, object: action) }

    static func action(for event: NSEvent) -> Action? {
        guard let key = event.commandOrControlKey else { return nil }
        if collapseKeys.contains(key) { return .collapse }
        if expandKeys.contains(key) { return .expand }
        return nil
    }

    static func installKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let action = action(for: event) else { return event }
            perform(action)
            return nil
        }
    }
}

struct FoldingCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button("Collapse Sections") { Folding.perform(.collapse) }.keyboardShortcut("[")
            Button("Expand Sections") { Folding.perform(.expand) }.keyboardShortcut("]")
        }
    }
}
