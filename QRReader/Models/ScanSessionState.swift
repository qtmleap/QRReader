import Foundation

/// Every condition that decides whether a scanner callback may be acted on.
struct ScanSessionState: Equatable, Sendable {
    var isScanTabVisible: Bool = true
    var isAppActive: Bool = true
    var isAuthorized: Bool = false
    var isOnboardingPresented: Bool = false
    var isSettingsPresented: Bool = false
    var hasResult: Bool = false
    var hasError: Bool = false

    var canScan: Bool {
        isScanTabVisible && isAppActive && isAuthorized
            && !isOnboardingPresented && !isSettingsPresented && !hasResult && !hasError
    }
}
