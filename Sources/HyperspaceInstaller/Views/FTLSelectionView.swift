import SwiftUI

public struct FTLSelectionView: View {
    @ObservedObject public var state: InstallationState
    @State private var isFilePickerShown = false

    public init(state: InstallationState) {
        self._state = ObservedObject(wrappedValue: state)
    }

    public var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Select FTL Installation")
                    .font(.system(size: 18, weight: .bold))

                Text("Choose your FTL installation location")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if state.detectedFTLPaths.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text("No FTL Installation Found")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Please select your FTL.app location manually")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)

                Button(action: { isFilePickerShown = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.questionmark")
                        Text("Browse for FTL.app")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Detected Installations")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)

                    VStack(spacing: 8) {
                        ForEach(state.detectedFTLPaths) { installation in
                            Button(action: {
                                state.selectedFTL = installation
                            }) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(installation.displayName)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.primary)

                                        Text(installation.path)
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    if state.selectedFTL == installation {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(
                                    state.selectedFTL == installation
                                        ? Color(.controlAccentColor).opacity(0.1)
                                        : Color(.controlBackgroundColor)
                                )
                                .cornerRadius(6)
                            }
                        }
                    }
                }

                Divider()

                Button(action: { isFilePickerShown = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder")
                        Text("Browse for Custom Location")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: {
                    state.isUninstalling = false
                    state.currentStep = .welcome
                }) {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)

                Button(action: {
                    if let ftl = state.selectedFTL {
                        let manager = InstallationManager.shared
                        if state.isUninstalling {
                            // For uninstall, check if Hyperspace is installed
                            if manager.isHyperspaceInstalled(ftl: ftl) {
                                state.nextStep()
                            } else {
                                state.showHyperspaceNotFoundAlert = true
                            }
                        } else {
                            // For install, show confirmation if already installed
                            if manager.isHyperspaceInstalled(ftl: ftl) {
                                state.showReinstallConfirmation = true
                            } else {
                                state.nextStep()
                            }
                        }
                    }
                }) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(state.selectedFTL == nil)
            }
        }
        .frame(maxWidth: 500)
        .padding(30)
        .fileImporter(
            isPresented: $isFilePickerShown,
            allowedContentTypes: [.application],
            onCompletion: { result in
                switch result {
                case .success(let url):
                    let path = url.path
                    if path.hasSuffix(".app") {
                        let detector = FTLDetector.shared
                        if let version = detector.readFTLVersion(from: path),
                           let dylibVersion = detector.validateVersion(version) {
                            let installation = FTLInstallation(
                                path: path,
                                destination: .custom,
                                version: version,
                                dylibVersion: dylibVersion
                            )

                            // Add to detected paths if not already there
                            if !state.detectedFTLPaths.contains(where: { $0.path == installation.path }) {
                                state.detectedFTLPaths.append(installation)
                            }

                            // Auto-select it
                            state.selectedFTL = installation
                        } else {
                            // TODO: Show error alert - invalid FTL version
                        }
                    }
                case .failure:
                    break
                }
            }
        )
        .alert("Hyperspace Already Installed", isPresented: $state.showReinstallConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reinstall") {
                state.nextStep()
            }
        } message: {
            Text("Hyperspace is already installed on this FTL installation. Do you want to reinstall it?")
        }
        .alert("Hyperspace Not Found", isPresented: $state.showHyperspaceNotFoundAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Hyperspace is not installed on this FTL installation. Uninstall is not possible.")
        }
        .onAppear {
            if !state.hasDetectedFTL {
                Task {
                    let detector = FTLDetector.shared
                    state.detectedFTLPaths = detector.detectFTLInstallations()
                    state.hasDetectedFTL = true
                }
            }
        }
    }
}
