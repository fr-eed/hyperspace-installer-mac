import SwiftUI

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
        alert.messageText = "Hyperspace Installer"

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        alert.informativeText = "FTL: Faster Than Light Mod Installer\n\nVersion \(version)\n\nDeveloped by Freed"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
