import Foundation

@MainActor
class InstallationState: ObservableObject {
    @Published var currentStep: InstallStep = .welcome
    @Published var detectedFTLPaths: [FTLInstallation] = []
    @Published var selectedFTL: FTLInstallation?
    @Published var isInstalling: Bool = false
    @Published var installProgress: Double = 0.0
    @Published var installLog: [String] = []
    @Published var installationError: String?
    @Published var installationSuccess: Bool = false
    @Published var showReinstallConfirmation: Bool = false
    @Published var hasDetectedFTL: Bool = false

    func addLog(_ message: String) {
        DispatchQueue.main.async {
            self.installLog.append("[\(self.timestamp())] \(message)")
        }
    }

    func setError(_ error: String) {
        DispatchQueue.main.async {
            self.installationError = error
            self.isInstalling = false
        }
    }

    func setSuccess() {
        DispatchQueue.main.async {
            self.installationSuccess = true
            self.isInstalling = false
        }
    }

    func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .ftlSelection
        case .ftlSelection:
            currentStep = .installing
        case .installing:
            currentStep = .summary
        case .summary:
            break
        }
    }

    func reset() {
        currentStep = .welcome
        detectedFTLPaths = []
        selectedFTL = nil
        isInstalling = false
        installProgress = 0.0
        installLog = []
        installationError = nil
        installationSuccess = false
        hasDetectedFTL = false
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}

enum InstallStep {
    case welcome
    case ftlSelection
    case installing
    case summary
}
