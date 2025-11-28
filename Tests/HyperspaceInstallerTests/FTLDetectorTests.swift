import Testing
import Foundation
@testable import HyperspaceInstallerLib

@Suite("FTLDetector Tests")
struct FTLDetectorTests {
    let detector = FTLDetector.shared
    let fileManager = FileManager.default

    // MARK: - Version Validation Tests

    @Test("Version 1.6.12 is valid")
    func testVersion1612IsValid() {
        let result = detector.validateVersion("1.6.12")
        #expect(result == "1.6.12")
    }

    @Test("Version 1.6.13 is valid")
    func testVersion1613IsValid() {
        let result = detector.validateVersion("1.6.13")
        #expect(result == "1.6.13")
    }

    @Test("Version 1.6.11 is invalid")
    func testVersion1611IsInvalid() {
        let result = detector.validateVersion("1.6.11")
        #expect(result == nil)
    }

    @Test("Version 2.0.0 is invalid")
    func testVersion200IsInvalid() {
        let result = detector.validateVersion("2.0.0")
        #expect(result == nil)
    }

    @Test("Empty version string is invalid")
    func testEmptyVersionIsInvalid() {
        let result = detector.validateVersion("")
        #expect(result == nil)
    }

    // MARK: - FTL Detection with Mock Structures

    @Test("Detects FTL with valid Info.plist")
    func testDetectsFTLWithValidPlist() throws {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        let ftlAppPath = tempDir.appendingPathComponent("FTL.app")
        let contentsPath = ftlAppPath.appendingPathComponent("Contents")
        try fileManager.createDirectory(at: contentsPath, withIntermediateDirectories: true)

        // Create a minimal valid Info.plist
        let infoPlistPath = contentsPath.appendingPathComponent("Info.plist")
        let plistDict: [String: Any] = [
            "CFBundleExecutable": "FTL",
            "CFBundleShortVersionString": "1.6.13"
        ]
        try (plistDict as NSDictionary).write(to: infoPlistPath)

        // Test reading the version from the mock plist
        let version = detector.readFTLVersion(from: ftlAppPath.path)
        #expect(version == "1.6.13")
    }

    @Test("Returns nil for FTL without Info.plist")
    func testMissingInfoPlist() throws {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        let ftlAppPath = tempDir.appendingPathComponent("FTL.app")
        try fileManager.createDirectory(at: ftlAppPath, withIntermediateDirectories: true)

        let version = detector.readFTLVersion(from: ftlAppPath.path)
        #expect(version == nil)
    }

    @Test("Returns nil for unsupported FTL version")
    func testUnsupportedFTLVersion() throws {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        let ftlAppPath = tempDir.appendingPathComponent("FTL.app")
        let contentsPath = ftlAppPath.appendingPathComponent("Contents")
        try fileManager.createDirectory(at: contentsPath, withIntermediateDirectories: true)

        // Create Info.plist with unsupported version
        let infoPlistPath = contentsPath.appendingPathComponent("Info.plist")
        let plistDict: [String: Any] = [
            "CFBundleExecutable": "FTL",
            "CFBundleShortVersionString": "1.6.11"
        ]
        try (plistDict as NSDictionary).write(to: infoPlistPath)

        let version = detector.readFTLVersion(from: ftlAppPath.path)
        #expect(version == "1.6.11")

        let validated = detector.validateVersion(version ?? "")
        #expect(validated == nil)
    }

    @Test("Detects multiple FTL installations")
    func testDetectsMultipleFTLInstallations() throws {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        // Create two mock FTL installations
        let ftl1Path = tempDir.appendingPathComponent("FTL1.app")
        let ftl2Path = tempDir.appendingPathComponent("FTL2.app")

        for ftlPath in [ftl1Path, ftl2Path] {
            let contentsPath = ftlPath.appendingPathComponent("Contents")
            try fileManager.createDirectory(at: contentsPath, withIntermediateDirectories: true)

            let infoPlistPath = contentsPath.appendingPathComponent("Info.plist")
            let plistDict: [String: Any] = [
                "CFBundleExecutable": "FTL",
                "CFBundleShortVersionString": "1.6.13"
            ]
            try (plistDict as NSDictionary).write(to: infoPlistPath)
        }

        // Verify we can read both versions
        let version1 = detector.readFTLVersion(from: ftl1Path.path)
        let version2 = detector.readFTLVersion(from: ftl2Path.path)

        #expect(version1 == "1.6.13")
        #expect(version2 == "1.6.13")
    }
}
