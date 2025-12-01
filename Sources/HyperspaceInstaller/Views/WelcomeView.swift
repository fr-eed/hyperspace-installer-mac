import SwiftUI

public struct WelcomeView: View {
    @ObservedObject public var state: InstallationState
    @State private var modsList: [String] = []

    public init(state: InstallationState) {
        self.state = state
    }

    public var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(AppInfo.appName + " Installer")
                        .font(.system(size: 28, weight: .bold))

                    Text("\(AppInfo.bundleVersion)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }

                Text("FTL: Faster Than Light Mod")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("This installer will:")
                    .font(.system(size: 13, weight: .semibold))

                VStack(alignment: .leading, spacing: 4) {
                    installItem("Detect your FTL installation")
                    installItem("Identify your FTL version")
                    installItem("Install Hyperspace dynamic library")
                    installItem("Patch the FTL data")
                    installItem("Configure your FTL.app")
                    installItem("Sign the application")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            if !modsList.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mods:")
                        .font(.system(size: 13, weight: .semibold))

                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(modsList, id: \.self) { mod in
                            modItem(mod)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Dependencies:")
                    .font(.system(size: 13, weight: .semibold))

                VStack(alignment: .leading, spacing: 3) {
                    depItem("ftlman", AppInfo.ftlmanVersion)
                    depItem("Hyperspace", AppInfo.hyperspaceVersion)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 6) {
                Text("Requirements:")
                    .font(.system(size: 13, weight: .semibold))

                VStack(alignment: .leading, spacing: 2) {
                    requirementItem("FTL: Faster Than Light v1.6.12 or v1.6.13")
                    requirementItem("Administrator privileges")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
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
        .onAppear {
            modsList = readModsList()
        }
    }

    private func readModsList() -> [String] {
        do {
            return try InstallationManager.shared.readModsList()
        } catch {
            return []
        }
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

    private func modItem(_ modName: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "square.fill")
                .foregroundColor(.purple)
                .font(.system(size: 6))

            Text(modName)
                .font(.system(size: 13))
        }
    }

    private func depItem(_ name: String, _ version: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "gear")
                .foregroundColor(.orange)
                .font(.system(size: 11))

            Text("\(name)")
                .font(.system(size: 13))

            Spacer()

            Text(version)
                .font(.system(size: 11))
                .foregroundColor(.gray)
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
