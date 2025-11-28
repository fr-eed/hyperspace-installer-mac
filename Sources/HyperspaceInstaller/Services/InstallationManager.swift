import Foundation
import AppKit

class InstallationManager {
    nonisolated(unsafe) static let shared = InstallationManager()

    let fileManager = FileManager.default
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path

    func isHyperspaceInstalled(ftl: FTLInstallation) -> Bool {
        // Check if Hyperspace.command exists in FTL.app
        let hyperspaceCommandPath = "\(ftl.path)/Contents/MacOS/Hyperspace.command"
        return fileManager.fileExists(atPath: hyperspaceCommandPath)
    }

    func installHyperspace(
        ftl: FTLInstallation,
        state: InstallationState,
        resourcePath: String
    ) async {
        let ftlDestination = ftl.destination.rawValue
        let ftlPath = ftl.path
        let ftlVersion = ftl.version
        let ftlDylibVersion = ftl.dylibVersion

        await MainActor.run {
            state.isInstalling = true
            state.installLog.removeAll()
            state.installationError = nil
            state.installationSuccess = false

            state.addLog("=== Hyperspace Installation Started ===")
            state.addLog("FTL Destination: \(ftlDestination)")
            state.addLog("FTL Location: \(ftlPath)")
            state.addLog("FTL Version: \(ftlVersion)")
            state.addLog("Using dylib version: \(ftlDylibVersion)")
            state.addLog("")
        }

        do {
            // Step 1: Create installation directory
            await updateProgress(state: state, step: 1, total: INSTALLATION_STEPS_TOTAL)
            try await installStep(
                state: state,
                title: "Creating installation directory",
                action: { try self.createInstallationDirectory() }
            )

            // Step 2: Copy files to user's Documents
            await updateProgress(state: state, step: 2, total: INSTALLATION_STEPS_TOTAL)
            try await installStep(
                state: state,
                title: "Copying Hyperspace files",
                action: { try self.copyHyperspaceFiles(resourcePath: resourcePath) }
            )

            // Step 3: Backup original Info.plist
            await updateProgress(state: state, step: 3, total: INSTALLATION_STEPS_TOTAL)
            try await installStep(
                state: state,
                title: "Backing up FTL configuration",
                action: { try self.backupInfoPlist(ftl: ftl) }
            )

            // Step 4: Modify Info.plist
            await updateProgress(state: state, step: 4, total: INSTALLATION_STEPS_TOTAL)
            try await installStep(
                state: state,
                title: "Modifying FTL.app configuration",
                action: { try self.modifyInfoPlist(ftl: ftl) }
            )

            // Step 5: Copy dylib
            await updateProgress(state: state, step: 5, total: INSTALLATION_STEPS_TOTAL)
            try await installStep(
                state: state,
                title: "Copying Hyperspace dylib",
                action: { try self.copyDylib(ftl: ftl, resourcePath: resourcePath) }
            )

            // Step 6: Copy Hyperspace.command
            await updateProgress(state: state, step: 6, total: INSTALLATION_STEPS_TOTAL)
            try await installStep(
                state: state,
                title: "Copying launcher script",
                action: { try self.copyHyperspaceCommand(ftl: ftl, resourcePath: resourcePath) }
            )

            // Step 7: Edit Hyperspace.command
            await updateProgress(state: state, step: 7, total: INSTALLATION_STEPS_TOTAL)
            try await installStep(
                state: state,
                title: "Updating launcher script",
                action: { try self.editHyperspaceCommand(ftl: ftl) }
            )

            // Step 8: Run ftlman patch
            await updateProgress(state: state, step: 8, total: INSTALLATION_STEPS_TOTAL)
            await MainActor.run {
                state.addLog("• Patching FTL mod data...")
            }
            try await self.runFTLManPatch(ftl: ftl)
            await MainActor.run {
                state.addLog("  ✓ Done")
            }

            // Step 9: Create ftlman config
            await updateProgress(state: state, step: 9, total: INSTALLATION_STEPS_TOTAL)
            try await installStep(
                state: state,
                title: "Creating ftlman configuration",
                action: { try self.createFTLManConfig(ftl: ftl) }
            )

            // Step 10: Codesign FTL.app
            await updateProgress(state: state, step: 10, total: INSTALLATION_STEPS_TOTAL)
            await MainActor.run {
                state.addLog("• Signing application...")
            }
            try self.codesignFTLApp(ftl: ftl)
            await MainActor.run {
                state.addLog("  ✓ Done")
            }

            await MainActor.run {
                state.addLog("")
                state.addLog("=== Installation Complete ===")
            }
            await MainActor.run {
                state.setSuccess()
            }

        } catch {
            await MainActor.run {
                state.setError("Installation failed: \(error.localizedDescription)")
                state.addLog("ERROR: \(error.localizedDescription)")

                // Attempt rollback
                state.addLog("Attempting to rollback changes...")
            }
            try? self.rollbackChanges(ftl: ftl)
        }
    }

    private func createInstallationDirectory() throws {
        let baseDir = InstallationPaths.baseDirectory(homeDirectory: homeDirectory)
        let modsDir = InstallationPaths.modsDirectory(homeDirectory: homeDirectory)

        try fileManager.createDirectory(atPath: baseDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: modsDir, withIntermediateDirectories: true)
    }

    private func copyHyperspaceFiles(resourcePath: String) throws {
        try copyFTLManIfNeeded(from: resourcePath)
        try copyModFileIfExists(from: resourcePath)
    }

    private func copyFTLManIfNeeded(from resourcePath: String) throws {
        let ftlmanSrc = "\(resourcePath)/ftlman"

        guard fileManager.fileExists(atPath: ftlmanSrc) else { return }

        let ftlmanDest = InstallationPaths.ftlmanPath(homeDirectory: homeDirectory)
        let shouldCopy = try shouldUpdateFile(source: ftlmanSrc, destination: ftlmanDest)

        guard shouldCopy else { return }

        try replaceFTLMan(source: ftlmanSrc, destination: ftlmanDest)
    }

    private func shouldUpdateFile(source: String, destination: String) throws -> Bool {
        guard fileManager.fileExists(atPath: destination) else {
            return true  // Copy if destination doesn't exist
        }

        let srcHash = try getFileHash(source)
        let destHash = try getFileHash(destination)
        return srcHash != destHash
    }

    private func replaceFTLMan(source: String, destination: String) throws {
        try? fileManager.removeItem(atPath: destination)
        try fileManager.copyItem(atPath: source, toPath: destination)
        try fileManager.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: destination)
        try Self.execShell("chmod +x '\(destination)'")
        try? Self.execShell("xattr -d com.apple.quarantine '\(destination)'")
    }

    private func copyModFileIfExists(from resourcePath: String) throws {
        let modSrc = "\(resourcePath)/mods/hyperspace.ftl"

        guard fileManager.fileExists(atPath: modSrc) else { return }

        let modDest = InstallationPaths.modFilePath(homeDirectory: homeDirectory)
        try? fileManager.removeItem(atPath: modDest)
        try fileManager.copyItem(atPath: modSrc, toPath: modDest)
    }

    private func backupInfoPlist(ftl: FTLInstallation) throws {
        let infoPlistPath = "\(ftl.path)/Contents/Info.plist"
        let backupPath = "\(infoPlistPath).bak"

        try? fileManager.removeItem(atPath: backupPath)
        try fileManager.copyItem(atPath: infoPlistPath, toPath: backupPath)
    }

    private func modifyInfoPlist(ftl: FTLInstallation) throws {
        let infoPlistPath = "\(ftl.path)/Contents/Info.plist"

        try Self.execShell(
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
        try Self.execShell("chmod +x '\(destPath)'")
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
        let ftlmanPath = InstallationPaths.ftlmanPath(homeDirectory: homeDirectory)
        let modPath = InstallationPaths.modFilePath(homeDirectory: homeDirectory)

        try? Self.execShell("xattr -d com.apple.quarantine '\(ftlmanPath)'")

        try await runFTLManPatchWithGatekeeperRetry(
            ftlmanPath: ftlmanPath,
            modPath: modPath,
            dataDir: ftl.ftlDataPath
        )
    }

    private func runFTLManPatchWithGatekeeperRetry(
        ftlmanPath: String,
        modPath: String,
        dataDir: String
    ) async throws {
        do {
            try await execShellAsync(
                "'\(ftlmanPath)' patch '\(modPath)' -d '\(dataDir)'"
            )
        } catch {
            let userAllowed = await showGatekeeperPrompt()
            guard userAllowed else {
                throw InstallationError.gatekeeperBlocked
            }

            // Retry recursively after user allows
            try await runFTLManPatchWithGatekeeperRetry(
                ftlmanPath: ftlmanPath,
                modPath: modPath,
                dataDir: dataDir
            )
        }
    }

    private func showGatekeeperPrompt() async -> Bool {
        let result = await MainActor.run {
            let alert = NSAlert()
            alert.messageText = "ftlman Blocked by Gatekeeper"
            alert.informativeText = "ftlman needs to be allowed to run.\n\nPlease go to System Preferences > Security & Privacy and click 'Allow' for ftlman, then click OK to continue."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            return response == .alertFirstButtonReturn
        }
        return result
    }

    private func codesignFTLApp(ftl: FTLInstallation) throws {
        try Self.execShell(
            "codesign -f -s - --timestamp=none --all-architectures --deep '\(ftl.path)'"
        )
    }

    private func createFTLManConfig(ftl: FTLInstallation) throws {
        let configPath = InstallationPaths.configPath(homeDirectory: homeDirectory)

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

    private static func execShell(_ command: String) throws {
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
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try Self.execShell(command)
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
