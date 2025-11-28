import Foundation

public struct FTLInstallation: Identifiable, Equatable {
    public let id = UUID()
    public let path: String
    public let destination: FTLDestination
    public let version: String
    public let dylibVersion: String

    public init(path: String, destination: FTLDestination, version: String, dylibVersion: String) {
        self.path = path
        self.destination = destination
        self.version = version
        self.dylibVersion = dylibVersion
    }

    public var displayName: String {
        "\(destination.rawValue) - v\(version)"
    }

    public var ftlAppPath: String {
        path
    }

    public var ftlDataPath: String {
        "\(path)/Contents/Resources"
    }

    // Custom Equatable implementation - compare by path only
    public static func == (lhs: FTLInstallation, rhs: FTLInstallation) -> Bool {
        lhs.path == rhs.path
    }
}

public enum FTLDestination: String, Codable, Sendable {
    case steam = "Steam"
    case gog = "GOG"
    case humble = "Humble"
    case custom = "Custom"
}
