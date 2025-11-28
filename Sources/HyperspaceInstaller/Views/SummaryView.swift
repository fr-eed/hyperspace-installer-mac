import SwiftUI

public struct SummaryView: View {
    @ObservedObject public var state: InstallationState

    public init(state: InstallationState) {
        self._state = ObservedObject(wrappedValue: state)
    }

    public var body: some View {
        VStack(spacing: 20) {
            successView

            Spacer()

            HStack(spacing: 12) {
                Button(action: {
                    if let ftlPath = state.selectedFTL?.path {
                        let ftlFolder = (ftlPath as NSString).deletingLastPathComponent
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: ftlFolder)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                        Text("Open FTL Folder")
                    }
                    .frame(maxWidth: .infinity)
                }

                Button(action: {
                    let ftlHyperspaceFolder = NSHomeDirectory() + "/Documents/FTLHyperspace"
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: ftlHyperspaceFolder)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                        Text("Open Mods Folder")
                    }
                    .frame(maxWidth: .infinity)
                }

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Text("Quit")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .frame(maxWidth: 500)
        .padding(30)
    }

    private var successView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Installation Complete")
                    .font(.system(size: 18, weight: .bold))

                Text("Hyperspace has been successfully installed!")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    infoItem(label: "FTL Version", value: state.selectedFTL?.version ?? "Unknown")
                    infoItem(label: "Installation Path", value: state.selectedFTL?.destination.rawValue ?? "Unknown")
                    infoItem(label: "Mod Files", value: "~/Documents/FTLHyperspace/")
                }
                .padding(12)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Next Steps")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 8) {
                    nextStepItem("Launch FTL normally - Hyperspace will be enabled")
                    nextStepItem("To add more mods, place .ftl files in ~/Documents/FTLHyperspace/mods/")
                    nextStepItem("Run: ~/Documents/FTLHyperspace/ftlman to patch additional mods")
                }
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(6)

            VStack(alignment: .leading, spacing: 8) {
                Text("Installation Log")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)

                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(state.installLog.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
                .frame(height: 120)
            }
        }
    }

    private func infoItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray)

            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }

    private func nextStepItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 12))

            Text(text)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func troubleItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 6))

            Text(text)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
