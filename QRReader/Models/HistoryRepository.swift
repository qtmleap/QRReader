import Foundation

/// Persists scan history as a JSON string (the legacy `@AppStorage` raw value) in `UserDefaults`.
///
/// Stored data that cannot be decoded is never overwritten automatically: `hasLoadError` is set and
/// mutations are refused until `clear()` is called explicitly.
@MainActor
final class HistoryRepository {
    private(set) var items: [HistoryItem] = []
    private(set) var hasLoadError: Bool = false

    /// Newest first. Items with equal dates keep the most recently appended first.
    var sortedItems: [HistoryItem] {
        items.enumerated()
            .sorted { lhs, rhs in
                lhs.element.date != rhs.element.date
                    ? lhs.element.date > rhs.element.date
                    : lhs.offset > rhs.offset
            }
            .map(\.element)
    }

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults, key: String = "QR_HISTORY") {
        self.defaults = defaults
        self.key = key
        guard let raw = defaults.object(forKey: key) else {
            return
        }
        guard let string = raw as? String,
              let data = string.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data)
        else {
            hasLoadError = true
            return
        }
        items = decoded
    }

    /// Returns the stored item, or nil when persistence is refused or fails.
    @discardableResult
    func append(value: String, date: Date) -> HistoryItem? {
        guard !hasLoadError else {
            return nil
        }
        let item = HistoryItem(value: value, date: date)
        let updated = items + [item]
        guard commit(updated) else {
            return nil
        }
        return item
    }

    func remove(ids: Set<UUID>) {
        guard !hasLoadError, items.contains(where: { ids.contains($0.id) }) else {
            return
        }
        _ = commit(items.filter { !ids.contains($0.id) })
    }

    /// Explicitly empties history, also recovering from a load error.
    func clear() {
        if commit([]) {
            hasLoadError = false
        }
    }

    /// Mutable state changes only after the encoded value was written.
    private func commit(_ updated: [HistoryItem]) -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(updated),
              let string = String(data: data, encoding: .utf8)
        else {
            return false
        }
        defaults.set(string, forKey: key)
        items = updated
        return true
    }
}
