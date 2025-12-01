import SwiftUI
import HyperspaceInstallerLib

@main
struct HyperspaceInstallerApp: App {
    @StateObject private var state = InstallationState()

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(.windowBackgroundColor)
                    .ignoresSafeArea()

                Group {
                    switch state.currentStep {
                    case .welcome:
                        WelcomeView(state: state)
                    case .ftlSelection:
                        FTLSelectionView(state: state)
                    case .installing:
                        InstallationView(state: state)
                    case .uninstalling:
                        UninstallView(state: state)
                    case .summary:
                        SummaryView(state: state)
                    }
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 700)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(action: {
                    showAboutWindow()
                }) {
                    Text("About Hyperspace Installer")
                }
            }
        }
    }

    private func showAboutWindow() {
        let alert = NSAlert()
        alert.messageText = AppInfo.appName

        let installerVersion = AppInfo.version
        let bundleVersion = AppInfo.bundleVersion
        alert.informativeText = "FTL: Faster Than Light Mod Installer\n\nInstaller \(installerVersion)\nBundle \(bundleVersion)\n\nInstaller Developed by Freed"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
