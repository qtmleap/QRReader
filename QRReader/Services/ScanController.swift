import Foundation
import SwiftUI

/// A result shown in the shared result sheet, from either a live scan or a history row.
struct PresentedResult: Identifiable, Equatable {
    let id = UUID()
    let content: QRContent
    let date: Date
    let isFromHistory: Bool
    let wasSaved: Bool
}

/// Owns scan gating. Scanner callbacks must go through `handleScan`, which checks `canScan`
/// synchronously before saving or presenting, so duplicate callbacks cannot create two results.
@MainActor
final class ScanController: ObservableObject {
    @Published var isScanTabVisible: Bool = true {
        didSet { if isScanTabVisible && !oldValue { scannerGeneration += 1 } }
    }
    @Published var isAppActive: Bool = true {
        didSet { if isAppActive && !oldValue { scannerGeneration += 1 } }
    }
    @Published var isAuthorized: Bool = false {
        didSet { if isAuthorized && !oldValue { scannerGeneration += 1 } }
    }
    @Published var isOnboardingPresented: Bool = false {
        didSet { if !isOnboardingPresented && oldValue { scannerGeneration += 1 } }
    }
    @Published var isSettingsPresented: Bool = false {
        didSet { if !isSettingsPresented && oldValue { scannerGeneration += 1 } }
    }
    @Published private(set) var scanFailed: Bool = false
    /// Changing this recreates the scanner view (after backgrounding or a failure).
    @Published private(set) var scannerGeneration: Int = 0

    @Published var result: PresentedResult? {
        didSet {
            if let closed = oldValue, result == nil {
                if !closed.isFromHistory {
                    lastClosed = (closed.content.value, Date())
                }
                scannerGeneration += 1
            }
        }
    }

    var session: ScanSessionState {
        ScanSessionState(
            isScanTabVisible: isScanTabVisible,
            isAppActive: isAppActive,
            isAuthorized: isAuthorized,
            isOnboardingPresented: isOnboardingPresented,
            isSettingsPresented: isSettingsPresented,
            hasResult: result != nil,
            hasError: scanFailed
        )
    }

    var canScan: Bool { session.canScan }

    private let store: HistoryStore
    private let repeatSuppression: TimeInterval
    private var lastClosed: (value: String, date: Date)?

    /// - Parameter repeatSuppression: seconds during which the payload of a just-closed scan result
    ///   is ignored, so a code still in front of the camera does not immediately reopen.
    init(store: HistoryStore, repeatSuppression: TimeInterval = 3) {
        self.store = store
        self.repeatSuppression = repeatSuppression
    }

    /// Single entry point for real scanner callbacks and DEBUG fixtures.
    @discardableResult
    func handleScan(_ payload: String, now: Date = Date(), generation: Int? = nil) -> Bool {
        guard accepts(generation: generation), !payload.isEmpty else {
            return false
        }
        if let lastClosed, lastClosed.value == payload, now.timeIntervalSince(lastClosed.date) < repeatSuppression {
            return false
        }
        let saved = store.append(value: payload, date: now) != nil
        result = PresentedResult(content: QRContent(value: payload), date: now, isFromHistory: false, wasSaved: saved)
        return true
    }

    func showHistoryItem(_ item: HistoryItem) {
        result = PresentedResult(content: QRContent(value: item.value), date: item.date, isFromHistory: true, wasSaved: true)
    }

    func reportScannerFailure(generation: Int? = nil) {
        guard accepts(generation: generation) else { return }
        scanFailed = true
    }

    func retryScanner() {
        scanFailed = false
        scannerGeneration += 1
    }

    func sceneChanged(_ phase: ScenePhase) {
        isAppActive = phase == .active
    }

    func accepts(generation: Int?) -> Bool {
        canScan && (generation == nil || generation == scannerGeneration)
    }
}
