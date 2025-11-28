import Foundation
import AppKit

class InstallationManager {
    static let shared = InstallationManager()

    let fileManager = FileManager.default
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path

    func isHyperspaceInstalled(ftl: FTLInstallation) -> Bool {
        // Check if Hyperspace.command exists in FTL.app
        let hyperspaceCommandPath = "\(ftl.path)/Contents/MacOS/Hyperspace.command"
        return fileManager.fileExists(atPath: hyperspaceCommandPath)
    }

    @MainActor
    func installHyperspace(
        ftl: FTLInstallation,
        state: InstallationState,
        resourcePath: String
    ) async {
        state.isInstalling = true
        state.installLog.removeAll()
        state.installationError = nil
        state.installationSuccess = false

        state.addLog("=== Hyperspace Installation Started ===")
        state.addLog("FTL Destination: \(ftl.destination.rawValue)")
        state.addLog("FTL Location: \(ftl.path)")
        state.addLog("FTL Version: \(ftl.version)")
        state.addLog("Using dylib version: \(ftl.dylibVersion)")
        state.addLog("")

        do {
            let totalSteps = 10.0

            // Step 1: Create installation directory
            await updateProgress(state: state, step: 1, total: totalSteps)
            try await installStep(
                state: state,
                title: "Creating installation directory",
                action: {
                    try self.createInstallationDirectory()
                }
            )

            // Step 2: Copy files to user's Documents
            await updateProgress(state: state, step: 2, total: totalSteps)
            try await installStep(
                state: state,
                title: "Copying Hyperspace files",
                action: {
                    try self.copyHyperspaceFiles(resourcePath: resourcePath)
                }
            )

            // Step 3: Backup original Info.plist
            await updateProgress(state: state, step: 3, total: totalSteps)
            try await installStep(
                state: state,
                title: "Backing up FTL configuration",
                action: {
                    try self.backupInfoPlist(ftl: ftl)
                }
            )

            // Step 4: Modify Info.plist
            await updateProgress(state: state, step: 4, total: totalSteps)
            try await installStep(
                state: state,
                title: "Modifying FTL.app configuration",
                action: {
                    try self.modifyInfoPlist(ftl: ftl)
                }
            )

            // Step 5: Copy dylib
            await updateProgress(state: state, step: 5, total: totalSteps)
            try await installStep(
                state: state,
                title: "Copying Hyperspace dylib",
                action: {
                    try self.copyDylib(ftl: ftl, resourcePath: resourcePath)
                }
            )

            // Step 6: Copy Hyperspace.command
            await updateProgress(state: state, step: 6, total: totalSteps)
            try await installStep(
                state: state,
                title: "Copying launcher script",
                action: {
                    try self.copyHyperspaceCommand(ftl: ftl, resourcePath: resourcePath)
                }
            )

            // Step 7: Edit Hyperspace.command
            await updateProgress(state: state, step: 7, total: totalSteps)
            try await installStep(
                state: state,
                title: "Updating launcher script",
                action: {
                    try self.editHyperspaceCommand(ftl: ftl)
                }
            )

            // Step 8: Run ftlman patch
            await updateProgress(state: state, step: 8, total: totalSteps)
            state.addLog("• Patching FTL mod data...")
            try await self.runFTLManPatch(ftl: ftl)
            state.addLog("  ✓ Done")

            // Step 9: Create ftlman config
            await updateProgress(state: state, step: 9, total: totalSteps)
            try await installStep(
                state: state,
                title: "Creating ftlman configuration",
                action: {
                    try self.createFTLManConfig(ftl: ftl)
                }
            )

            // Step 10: Codesign FTL.app
            await updateProgress(state: state, step: 10, total: totalSteps)
            state.addLog("• Signing application...")
            try self.codesignFTLApp(ftl: ftl)
            state.addLog("  ✓ Done")

            await MainActor.run {
                state.addLog("")
                state.addLog("=== Installation Complete ===")
            }
            state.setSuccess()

        } catch {
            state.setError("Installation failed: \(error.localizedDescription)")
            state.addLog("ERROR: \(error.localizedDescription)")

            // Attempt rollback
            state.addLog("Attempting to rollback changes...")
            try? self.rollbackChanges(ftl: ftl)
        }
    }

    private func createInstallationDirectory() throws {
        let dirPath = "\(homeDirectory)/Documents/FTLHyperspace"
        let modsPath = "\(dirPath)/mods"

        try fileManager.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: modsPath, withIntermediateDirectories: true)
    }

    private func copyHyperspaceFiles(resourcePath: String) throws {
        let sourceDir = resourcePath
        let destDir = "\(homeDirectory)/Documents/FTLHyperspace"

        // Copy ftlman
        let ftlmanSrc = "\(sourceDir)/ftlman"
        let ftlmanDest = "\(destDir)/ftlman"

        if fileManager.fileExists(atPath: ftlmanSrc) {
            // Check if ftlman already exists and has the same hash
            let shouldCopy: Bool
            if fileManager.fileExists(atPath: ftlmanDest) {
                let srcHash = try getFileHash(ftlmanSrc)
                let destHash = try getFileHash(ftlmanDest)
                shouldCopy = srcHash != destHash
            } else {
                shouldCopy = true
            }

            if shouldCopy {
                try? fileManager.removeItem(atPath: ftlmanDest)
                try fileManager.copyItem(atPath: ftlmanSrc, toPath: ftlmanDest)
                try fileManager.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: ftlmanDest)
                try execShell("chmod +x '\(ftlmanDest)'")
                // Remove quarantine attribute so Gatekeeper doesn't block it
                try? execShell("xattr -d com.apple.quarantine '\(ftlmanDest)'")
            }
        }

        // Copy hyperspace.ftl
        let modSrc = "\(sourceDir)/mods/hyperspace.ftl"
        let modDest = "\(destDir)/mods/hyperspace.ftl"

        if fileManager.fileExists(atPath: modSrc) {
            try? fileManager.removeItem(atPath: modDest)
            try fileManager.copyItem(atPath: modSrc, toPath: modDest)
        }
    }

    private func backupInfoPlist(ftl: FTLInstallation) throws {
        let infoPlistPath = "\(ftl.path)/Contents/Info.plist"
        let backupPath = "\(infoPlistPath).bak"

        try? fileManager.removeItem(atPath: backupPath)
        try fileManager.copyItem(atPath: infoPlistPath, toPath: backupPath)
    }

    private func modifyInfoPlist(ftl: FTLInstallation) throws {
        let infoPlistPath = "\(ftl.path)/Contents/Info.plist"

        try execShell(
            "plutil -replace CFBundleExecutable -string 'Hyperspace.command' '\(infoPlistPath)'"
        )
    }

    private func copyDylib(ftl: FTLInstallation, resourcePath: String) throws {
        let dylibName = "Hyperspace.\(ftl.dylibVersion).amd64.dylib"
        let sourcePath = "\(resourcePath)/\(dylibName)"
        let destPath = "\(ftl.path)/Contents/MacOS/\(dylibName)"

        if fileManager.fileExists(atPath: sourcePath) {
            // Remove existing dylib if it exists
            try? fileManager.removeItem(atPath: destPath)
            try fileManager.copyItem(atPath: sourcePath, toPath: destPath)
        } else {
            throw NSError(domain: "dylib not found: \(sourcePath)", code: -1)
        }
    }

    private func copyHyperspaceCommand(ftl: FTLInstallation, resourcePath: String) throws {
        let sourcePath = "\(resourcePath)/Hyperspace.command"
        let destPath = "\(ftl.path)/Contents/MacOS/Hyperspace.command"

        // Remove existing file if it exists
        try? fileManager.removeItem(atPath: destPath)
        try fileManager.copyItem(atPath: sourcePath, toPath: destPath)
        try execShell("chmod +x '\(destPath)'")
    }

    private func editHyperspaceCommand(ftl: FTLInstallation) throws {
        let scriptPath = "\(ftl.path)/Contents/MacOS/Hyperspace.command"

        // Read the file
        let content = try String(contentsOfFile: scriptPath, encoding: .utf8)

        // Replace the dylib version
        let updated = content.replacingOccurrences(
            of: "Hyperspace\\.1\\.6\\.[0-9]+\\.amd64\\.dylib",
            with: "Hyperspace.\(ftl.dylibVersion).amd64.dylib",
            options: .regularExpression
        )

        // Write back
        try updated.write(toFile: scriptPath, atomically: true, encoding: .utf8)
    }

    private func runFTLManPatch(ftl: FTLInstallation) async throws {
        let ftlmanPath = "\(homeDirectory)/Documents/FTLHyperspace/ftlman"
        let modPath = "\(homeDirectory)/Documents/FTLHyperspace/mods/hyperspace.ftl"
        let dataDir = ftl.ftlDataPath

        // Remove quarantine attribute before running ftlman
        try? execShell("xattr -d com.apple.quarantine '\(ftlmanPath)'")

        var shouldRetry = true
        while shouldRetry {
            do {
                try await execShellAsync(
                    "'\(ftlmanPath)' patch '\(modPath)' -d '\(dataDir)'"
                )
                shouldRetry = false
            } catch {
                // Any error is treated as Gatekeeper blocking ftlman
                let userAllowed = await showGatekeeperPrompt()
                if !userAllowed {
                    throw error
                }
                // User clicked OK, loop will retry
            }
        }
    }

    @MainActor
    private func showGatekeeperPrompt() async -> Bool {
        let alert = NSAlert()
        alert.messageText = "ftlman Blocked by Gatekeeper"
        alert.informativeText = "ftlman needs to be allowed to run.\n\nPlease go to System Preferences > Security & Privacy and click 'Allow' for ftlman, then click OK to continue."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        return response == .alertFirstButtonReturn
    }

    private func codesignFTLApp(ftl: FTLInstallation) throws {
        try execShell(
            "codesign -f -s - --timestamp=none --all-architectures --deep '\(ftl.path)'"
        )
    }

    private func createFTLManConfig(ftl: FTLInstallation) throws {
        let configPath = "\(homeDirectory)/Documents/FTLHyperspace/settings.json"

        let config: [String: Any] = [
            "mod_directory": "mods",
            "ftl_directory": ftl.ftlDataPath,
            "dirs_are_mods": true,
            "zips_are_mods": true,
            "ftl_is_zip": true,
            "repack_ftl_data": true,
            "disable_hs_installer": false,
            "autoupdate": true,
            "warn_about_missing_hyperspace": true,
            "theme": [
                "colors": "Dark",
                "opacity": 1.0
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
        try jsonData.write(to: URL(fileURLWithPath: configPath))
    }

    private func rollbackChanges(ftl: FTLInstallation) throws {
        let infoPlistPath = "\(ftl.path)/Contents/Info.plist"
        let backupPath = "\(infoPlistPath).bak"

        if fileManager.fileExists(atPath: backupPath) {
            try fileManager.removeItem(atPath: infoPlistPath)
            try fileManager.copyItem(atPath: backupPath, toPath: infoPlistPath)
        }
    }

    // MARK: - Helper Methods

    private func execShell(_ command: String) throws {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "Shell command failed: \(output)", code: -1)
        }
    }

    private func execShellAsync(_ command: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    try self?.execShell(command)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func installStep(
        state: InstallationState,
        title: String,
        action: @escaping () throws -> Void
    ) async throws {
        await MainActor.run {
            state.addLog("• \(title)...")
        }
        try action()
        await MainActor.run {
            state.addLog("  ✓ Done")
        }
    }

    private func updateProgress(state: InstallationState, step: Double, total: Double) async {
        await MainActor.run {
            state.installProgress = step / total
        }
    }

    private func getFileHash(_ filePath: String) throws -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "md5 -q '\(filePath)'"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let hash = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return hash
    }
}
