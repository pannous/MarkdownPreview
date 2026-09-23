import Foundation

/// Calls `onChange` on the main queue whenever the file is written or replaced (atomic saves rename a new file into place).
final class FileWatcher {
    private static let reopenDelay: TimeInterval = 0.1
    private static let maxReopenAttempts = 20

    private let url: URL
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?

    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
        watch()
    }

    deinit { source?.cancel() }

    @discardableResult
    private func watch() -> Bool {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return false }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.write, .extend, .delete, .rename], queue: .main)
        source.setEventHandler { [weak self, unowned source] in
            guard let self else { return }
            if source.data.isDisjoint(with: [.delete, .rename]) { return self.onChange() }
            source.cancel()
            self.rewatch(attempt: 1)
        }
        source.setCancelHandler { close(descriptor) }
        source.resume()
        self.source = source
        return true
    }

    private func rewatch(attempt: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.reopenDelay) { [weak self] in
            guard let self else { return }
            if self.watch() { return self.onChange() }
            if attempt < Self.maxReopenAttempts { self.rewatch(attempt: attempt + 1) }
        }
    }
}
