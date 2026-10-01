import AppKit

private let tabbingModeKey = "AppleWindowTabbingMode"
private let ignoreSavedWindowsKey = "ApplePersistenceIgnoreState"

/// Every document opens as a tab of the frontmost window, whatever the system setting says.
enum Tabs {
    static func preferAlways() { UserDefaults.standard.set("always", forKey: tabbingModeKey) }
}

/// One running copy only: a second launch (another build of the app, `open -n`) hands its files to the running
/// instance and exits before it restores windows or saves its own window state over the running one's.
final class SingleInstance: NSObject {
    private static let shared = SingleInstance()
    private var runningInstance: NSRunningApplication?

    /// Call from applicationWillFinishLaunching, before the open events arrive
    static func handOverIfAlreadyRunning() {
        let current = NSRunningApplication.current
        guard let other = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
            .first(where: { $0 != current && !$0.isTerminated }) else { return }
        shared.runningInstance = other
        UserDefaults.standard.register(defaults: [ignoreSavedWindowsKey: true])
        let events = NSAppleEventManager.shared()
        let coreEvents = AEEventClass(kCoreEventClass)
        events.setEventHandler(shared, andSelector: #selector(openDocuments(_:reply:)), forEventClass: coreEvents, andEventID: AEEventID(kAEOpenDocuments))
        events.setEventHandler(shared, andSelector: #selector(openApplication(_:reply:)), forEventClass: coreEvents, andEventID: AEEventID(kAEOpenApplication))
        events.setEventHandler(shared, andSelector: #selector(openApplication(_:reply:)), forEventClass: coreEvents, andEventID: AEEventID(kAEReopenApplication))
    }

    @objc private func openDocuments(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        guard let list = event.paramDescriptor(forKeyword: keyDirectObject), let runningInstance, let applicationURL = runningInstance.bundleURL else { exit(0) }
        let files = (1...max(list.numberOfItems, 1)).compactMap { list.atIndex($0)?.fileURLValue ?? list.fileURLValue }
        NSLog("SingleInstance: handing %d file(s) to the running instance (pid %d)", files.count, runningInstance.processIdentifier)
        NSWorkspace.shared.open(files, withApplicationAt: applicationURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in exit(0) }
    }

    @objc private func openApplication(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        runningInstance?.activate()
        exit(0)
    }
}

private extension NSAppleEventDescriptor {
    var fileURLValue: URL? { coerce(toDescriptorType: typeFileURL).flatMap { URL(dataRepresentation: $0.data, relativeTo: nil) } }
}
