// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HyperspaceInstaller",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "HyperspaceInstaller",
            targets: ["HyperspaceInstaller"]
        )
    ],
    targets: [
        .executableTarget(
            name: "HyperspaceInstaller",
            dependencies: [],
            path: "Sources/HyperspaceInstaller"
        )
    ]
)
