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

            do {
                try LogManager.shared.initializeLog()
            } catch {
                state.addLog("Warning: Could not initialize log file: \(error)")
            }

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

            // Step 2: Copy files to ~/Games/FTLHyperspace
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
            try await self.runFTLManPatch(ftl: ftl, state: state)
            await MainActor.run {
                state.addLog("  ✓ Patching complete")
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

    func uninstallHyperspace(
        ftl: FTLInstallation,
        state: InstallationState
    ) async {
        let ftlPath = ftl.path

        await MainActor.run {
            state.isInstalling = true
            state.installLog.removeAll()
            state.installationError = nil
            state.installationSuccess = false

            do {
                try LogManager.shared.initializeLog()
            } catch {
                state.addLog("Warning: Could not initialize log file: \(error)")
            }

            state.addLog("=== Hyperspace Uninstallation Started ===")
            state.addLog("FTL Location: \(ftlPath)")
            state.addLog("")
        }

        do {
            // Step 1: Restore Info.plist
            await updateProgress(state: state, step: 1, total: 4)
            try await installStep(
                state: state,
                title: "Restoring FTL configuration",
                action: { try self.restoreInfoPlist(ftl: ftl) }
            )

            // Step 2: Remove Hyperspace files
            await updateProgress(state: state, step: 2, total: 4)
            try await installStep(
                state: state,
                title: "Removing Hyperspace files",
                action: { try self.removeHyperspaceFiles(ftl: ftl) }
            )

            // Step 3: Restore FTL data
            await updateProgress(state: state, step: 3, total: 4)
            try await installStep(
                state: state,
                title: "Restoring FTL data",
                action: { try self.restoreFTLData(ftl: ftl) }
            )

            // Step 4: Codesign FTL.app
            await updateProgress(state: state, step: 4, total: 4)
            await MainActor.run {
                state.addLog("• Signing application...")
            }
            try self.codesignFTLApp(ftl: ftl)
            await MainActor.run {
                state.addLog("  ✓ Done")
            }

            await MainActor.run {
                state.addLog("")
                state.addLog("=== Uninstallation Complete ===")
                state.setSuccess()
            }

        } catch {
            await MainActor.run {
                state.setError("Uninstallation failed: \(error.localizedDescription)")
                state.addLog("ERROR: \(error.localizedDescription)")
            }
        }
    }

    private func restoreInfoPlist(ftl: FTLInstallation) throws {
        let infoPlistPath = "\(ftl.path)/Contents/Info.plist"
        let backupPath = "\(infoPlistPath).vanilla"

        if fileManager.fileExists(atPath: backupPath) {
            try fileManager.removeItem(atPath: infoPlistPath)
            try fileManager.copyItem(atPath: backupPath, toPath: infoPlistPath)
        } else {
            throw NSError(domain: "Backup Info.plist not found", code: -1)
        }
    }

    private func removeHyperspaceFiles(ftl: FTLInstallation) throws {
        let macosDir = "\(ftl.path)/Contents/MacOS"
        let files = try fileManager.contentsOfDirectory(atPath: macosDir)

        for file in files {
            if file.hasPrefix("Hyperspace") {
                let filePath = "\(macosDir)/\(file)"
                try? fileManager.removeItem(atPath: filePath)
            }
        }
    }

    private func restoreFTLData(ftl: FTLInstallation) throws {
        let dataDir = ftl.ftlDataPath
        let ftlDatPath = "\(dataDir)/ftl.dat"
        let vanillaDatPath = "\(dataDir)/ftl.dat.vanilla"

        if fileManager.fileExists(atPath: vanillaDatPath) {
            try fileManager.removeItem(atPath: ftlDatPath)
            try fileManager.copyItem(atPath: vanillaDatPath, toPath: ftlDatPath)
        } else {
            throw NSError(domain: "Vanilla FTL data not found", code: -1)
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
        try copyAllModFiles(from: resourcePath)
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

    private func copyAllModFiles(from resourcePath: String) throws {
        let modsSourceDir = "\(resourcePath)/mods"
        let modsDestDir = InstallationPaths.modsDirectory(homeDirectory: homeDirectory)

        guard fileManager.fileExists(atPath: modsSourceDir) else { return }

        // Get all .ftl and .zip files from the bundled mods directory
        let modFiles = try fileManager.contentsOfDirectory(atPath: modsSourceDir)
            .filter { $0.hasSuffix(".ftl") || $0.hasSuffix(".zip") }

        for modFile in modFiles {
            let sourcePath = "\(modsSourceDir)/\(modFile)"
            let destPath = "\(modsDestDir)/\(modFile)"

            try? fileManager.removeItem(atPath: destPath)
            try fileManager.copyItem(atPath: sourcePath, toPath: destPath)
        }
    }

    private func backupInfoPlist(ftl: FTLInstallation) throws {
        let infoPlistPath = "\(ftl.path)/Contents/Info.plist"
        let backupPath = "\(infoPlistPath).vanilla"

        // Only create backup if it doesn't already exist
        if !fileManager.fileExists(atPath: backupPath) {
            try fileManager.copyItem(atPath: infoPlistPath, toPath: backupPath)
        }
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

    private func runFTLManPatch(ftl: FTLInstallation, state: InstallationState) async throws {
        let ftlmanPath = InstallationPaths.ftlmanPath(homeDirectory: homeDirectory)
        let modsDir = InstallationPaths.modsDirectory(homeDirectory: homeDirectory)

        try? Self.execShell("xattr -d com.apple.quarantine '\(ftlmanPath)'")

        // Get list of mods from mods.plist (order is important)
        let modsList = try readModsList(state: state)
        let ftlDataPath = ftl.ftlDataPath

        await MainActor.run {
            state.addLog("  Mods to patch: \(modsList.joined(separator: ", "))")
            state.addLog("  FTL Data Dir: \(ftlDataPath)")
        }

        // Build paths for all mod files
        var modPaths: [String] = []
        for modFile in modsList {
            let modPath = "\(modsDir)/\(modFile)"

            guard fileManager.fileExists(atPath: modPath) else {
                throw InstallationError.fileCopyFailed("Mod file not found: \(modFile)")
            }

            modPaths.append(modPath)
        }

        // Patch all mods at once with a single ftlman call
        if !modPaths.isEmpty {
            try await runFTLManPatchWithGatekeeperRetry(
                ftlmanPath: ftlmanPath,
                modPaths: modPaths,
                dataDir: ftl.ftlDataPath,
                state: state
            )
        }
    }

    private func runFTLManPatchWithGatekeeperRetry(
        ftlmanPath: String,
        modPaths: [String],
        dataDir: String,
        state: InstallationState
    ) async throws {
        do {
            // Build command with all mod files
            let modArgs = modPaths.map { "'\($0)'" }.joined(separator: " ")
            let command = "'\(ftlmanPath)' patch \(modArgs) -d '\(dataDir)'"

            // Log the exact command being executed
            await MainActor.run {
                state.addLog("  Command: \(command)")
            }

            try await execShellAsync(command)
        } catch {
            let userAllowed = await showGatekeeperPrompt()
            guard userAllowed else {
                throw InstallationError.gatekeeperBlocked
            }

            // Retry recursively after user allows
            try await runFTLManPatchWithGatekeeperRetry(
                ftlmanPath: ftlmanPath,
                modPaths: modPaths,
                dataDir: dataDir,
                state: state
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

    public func readModsList(state: InstallationState? = nil) throws -> [String] {
        let resourcePath = Bundle.main.resourcePath ?? ""
        let modsPlistPath = "\(resourcePath)/mods.plist"

        guard fileManager.fileExists(atPath: modsPlistPath) else {
            return []
        }

        // Read plist as dictionary
        guard let plist = NSDictionary(contentsOfFile: modsPlistPath) else {
            return []
        }

        // Extract mods array from dictionary
        guard let modsArray = plist["mods"] as? [String] else {
            return []
        }

        return modsArray
    }

    private func rollbackChanges(ftl: FTLInstallation) throws {
        let infoPlistPath = "\(ftl.path)/Contents/Info.plist"
        let backupPath = "\(infoPlistPath).vanilla"

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
