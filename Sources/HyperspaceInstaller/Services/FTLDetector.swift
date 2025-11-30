import Foundation

public class FTLDetector {
    nonisolated(unsafe) static let shared = FTLDetector()

    private let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
    private let fileManager = FileManager.default

    public func detectFTLInstallations() -> [FTLInstallation] {
        var installations: [FTLInstallation] = []

        for (pathString, destination) in FTLInstallationLocations.commonPaths {
            let fullPath = pathString.replacingOccurrences(of: "$HOME", with: homeDirectory)

            guard fileManager.fileExists(atPath: fullPath) else { continue }

            if let version = readFTLVersion(from: fullPath),
               let dylibVersion = validateVersion(version) {
                let installation = FTLInstallation(
                    path: fullPath,
                    destination: destination,
                    version: version,
                    dylibVersion: dylibVersion
                )
                installations.append(installation)
            }
        }

        return installations
    }

    func readFTLVersion(from ftlAppPath: String) -> String? {
        let infoPlistPath = "\(ftlAppPath)/Contents/Info.plist"

        guard fileManager.fileExists(atPath: infoPlistPath) else {
            return nil
        }

        return readVersionFromPlist(atPath: infoPlistPath)
    }

    private func readVersionFromPlist(atPath path: String) -> String? {
        // Try to read version using PlistBuddy
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/libexec/PlistBuddy")
        process.arguments = ["-c", "Print :CFBundleShortVersionString", path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            // Fallback: try to read using NSDictionary
            if let plist = NSDictionary(contentsOfFile: path) as? [String: Any],
               let version = plist["CFBundleShortVersionString"] as? String {
                return version
            }
        }

        return nil
    }

    func validateVersion(_ version: String) -> String? {
        SupportedFTLVersions.all.contains(version) ? version : nil
    }
}
