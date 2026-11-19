import Foundation

/// Shared observable wrapper around `HistoryRepository`; scan and history UI use the same instance.
@MainActor
final class HistoryStore: ObservableObject {
    /// Newest first.
    @Published private(set) var items: [HistoryItem] = []
    @Published private(set) var hasLoadError: Bool = false

    private let repository: HistoryRepository

    init(defaults: UserDefaults, key: String = "QR_HISTORY") {
        repository = HistoryRepository(defaults: defaults, key: key)
        publish()
    }

    @discardableResult
    func append(value: String, date: Date = Date()) -> HistoryItem? {
        let item = repository.append(value: value, date: date)
        publish()
        return item
    }

    func remove(id: UUID) {
        repository.remove(ids: [id])
        publish()
    }

    func clear() {
        repository.clear()
        publish()
    }

    private func publish() {
        items = repository.sortedItems
        hasLoadError = repository.hasLoadError
    }
}
