import Foundation

class FTLDetector {
    static let shared = FTLDetector()

    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path

    let commonPaths: [(path: String, destination: FTLDestination)] = [
        ("Library/Application Support/Steam/steamapps/common/FTL Faster Than Light/FTL.app", .steam),
        ("Games/FTL Faster Than Light/FTL.app", .gog),
        ("Games/FTL/FTL.app", .humble),
    ]

    func detectFTLInstallations() -> [FTLInstallation] {
        var installations: [FTLInstallation] = []

        for (relativePath, destination) in commonPaths {
            let fullPath = "\(homeDirectory)/\(relativePath)"

            if FileManager.default.fileExists(atPath: fullPath) {
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
        }

        return installations
    }

    func readFTLVersion(from ftlAppPath: String) -> String? {
        let infoPlistPath = "\(ftlAppPath)/Contents/Info.plist"

        guard FileManager.default.fileExists(atPath: infoPlistPath) else {
            return nil
        }

        // Try to read version using plutil
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/libexec/PlistBuddy")
        process.arguments = ["-c", "Print :CFBundleShortVersionString", infoPlistPath]

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
            if let plist = NSDictionary(contentsOfFile: infoPlistPath) as? [String: Any],
               let version = plist["CFBundleShortVersionString"] as? String {
                return version
            }
        }

        return nil
    }

    func validateVersion(_ version: String) -> String? {
        if version == "1.6.12" || version == "1.6.13" {
            return version
        }
        return nil
    }

    func selectFTLManually() async -> FTLInstallation? {
        // This would be called when user clicks "Browse" button
        // Implementation in FTLSelectionView
        return nil
    }
}
