import Foundation

public struct AppInfo {
    public static var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Hyperspace Installer"
    }

    // Installer executable version (read from VERSION file at compile time)
    public static var version: String {
        InstallerVersion.version
    }

    // Installer bundle version (from plist, set during build)
    public static var bundleVersion: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    }

    // ftlman dependency version
    public static var ftlmanVersion: String {
        Bundle.main.infoDictionary?["FTLManVersion"] as? String ?? "unknown"
    }

    // Hyperspace dependency version
    public static var hyperspaceVersion: String {
        Bundle.main.infoDictionary?["HyperspaceVersion"] as? String ?? "unknown"
    }
}
