import Foundation

@MainActor
public class InstallationState: ObservableObject {
    @Published public var currentStep: InstallStep = .welcome
    @Published public var detectedFTLPaths: [FTLInstallation] = []
    @Published public var selectedFTL: FTLInstallation?
    @Published public var isInstalling: Bool = false
    @Published public var installProgress: Double = 0.0
    @Published public var installLog: [String] = []
    @Published public var installationError: String?
    @Published public var installationSuccess: Bool = false
    @Published public var showReinstallConfirmation: Bool = false
    @Published public var hasDetectedFTL: Bool = false

    public init() {}

    public func addLog(_ message: String) {
        let logMessage = "[\(self.timestamp())] \(message)"
        self.installLog.append(logMessage)

        do {
            try LogManager.shared.appendLog(logMessage)
        } catch {
            // Silent fail - don't block installation if log write fails
        }
    }

    public func setError(_ error: String) {
        DispatchQueue.main.async {
            self.installationError = error
            self.isInstalling = false
        }
    }

    public func setSuccess() {
        DispatchQueue.main.async {
            self.installationSuccess = true
            self.isInstalling = false
        }
    }

    public func nextStep() {
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

    public func reset() {
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

public enum InstallStep {
    case welcome
    case ftlSelection
    case installing
    case summary
}
