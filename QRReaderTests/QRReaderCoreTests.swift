import Foundation
import Testing

#if SWIFT_PACKAGE
@testable import QRReaderCore
#else
@testable import QRReader
#endif

// MARK: - QRContent

struct QRContentTests {
    @Test(arguments: [
        "https://example.com",
        "http://example.com/path?q=1#frag",
        "HTTPS://EXAMPLE.COM/Path",
        "HtTp://Example.com:8080/a/b",
        "https://example.com:443",
    ])
    func acceptsHTTPAndHTTPS(_ value: String) {
        let content = QRContent(value: value)
        #expect(content.isWebURL)
        #expect(content.webURL != nil)
        #expect(content.title != "テキスト")
        #expect(content.value == value)
    }

    @Test func trimsSurroundingWhitespaceButPreservesPayload() {
        let value = "  https://example.com/a \n"
        let content = QRContent(value: value)
        #expect(content.webURL?.absoluteString == "https://example.com/a")
        #expect(content.value == value)
    }

    @Test func preservesLongPayloadWithQuery() {
        let value = "https://example.com/?" + String(repeating: "a=b&", count: 500)
        let content = QRContent(value: value)
        #expect(content.isWebURL)
        #expect(content.value == value)
    }

    @Test(arguments: [
        "hello world",
        "",
        "ftp://example.com",
        "mailto:a@example.com",
        "javascript:alert(1)",
        "tel:+810000000000",
        "file:///etc/passwd",
        "myapp://open?x=1",
        "http://",
        "https:///path",
        "https://exa mple.com",
        "https://example.com/a b",
        "example.com",
    ])
    func rejectsNonWebPayloads(_ value: String) {
        let content = QRContent(value: value)
        #expect(!content.isWebURL)
        #expect(content.webURL == nil)
        #expect(content.title == "テキスト")
        #expect(content.value == value)
    }
}

// MARK: - HistoryRepository

@MainActor
struct HistoryRepositoryTests {
    private func withDefaults(_ body: (UserDefaults) throws -> Void) rethrows {
        let name = "QRReaderCoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults)
    }

    @Test func loadsHandwrittenLegacyJSON() {
        withDefaults { defaults in
            let id = UUID()
            let json = """
            [{"id":"\(id.uuidString)","value":"legacy","date":760000000}]
            """
            defaults.set(json, forKey: "QR_HISTORY")
            let repo = HistoryRepository(defaults: defaults)
            #expect(!repo.hasLoadError)
            #expect(repo.items.count == 1)
            #expect(repo.items.first?.id == id)
            #expect(repo.items.first?.value == "legacy")
            #expect(repo.items.first?.date == Date(timeIntervalSinceReferenceDate: 760000000))
        }
    }

    @Test func appendPersistsAndRoundTrips() {
        withDefaults { defaults in
            let date = Date(timeIntervalSinceReferenceDate: 1000)
            let repo = HistoryRepository(defaults: defaults)
            let item = repo.append(value: "a", date: date)
            #expect(item?.value == "a")

            let reloaded = HistoryRepository(defaults: defaults)
            #expect(reloaded.items.count == 1)
            #expect(reloaded.items.first?.id == item?.id)
            #expect(reloaded.items.first?.date == date)
            #expect(reloaded.items.first?.value == "a")
        }
    }

    @Test func sortedItemsAreNewestFirst() {
        withDefaults { defaults in
            let repo = HistoryRepository(defaults: defaults)
            repo.append(value: "old", date: Date(timeIntervalSinceReferenceDate: 1))
            repo.append(value: "new", date: Date(timeIntervalSinceReferenceDate: 3))
            repo.append(value: "mid", date: Date(timeIntervalSinceReferenceDate: 2))
            #expect(repo.sortedItems.map(\.value) == ["new", "mid", "old"])
        }
    }

    @Test func sameDateOrderIsStable() {
        withDefaults { defaults in
            let date = Date(timeIntervalSinceReferenceDate: 5)
            let repo = HistoryRepository(defaults: defaults)
            repo.append(value: "first", date: date)
            repo.append(value: "second", date: date)
            repo.append(value: "third", date: date)
            let once = repo.sortedItems.map(\.value)
            #expect(once == repo.sortedItems.map(\.value))
            #expect(Set(once) == ["first", "second", "third"])
            let reloaded = HistoryRepository(defaults: defaults)
            #expect(reloaded.sortedItems.map(\.value) == once)
        }
    }

    @Test func removeDeletesOnlyMatchingUUIDAmongIdenticalValues() throws {
        try withDefaults { defaults in
            let date = Date(timeIntervalSinceReferenceDate: 9)
            let repo = HistoryRepository(defaults: defaults)
            let a = repo.append(value: "same", date: date)
            let b = repo.append(value: "same", date: date)
            let first = try #require(a)
            let second = try #require(b)
            #expect(first.id != second.id)
            repo.remove(ids: [first.id])
            #expect(repo.items.map(\.id) == [second.id])
            #expect(HistoryRepository(defaults: defaults).items.map(\.id) == [second.id])
        }
    }

    @Test func corruptJSONIsPreservedAndAppendRefused() {
        withDefaults { defaults in
            let corrupt = "{not json"
            defaults.set(corrupt, forKey: "QR_HISTORY")
            let repo = HistoryRepository(defaults: defaults)
            #expect(repo.hasLoadError)
            #expect(repo.items.isEmpty)
            #expect(repo.append(value: "x", date: .now) == nil)
            #expect(defaults.string(forKey: "QR_HISTORY") == corrupt)
        }
    }

    @Test func explicitClearThenAppendRecovers() {
        withDefaults { defaults in
            defaults.set("{not json", forKey: "QR_HISTORY")
            let repo = HistoryRepository(defaults: defaults)
            repo.clear()
            #expect(!repo.hasLoadError)
            #expect(repo.items.isEmpty)
            #expect(repo.append(value: "ok", date: .now) != nil)
            #expect(HistoryRepository(defaults: defaults).items.map(\.value) == ["ok"])
        }
    }

    @Test func customKeyIsolatesStorage() {
        withDefaults { defaults in
            let repo = HistoryRepository(defaults: defaults, key: "OTHER")
            repo.append(value: "x", date: .now)
            #expect(HistoryRepository(defaults: defaults).items.isEmpty)
            #expect(HistoryRepository(defaults: defaults, key: "OTHER").items.count == 1)
        }
    }
}

// MARK: - ScanSessionState

struct ScanSessionStateTests {
    private func ready() -> ScanSessionState {
        var state = ScanSessionState()
        state.isAuthorized = true
        return state
    }

    @Test func defaults() {
        let state = ScanSessionState()
        #expect(state.isScanTabVisible)
        #expect(state.isAppActive)
        #expect(!state.isAuthorized)
        #expect(!state.isOnboardingPresented)
        #expect(!state.isSettingsPresented)
        #expect(!state.hasResult)
        #expect(!state.hasError)
    }

    @Test func authorizedVisibleActiveCanScan() {
        #expect(ready().canScan)
    }

    @Test func unauthorizedCannotScan() {
        #expect(!ScanSessionState().canScan)
    }

    @Test func clearingEachPositiveGateBlocks() {
        var hidden = ready()
        hidden.isScanTabVisible = false
        #expect(!hidden.canScan)

        var inactive = ready()
        inactive.isAppActive = false
        #expect(!inactive.canScan)
    }

    @Test func raisingEachBlockingFlagBlocks() {
        var onboarding = ready()
        onboarding.isOnboardingPresented = true
        #expect(!onboarding.canScan)

        var settings = ready()
        settings.isSettingsPresented = true
        #expect(!settings.canScan)

        var result = ready()
        result.hasResult = true
        #expect(!result.canScan)

        var error = ready()
        error.hasError = true
        #expect(!error.canScan)
    }

    @Test func presentedResultBlocksNewCallbacksUntilCleared() {
        var state = ready()
        state.hasResult = true
        #expect(!state.canScan)
        state.hasResult = false
        #expect(state.canScan)
    }
}
