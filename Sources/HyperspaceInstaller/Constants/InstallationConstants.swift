import Foundation

// MARK: - Supported Versions

enum SupportedFTLVersions {
    static let all = ["1.6.12", "1.6.13"]

    static func isSupported(_ version: String) -> Bool {
        all.contains(version)
    }
}

// MARK: - FTL Installation Locations

enum FTLInstallationLocations {
    static let commonPaths: [(path: String, destination: FTLDestination)] = [
 
        // Drag & drop installs
        ("/Applications/FTL Advanced Edition.app", .gog),
        ("/Applications/FTL.app", .gog),
        
        ("$HOME/Applications/FTL Advanced Edition.app", .gog),
        ("$HOME/Applications/FTL.app", .gog),

        // Launcher based installs
        ("$HOME/Library/Application Support/Steam/steamapps/common/FTL Faster Than Light/FTL.app", .steam),
        ("$HOME/Library/Application Support/GOG.com/Galaxy/Applications/FTL.app", .gog),
        ("/Users/Shared/Epic Games/FasterThanLight/FTL.app", .epic),
        ("$HOME/Games/Heroic/FasterThanLight/FTL.app", .heroic),
        ("$HOME/Games/Heroic/FTL Advanced Edition.app", .heroic)
    ]
}

// MARK: - Installation Paths

enum InstallationPaths {
    private static let baseDir = "Games/FTLHyperspace"

    static func baseDirectory(homeDirectory: String) -> String {
        "\(homeDirectory)/\(baseDir)"
    }

    static func modsDirectory(homeDirectory: String) -> String {
        "\(baseDirectory(homeDirectory: homeDirectory))/mods"
    }

    static func ftlmanPath(homeDirectory: String) -> String {
        "\(baseDirectory(homeDirectory: homeDirectory))/ftlman"
    }

    static func modFilePath(homeDirectory: String) -> String {
        "\(modsDirectory(homeDirectory: homeDirectory))/hyperspace.ftl"
    }

    static func configPath(homeDirectory: String) -> String {
        "\(baseDirectory(homeDirectory: homeDirectory))/settings.json"
    }

    static func logsDirectory(homeDirectory: String) -> String {
        "\(baseDirectory(homeDirectory: homeDirectory))/logs"
    }
}

// MARK: - Installation Constants

let INSTALLATION_STEPS_TOTAL: Double = 10

// MARK: - Error Types

public enum InstallationError: LocalizedError {
    case directoryCreationFailed(String)
    case fileCopyFailed(String)
    case configModificationFailed(String)
    case dylibNotFound(String)
    case scriptExecutionFailed(String)
    case gatekeeperBlocked
    case invalidFTLVersion(String)
    case configWriteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let path):
            return "Failed to create directory: \(path)"
        case .fileCopyFailed(let file):
            return "Failed to copy file: \(file)"
        case .configModificationFailed(let detail):
            return "Failed to modify configuration: \(detail)"
        case .dylibNotFound(let name):
            return "Dylib not found: \(name)"
        case .scriptExecutionFailed(let detail):
            return "Script execution failed: \(detail)"
        case .gatekeeperBlocked:
            return "ftlman is blocked by Gatekeeper"
        case .invalidFTLVersion(let version):
            return "FTL version \(version) is not supported (requires 1.6.12 or 1.6.13)"
        case .configWriteFailed(let detail):
            return "Failed to write configuration: \(detail)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .directoryCreationFailed:
            return "Check that you have write permissions to your Documents folder"
        case .fileCopyFailed:
            return "Ensure the source files exist and you have write permissions"
        case .configModificationFailed:
            return "Check that FTL.app is not in use"
        case .gatekeeperBlocked:
            return "Go to System Preferences > Security & Privacy and click 'Allow' for ftlman"
        case .invalidFTLVersion:
            return "Please install FTL: Faster Than Light version 1.6.13 or 1.6.12"
        default:
            return nil
        }
    }
}
