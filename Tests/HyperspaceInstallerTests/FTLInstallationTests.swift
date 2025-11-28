import Testing
import Foundation
@testable import HyperspaceInstallerLib

@Suite("FTLInstallation Tests")
struct FTLInstallationTests {

    // MARK: - Initialization Tests

    @Test("FTLInstallation initializes with all properties")
    func testInitialization() {
        let ftl = FTLInstallation(
            path: "/path/to/ftl",
            destination: .steam,
            version: "1.6.13",
            dylibVersion: "1.6.13"
        )

        #expect(ftl.path == "/path/to/ftl")
        #expect(ftl.destination == .steam)
        #expect(ftl.version == "1.6.13")
        #expect(ftl.dylibVersion == "1.6.13")
    }

    @Test("FTLInstallation generates unique IDs")
    func testUniqueIDs() {
        let ftl1 = FTLInstallation(
            path: "/path1",
            destination: .steam,
            version: "1.6.13",
            dylibVersion: "1.6.13"
        )
        let ftl2 = FTLInstallation(
            path: "/path2",
            destination: .gog,
            version: "1.6.13",
            dylibVersion: "1.6.13"
        )

        #expect(ftl1.id != ftl2.id)
    }

    // MARK: - Display Name Tests

    @Test("displayName formats destination and version")
    func testDisplayNameFormat() {
        let ftl = FTLInstallation(
            path: "/path",
            destination: .steam,
            version: "1.6.13",
            dylibVersion: "1.6.13"
        )

        #expect(ftl.displayName == "Steam - v1.6.13")
    }

    @Test("displayName works for all destinations")
    func testDisplayNameAllDestinations() {
        let destinations: [FTLDestination] = [.steam, .gog, .humble, .custom]
        let expectedNames = ["Steam - v1.6.13", "GOG - v1.6.13", "Humble - v1.6.13", "Custom - v1.6.13"]

        for (destination, expectedName) in zip(destinations, expectedNames) {
            let ftl = FTLInstallation(
                path: "/path",
                destination: destination,
                version: "1.6.13",
                dylibVersion: "1.6.13"
            )
            #expect(ftl.displayName == expectedName)
        }
    }

    @Test("displayName with different version")
    func testDisplayNameDifferentVersion() {
        let ftl = FTLInstallation(
            path: "/path",
            destination: .gog,
            version: "1.6.12",
            dylibVersion: "1.6.12"
        )

        #expect(ftl.displayName == "GOG - v1.6.12")
    }

    // MARK: - Path Property Tests

    @Test("ftlAppPath returns the app path")
    func testFTLAppPath() {
        let expectedPath = "/Users/test/Games/FTL/FTL.app"
        let ftl = FTLInstallation(
            path: expectedPath,
            destination: .humble,
            version: "1.6.13",
            dylibVersion: "1.6.13"
        )

        #expect(ftl.ftlAppPath == expectedPath)
    }

    @Test("ftlDataPath constructs Contents/Resources path")
    func testFTLDataPath() {
        let appPath = "/Users/test/Games/FTL/FTL.app"
        let ftl = FTLInstallation(
            path: appPath,
            destination: .humble,
            version: "1.6.13",
            dylibVersion: "1.6.13"
        )

        let expectedDataPath = "\(appPath)/Contents/Resources"
        #expect(ftl.ftlDataPath == expectedDataPath)
    }

    @Test("ftlDataPath works with Steam path")
    func testFTLDataPathSteam() {
        let steamPath = "/Users/test/Library/Application Support/Steam/steamapps/common/FTL Faster Than Light/FTL.app"
        let ftl = FTLInstallation(
            path: steamPath,
            destination: .steam,
            version: "1.6.13",
            dylibVersion: "1.6.13"
        )

        let expectedDataPath = "\(steamPath)/Contents/Resources"
        #expect(ftl.ftlDataPath == expectedDataPath)
    }

    // MARK: - Equatable Tests

    @Test("Two FTLInstallations with same path are equal")
    func testEqualityByPath() {
        let ftl1 = FTLInstallation(
            path: "/path/to/ftl",
            destination: .steam,
            version: "1.6.13",
            dylibVersion: "1.6.13"
        )
        let ftl2 = FTLInstallation(
            path: "/path/to/ftl",
            destination: .gog,
            version: "1.6.12",
            dylibVersion: "1.6.12"
        )

        // Should be equal because paths are the same (despite different destination/version)
        #expect(ftl1 == ftl2)
    }

    @Test("Two FTLInstallations with different paths are not equal")
    func testInequalityByPath() {
        let ftl1 = FTLInstallation(
            path: "/path/to/ftl1",
            destination: .steam,
            version: "1.6.13",
            dylibVersion: "1.6.13"
        )
        let ftl2 = FTLInstallation(
            path: "/path/to/ftl2",
            destination: .steam,
            version: "1.6.13",
            dylibVersion: "1.6.13"
        )

        #expect(ftl1 != ftl2)
    }

    @Test("Equality ignores ID differences")
    func testEqualityIgnoresID() {
        let path = "/path/to/ftl"
        let ftl1 = FTLInstallation(
            path: path,
            destination: .steam,
            version: "1.6.13",
            dylibVersion: "1.6.13"
        )
        let ftl2 = FTLInstallation(
            path: path,
            destination: .steam,
            version: "1.6.13",
            dylibVersion: "1.6.13"
        )

        // IDs will be different, but instances should be equal
        #expect(ftl1.id != ftl2.id)
        #expect(ftl1 == ftl2)
    }

    // MARK: - Destination Enum Tests

    @Test("FTLDestination has all required cases")
    func testDestinationCases() {
        let destinations: [FTLDestination] = [.steam, .gog, .humble, .custom]
        #expect(destinations.count == 4)
    }

    @Test("FTLDestination rawValues are correct")
    func testDestinationRawValues() {
        #expect(FTLDestination.steam.rawValue == "Steam")
        #expect(FTLDestination.gog.rawValue == "GOG")
        #expect(FTLDestination.humble.rawValue == "Humble")
        #expect(FTLDestination.custom.rawValue == "Custom")
    }
}
