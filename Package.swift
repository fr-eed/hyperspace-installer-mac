// swift-tools-version: 6.0
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
        ),
        .library(
            name: "HyperspaceInstallerLib",
            targets: ["HyperspaceInstallerLib"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "6.2.1")
    ],
    targets: [
        .target(
            name: "HyperspaceInstallerLib",
            dependencies: [],
            path: "Sources/HyperspaceInstaller"
        ),
        .executableTarget(
            name: "HyperspaceInstaller",
            dependencies: ["HyperspaceInstallerLib"],
            path: "Sources/HyperspaceInstallerApp"
        ),
        .testTarget(
            name: "HyperspaceInstallerTests",
            dependencies: [
                "HyperspaceInstallerLib",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/HyperspaceInstallerTests"
        )
    ],
)
