import Foundation

/// Parsed scan payload. Only well-formed HTTP/HTTPS URLs with a host are treated as web links;
/// everything else is plain text. The original payload is always preserved in `value`.
struct QRContent: Equatable, Sendable {
    let value: String
    let webURL: URL?

    var isWebURL: Bool { webURL != nil }
    var host: String? { webURL?.host }
    var title: String { host ?? "テキスト" }

    init(value: String) {
        self.value = value
        self.webURL = Self.parseWebURL(value)
    }

    private static let forbidden: CharacterSet = CharacterSet.whitespacesAndNewlines.union(.controlCharacters)

    private static func parseWebURL(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.unicodeScalars.allSatisfy({ !forbidden.contains($0) }),
              let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host, !host.isEmpty
        else {
            return nil
        }
        return components.url
    }
}
