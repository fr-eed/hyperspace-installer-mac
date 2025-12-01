import SwiftUI

public struct UninstallView: View {
    @ObservedObject public var state: InstallationState

    public init(state: InstallationState) {
        self.state = state
    }

    public var body: some View {
        VStack(spacing: 20) {
            Text("Uninstalling Hyperspace")
                .font(.system(size: 18, weight: .semibold))

            ProgressView(value: state.installProgress)
                .frame(height: 8)

            VStack(alignment: .leading, spacing: 8) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(state.installLog, id: \.self) { logLine in
                            Text(logLine)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding(10)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }

            Spacer()

            HStack(spacing: 12) {
                if state.installationError != nil {
                    Button(action: {
                        state.currentStep = .welcome
                    }) {
                        Text("Back")
                            .frame(maxWidth: .infinity)
                    }
                } else if !state.installationSuccess {
                    Button(action: {
                        state.currentStep = .welcome
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                    }
                    .keyboardShortcut(.cancelAction)
                } else {
                    Button(action: {
                        state.currentStep = .welcome
                    }) {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: 500)
        .padding(30)
        .onAppear {
            performUninstall()
        }
    }

    private func performUninstall() {
        guard let selectedFTL = state.selectedFTL else {
            state.setError("No FTL installation selected")
            return
        }

        Task {
            await InstallationManager.shared.uninstallHyperspace(ftl: selectedFTL, state: state)
        }
    }
}
