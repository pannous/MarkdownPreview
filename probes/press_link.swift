// Presses a link in a MarkdownPreview window by accessibility (AXPress): no mouse movement, no focus change.
// Usage: xcrun swift probes/press_link.swift <window title> <link text>
import AppKit
import ApplicationServices

func attribute(_ element: AXUIElement, _ name: String) -> AnyObject? {
    var value: AnyObject?
    return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
}

func text(_ element: AXUIElement) -> String {
    ["AXTitle", "AXDescription", "AXValue"].compactMap { attribute(element, $0) as? String }.joined(separator: " ")
}

func find(_ element: AXUIElement, role: String, text wanted: String, depth: Int = 0) -> AXUIElement? {
    if attribute(element, "AXRole") as? String == role && text(element).split(separator: " ").first.map(String.init) == wanted { return element }
    guard depth < 40 else { return nil }
    for child in attribute(element, "AXChildren") as? [AXUIElement] ?? [] {
        if let found = find(child, role: role, text: wanted, depth: depth + 1) { return found }
    }
    return nil
}

let (windowTitle, linkText) = (CommandLine.arguments[1], CommandLine.arguments[2])
print("trusted", AXIsProcessTrusted())
guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.pannous.MarkdownPreview").first else { exit(1) }
let root = AXUIElementCreateApplication(app.processIdentifier)
let windows = attribute(root, "AXWindows") as? [AXUIElement] ?? []
print("windows", windows.map { attribute($0, "AXTitle") as? String ?? "?" })
guard let window = windows.first(where: { attribute($0, "AXTitle") as? String == windowTitle }),
      let link = find(window, role: "AXLink", text: linkText) else { print("link not found"); exit(1) }
print("press", AXUIElementPerformAction(link, "AXPress" as CFString).rawValue)
