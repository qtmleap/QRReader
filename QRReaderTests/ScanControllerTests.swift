import Foundation
import SwiftUI
import Testing

@testable import QRReader

@MainActor
struct ScanControllerTests {
    private func withController(_ body: (ScanController, HistoryStore, UserDefaults) -> Void) {
        let suite = "QRReader.ScanControllerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = HistoryStore(defaults: defaults)
        let controller = ScanController(store: store)
        controller.isAuthorized = true
        body(controller, store, defaults)
    }

    @Test func callbackBurstSavesOneResultThenDismissalAllowsNextPayload() {
        withController { controller, store, _ in
            #expect(controller.handleScan("https://example.com/first"))
            #expect(!controller.handleScan("second callback"))
            #expect(store.items.count == 1)
            #expect(controller.result?.content.value == "https://example.com/first")
            controller.result = nil
            #expect(controller.canScan)
            #expect(controller.handleScan("next QR code"))
            #expect(store.items.count == 2)
        }
    }

    @Test func settingsBlocksCallbacksAndDismissalRestoresScanning() {
        withController { controller, store, _ in
            controller.isSettingsPresented = true
            #expect(!controller.handleScan("behind settings"))
            #expect(store.items.isEmpty)
            controller.isSettingsPresented = false
            #expect(controller.handleScan("after settings"))
            #expect(store.items.count == 1)
        }
    }

    @Test func scannerFailureRequiresRetryBeforeAcceptingAnotherResult() {
        withController { controller, store, _ in
            controller.reportScannerFailure()
            #expect(!controller.handleScan("while failed"))
            #expect(store.items.isEmpty)
            let generation = controller.scannerGeneration
            controller.retryScanner()
            #expect(controller.scannerGeneration > generation)
            #expect(controller.handleScan("after retry"))
            #expect(store.items.count == 1)
        }
    }

    @Test func scannerFailureWhileSettingsIsOpenDoesNotBlockResumption() {
        withController { controller, _, _ in
            controller.isSettingsPresented = true
            controller.reportScannerFailure()
            #expect(!controller.scanFailed)
            controller.isSettingsPresented = false
            #expect(controller.canScan)
        }
    }

    @Test func oldScannerFailureAfterForegroundIsIgnored() {
        withController { controller, _, _ in
            let previous = controller.scannerGeneration
            controller.sceneChanged(.background)
            controller.sceneChanged(.active)
            controller.reportScannerFailure(generation: previous)
            #expect(!controller.scanFailed)
            #expect(controller.canScan)
        }
    }

    @Test func oldScannerSuccessAfterForegroundDoesNotSaveOrPresent() {
        withController { controller, store, _ in
            let previous = controller.scannerGeneration
            controller.sceneChanged(.background)
            controller.sceneChanged(.active)
            #expect(!controller.handleScan("stale callback", generation: previous))
            #expect(controller.result == nil)
            #expect(store.items.isEmpty)
            #expect(controller.handleScan("current callback", generation: controller.scannerGeneration))
        }
    }

    @Test func foregroundAfterBackgroundRecreatesScannerAndRestoresCallbacks() {
        withController { controller, store, _ in
            let generation = controller.scannerGeneration
            controller.sceneChanged(.background)
            #expect(!controller.handleScan("in background"))
            #expect(store.items.isEmpty)
            controller.sceneChanged(.active)
            #expect(controller.scannerGeneration > generation)
            #expect(controller.handleScan("in foreground"))
        }
    }

    @Test func historyPresentationPreservesPayloadAndDoesNotAppendAgain() {
        withController { controller, store, _ in
            let item = HistoryItem(value: "historical text", date: Date(timeIntervalSinceReferenceDate: 100))
            controller.showHistoryItem(item)
            #expect(controller.result?.content.value == item.value)
            #expect(controller.result?.date == item.date)
            #expect(controller.result?.isFromHistory == true)
            #expect(store.items.isEmpty)
            #expect(!controller.handleScan("behind history result"))
            controller.result = nil
            #expect(controller.canScan)
        }
    }

    @Test func justClosedCodeDoesNotImmediatelyReopenButCanBeReadLater() {
        withController { controller, store, _ in
            #expect(controller.handleScan("same code"))
            controller.result = nil
            let closed = Date()
            #expect(!controller.handleScan("same code", now: closed.addingTimeInterval(1)))
            #expect(store.items.count == 1)
            #expect(controller.handleScan("same code", now: closed.addingTimeInterval(4)))
            #expect(store.items.count == 2)
        }
    }
}
