import SwiftUI

struct WelcomeView: View {
    @ObservedObject var state: InstallationState

    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Text("Hyperspace Installer")
                    .font(.system(size: 32, weight: .bold))

                Text("FTL: Faster Than Light Mod")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("This installer will:")
                    .font(.system(size: 14, weight: .semibold))

                VStack(alignment: .leading, spacing: 8) {
                    installItem("Detect your FTL installation")
                    installItem("Identify your FTL version")
                    installItem("Install Hyperspace mod files")
                    installItem("Patch the FTL data")
                    installItem("Configure your FTL.app")
                    installItem("Sign the application")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Requirements:")
                    .font(.system(size: 14, weight: .semibold))

                VStack(alignment: .leading, spacing: 4) {
                    requirementItem("FTL: Faster Than Light v1.6.12 or v1.6.13")
                    requirementItem("Administrator privileges")
                    requirementItem("Documents folder access (for mod manager)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            HStack(spacing: 12) {
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)

                Button(action: {
                    state.nextStep()
                }) {
                    Text("Start Installation")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: 500)
        .padding(30)
    }

    private func installItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 12))

            Text(text)
                .font(.system(size: 13))
        }
    }

    private func requirementItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 6))

            Text(text)
                .font(.system(size: 13))
        }
    }
}
