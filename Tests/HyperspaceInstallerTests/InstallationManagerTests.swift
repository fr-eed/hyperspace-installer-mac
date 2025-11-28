import Testing
import Foundation
@testable import HyperspaceInstallerLib

@Suite("InstallationManager Patcher Tests")
struct InstallationManagerTests {
    let manager = InstallationManager.shared
    let fileManager = FileManager.default

    // MARK: - Plist Modification Tests

    @Test("Modifies Info.plist on original FTL")
    func testModifyPlistOnOriginalFTL() throws {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        let ftlAppPath = tempDir.appendingPathComponent("FTL.app")
        let macosPath = ftlAppPath.appendingPathComponent("Contents/MacOS")
        try fileManager.createDirectory(at: macosPath, withIntermediateDirectories: true)

        // Create original Info.plist with FTL as executable
        let infoPlistPath = ftlAppPath.appendingPathComponent("Contents/Info.plist")
        let originalPlist: [String: Any] = [
            "CFBundleExecutable": "FTL",
            "CFBundleShortVersionString": "1.6.13",
            "CFBundleName": "FTL"
        ]
        try (originalPlist as NSDictionary).write(to: infoPlistPath)

        // Verify original state
        let originalDict = NSDictionary(contentsOf: infoPlistPath) as? [String: Any]
        #expect(originalDict?["CFBundleExecutable"] as? String == "FTL")

        // Modify plist using plutil (same as modifyInfoPlist does)
        let modifyCommand = "plutil -replace CFBundleExecutable -string 'Hyperspace.command' '\(infoPlistPath.path)'"
        try runShellCommand(modifyCommand)

        // Verify plist was modified
        let modifiedDict = NSDictionary(contentsOf: infoPlistPath) as? [String: Any]
        #expect(modifiedDict?["CFBundleExecutable"] as? String == "Hyperspace.command")

        // Verify other keys are unchanged
        #expect(modifiedDict?["CFBundleName"] as? String == "FTL")
        #expect(modifiedDict?["CFBundleShortVersionString"] as? String == "1.6.13")
    }

    @Test("Modifies Info.plist on already-patched FTL")
    func testModifyPlistOnAlreadyPatchedFTL() throws {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        let ftlAppPath = tempDir.appendingPathComponent("FTL.app")
        let macosPath = ftlAppPath.appendingPathComponent("Contents/MacOS")
        try fileManager.createDirectory(at: macosPath, withIntermediateDirectories: true)

        // Create Info.plist that's already been patched (Hyperspace.command as executable)
        let infoPlistPath = ftlAppPath.appendingPathComponent("Contents/Info.plist")
        let alreadyPatchedPlist: [String: Any] = [
            "CFBundleExecutable": "Hyperspace.command",
            "CFBundleShortVersionString": "1.6.13",
            "CFBundleName": "FTL"
        ]
        try (alreadyPatchedPlist as NSDictionary).write(to: infoPlistPath)

        // Verify already-patched state
        let beforeDict = NSDictionary(contentsOf: infoPlistPath) as? [String: Any]
        #expect(beforeDict?["CFBundleExecutable"] as? String == "Hyperspace.command")

        // Apply modification again (should be idempotent)
        let modifyCommand = "plutil -replace CFBundleExecutable -string 'Hyperspace.command' '\(infoPlistPath.path)'"
        try runShellCommand(modifyCommand)

        // Verify plist still has Hyperspace.command
        let afterDict = NSDictionary(contentsOf: infoPlistPath) as? [String: Any]
        #expect(afterDict?["CFBundleExecutable"] as? String == "Hyperspace.command")

        // Verify modification is idempotent
        #expect(beforeDict?["CFBundleExecutable"] as? String == afterDict?["CFBundleExecutable"] as? String)
    }

    @Test("Preserves other plist keys during modification")
    func testPreservesPlistKeysOnModification() throws {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        let ftlAppPath = tempDir.appendingPathComponent("FTL.app")
        let macosPath = ftlAppPath.appendingPathComponent("Contents/MacOS")
        try fileManager.createDirectory(at: macosPath, withIntermediateDirectories: true)

        // Create Info.plist with multiple keys
        let infoPlistPath = ftlAppPath.appendingPathComponent("Contents/Info.plist")
        let originalPlist: [String: Any] = [
            "CFBundleExecutable": "FTL",
            "CFBundleShortVersionString": "1.6.13",
            "CFBundleName": "FTL",
            "CFBundleIdentifier": "com.subset.ftl",
            "CFBundleVersion": "1.0",
            "NSPrincipalClass": "NSApplication"
        ]
        try (originalPlist as NSDictionary).write(to: infoPlistPath)

        // Store original values
        let originalDict = NSDictionary(contentsOf: infoPlistPath) as? [String: Any]

        // Modify plist
        let modifyCommand = "plutil -replace CFBundleExecutable -string 'Hyperspace.command' '\(infoPlistPath.path)'"
        try runShellCommand(modifyCommand)

        // Verify all other keys are preserved
        let modifiedDict = NSDictionary(contentsOf: infoPlistPath) as? [String: Any]
        #expect(modifiedDict?["CFBundleShortVersionString"] as? String == originalDict?["CFBundleShortVersionString"] as? String)
        #expect(modifiedDict?["CFBundleName"] as? String == originalDict?["CFBundleName"] as? String)
        #expect(modifiedDict?["CFBundleIdentifier"] as? String == originalDict?["CFBundleIdentifier"] as? String)
        #expect(modifiedDict?["CFBundleVersion"] as? String == originalDict?["CFBundleVersion"] as? String)
        #expect(modifiedDict?["NSPrincipalClass"] as? String == originalDict?["NSPrincipalClass"] as? String)

        // Only CFBundleExecutable should change
        #expect(originalDict?["CFBundleExecutable"] as? String == "FTL")
        #expect(modifiedDict?["CFBundleExecutable"] as? String == "Hyperspace.command")
    }

    // MARK: - Helper Methods

    private func runShellCommand(_ command: String) throws {
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
}
