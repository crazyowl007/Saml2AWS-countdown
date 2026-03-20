import Foundation

final class CredentialsFileWatcher {
    private let filePath: String
    private let directoryPath: String
    private var fileDescriptor: Int32 = -1
    private var dirDescriptor: Int32 = -1
    private var fileSource: DispatchSourceFileSystemObject?
    private var dirSource: DispatchSourceFileSystemObject?
    private var pollingTimer: DispatchSourceTimer?
    private var onChange: () -> Void
    private let queue = DispatchQueue(label: "com.saml2aws.filewatcher", qos: .utility)
    private var lastModificationDate: Date?

    init(filePath: String = CredentialsParser.defaultPath, onChange: @escaping () -> Void) {
        self.filePath = filePath
        self.directoryPath = (filePath as NSString).deletingLastPathComponent
        self.onChange = onChange
        self.lastModificationDate = fileModificationDate()
        setupWatching()
        startPolling()
    }

    deinit {
        stopFileWatching()
        stopDirWatching()
        stopPolling()
    }

    private func setupWatching() {
        if FileManager.default.fileExists(atPath: filePath) {
            startFileWatching()
        } else {
            startDirWatching()
        }
    }

    // MARK: - Watch the credentials file directly

    private func startFileWatching() {
        stopFileWatching()
        stopDirWatching()

        fileDescriptor = open(filePath, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            startDirWatching()
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename, .attrib],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = source.data
            if flags.contains(.delete) || flags.contains(.rename) {
                self.stopFileWatching()
                self.queue.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self else { return }
                    self.notifyChange()
                    self.setupWatching()
                }
            } else {
                self.notifyChange()
            }
        }

        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }

        fileSource = source
        source.resume()
    }

    private func stopFileWatching() {
        fileSource?.cancel()
        fileSource = nil
    }

    // MARK: - Watch parent directory (when file doesn't exist)

    private func startDirWatching() {
        stopDirWatching()

        dirDescriptor = open(directoryPath, O_EVTONLY)
        guard dirDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: dirDescriptor,
            eventMask: [.write],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            if FileManager.default.fileExists(atPath: self.filePath) {
                self.stopDirWatching()
                self.startFileWatching()
                self.notifyChange()
            }
        }

        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.dirDescriptor >= 0 {
                close(self.dirDescriptor)
                self.dirDescriptor = -1
            }
        }

        dirSource = source
        source.resume()
    }

    private func stopDirWatching() {
        dirSource?.cancel()
        dirSource = nil
    }

    // MARK: - Polling fallback (60s)

    private func startPolling() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 60, repeating: 60)
        timer.setEventHandler { [weak self] in
            self?.checkForChanges()
        }
        pollingTimer = timer
        timer.resume()
    }

    private func stopPolling() {
        pollingTimer?.cancel()
        pollingTimer = nil
    }

    private func checkForChanges() {
        let currentDate = fileModificationDate()
        if currentDate != lastModificationDate {
            lastModificationDate = currentDate
            notifyChange()
            // If file just appeared, switch from dir watching to file watching
            if fileSource == nil && FileManager.default.fileExists(atPath: filePath) {
                setupWatching()
            }
        }
    }

    private func fileModificationDate() -> Date? {
        let attrs = try? FileManager.default.attributesOfItem(atPath: filePath)
        return attrs?[.modificationDate] as? Date
    }

    private func notifyChange() {
        DispatchQueue.main.async { [weak self] in
            self?.onChange()
        }
    }
}
