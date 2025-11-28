import Foundation

struct FTLInstallation: Identifiable, Equatable {
    let id = UUID()
    let path: String
    let destination: FTLDestination
    let version: String
    let dylibVersion: String

    var displayName: String {
        "\(destination.rawValue) - v\(version)"
    }

    var ftlAppPath: String {
        path
    }

    var ftlDataPath: String {
        "\(path)/Contents/Resources"
    }

    // Custom Equatable implementation - compare by path only
    static func == (lhs: FTLInstallation, rhs: FTLInstallation) -> Bool {
        lhs.path == rhs.path
    }
}

enum FTLDestination: String, Codable {
    case steam = "Steam"
    case gog = "GOG"
    case humble = "Humble"
    case custom = "Custom"
}
