import SwiftUI

public struct InstallationView: View {
    @ObservedObject public var state: InstallationState
    @State private var resourcePath: String = ""

    public init(state: InstallationState) {
        self._state = ObservedObject(wrappedValue: state)
    }

    public var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Installing \(AppInfo.appName)")
                    .font(.system(size: 18, weight: .bold))

                if let ftl = state.selectedFTL {
                    Text("Installing for \(ftl.displayName)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Progress indicator
            VStack(spacing: 8) {
                ProgressView(value: state.installProgress)
                    .tint(.green)

                Text("\(Int(state.installProgress * 100))%")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            // Installation log
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(state.installLog.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(line)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
                .onChange(of: state.installLog.count) { _ in
                    if let lastLog = state.installLog.last {
                        reader.scrollTo(lastLog, anchor: .bottom)
                    }
                }
            }
            .frame(minHeight: 150)

            Spacer()

            if state.installationError != nil {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Installation failed")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(state.installationError ?? "Unknown error")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }

            HStack(spacing: 12) {
                if state.isInstalling {
                    Button(action: { /* Cancel not implemented yet */ }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(true)
                } else {
                    Button(action: { state.currentStep = .ftlSelection }) {
                        Text("Back")
                            .frame(maxWidth: .infinity)
                    }
                    .keyboardShortcut(.cancelAction)

                    Button(action: {
                        if state.installationSuccess {
                            state.nextStep()
                        } else {
                            state.currentStep = .ftlSelection
                        }
                    }) {
                        Text(state.installationSuccess ? "Continue" : "Try Again")
                            .frame(maxWidth: .infinity)
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: 600)
        .padding(30)
        .onAppear {
            if state.isInstalling == false {
                startInstallation()
            }
        }
    }

    private func startInstallation() {
        guard let ftl = state.selectedFTL else { return }

        // Get the resource path from the app bundle
        let bundleResourcePath = Bundle.main.bundlePath + "/Contents/Resources"

        Task {
            let manager = InstallationManager.shared
            await manager.installHyperspace(ftl: ftl, state: state, resourcePath: bundleResourcePath)
        }
    }
}
