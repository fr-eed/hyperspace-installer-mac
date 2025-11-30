import Foundation

class LogManager {
    nonisolated(unsafe) static let shared = LogManager()

    let fileManager = FileManager.default
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
    private var logFilePath: String?

    @MainActor
    func initializeLog() throws {
        let logsDir = InstallationPaths.logsDirectory(homeDirectory: homeDirectory)
        try fileManager.createDirectory(atPath: logsDir, withIntermediateDirectories: true)

        let logPath = "\(logsDir)/install.log"
        self.logFilePath = logPath

        // Create new log file, overwriting any existing one
        try "".write(toFile: logPath, atomically: true, encoding: .utf8)
    }

    func appendLog(_ message: String) throws {
        guard let logPath = logFilePath else { return }

        if let fileHandle = FileHandle(forWritingAtPath: logPath) {
            fileHandle.seekToEndOfFile()
            if let data = "\(message)\n".data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        }
    }
}
