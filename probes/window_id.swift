// Prints the CGWindowIDs of the named process's on-screen document windows, largest first (for `screencapture -l`).
import CoreGraphics
let owner = CommandLine.arguments[1]
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
let area = { (window: [String: Any]) -> Double in
    let bounds = window[kCGWindowBounds as String] as? [String: Double] ?? [:]
    return (bounds["Width"] ?? 0) * (bounds["Height"] ?? 0)
}
let matches = windows
    .filter { ($0[kCGWindowOwnerName as String] as? String) == owner && ($0[kCGWindowLayer as String] as? Int) == 0 && area($0) > 10_000 }
    .sorted { area($0) > area($1) }
if matches.isEmpty { exit(1) }
for window in matches { print(window[kCGWindowNumber as String] as! Int) }
