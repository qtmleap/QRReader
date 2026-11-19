#if DEBUG
import SwiftUI

/// DEBUG-only UI-test launch configuration. Nothing here is active unless `-ui-testing` is passed.
///
/// Launch arguments:
/// - `-ui-testing`          isolated UserDefaults suite `UITestingOptions.suiteName` and a mock camera.
/// - `-reset-state`         wipe that suite first (history and IS_FIRST_LAUNCH).
/// - `-skip-onboarding`     persist IS_FIRST_LAUNCH = false.
/// - `-ui-seed-history`     store the three `UITestingOptions.seedHistory` entries.
/// - `-ui-initial-result <fixture>` show a fixture through the normal scan handler once active.
/// - `-ui-hide-controls`    hide fixture buttons in screenshot captures (mock camera only).
/// - `-ui-camera <state>`   `authorized` (default), `notDetermined` (prompt grants), `notDeterminedDeny`
///                          (prompt denies), `denied`, `restricted`, `unavailable`.
///
/// Fixture buttons on the mock camera (identifiers `ui.fixture.url|text|long|burst`) call
/// `ScanController.handleScan`, the same path as real scanner callbacks.
struct UITestingOptions {
    static let flag = "-ui-testing"
    static let suiteName = "jp.qleap.qrreader.ui-testing"

    let resetState: Bool
    let skipOnboarding: Bool
    let seedHistory: Bool
    let camera: String

    /// Used before UIKit/SwiftUI start, e.g. by the app delegate to skip Firebase.
    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains(flag)
    }

    init?(arguments: [String]) {
        guard arguments.contains(Self.flag) else {
            return nil
        }
        resetState = arguments.contains("-reset-state")
        skipOnboarding = arguments.contains("-skip-onboarding")
        seedHistory = arguments.contains("-ui-seed-history")
        if let index = arguments.firstIndex(of: "-ui-camera"), arguments.indices.contains(index + 1) {
            camera = arguments[index + 1]
        } else {
            camera = "authorized"
        }
    }

    static let seedEntries: [(value: String, date: Date)] = [
        ("https://qleap.jp", Date(timeIntervalSinceReferenceDate: 780_000_300)),
        ("Seed text line one\nSeed text line two", Date(timeIntervalSinceReferenceDate: 780_000_200)),
        ("https://example.com/seed", Date(timeIntervalSinceReferenceDate: 780_000_100)),
    ]

    @MainActor
    func makeConfiguration() -> AppConfiguration {
        guard let defaults = UserDefaults(suiteName: Self.suiteName) else {
            fatalError("Unable to create isolated UI-test storage")
        }
        if resetState {
            defaults.removePersistentDomain(forName: Self.suiteName)
        }
        if skipOnboarding {
            defaults.set(false, forKey: "IS_FIRST_LAUNCH")
        }
        if seedHistory {
            let repository = HistoryRepository(defaults: defaults)
            for entry in Self.seedEntries {
                repository.append(value: entry.value, date: entry.date)
            }
        }
        return AppConfiguration(
            defaults: defaults,
            cameraProvider: MockCameraProvider(option: camera),
            repeatSuppression: 3,
            usesMockCamera: true
        )
    }
}

@MainActor
final class MockCameraProvider: CameraAuthorizationProviding {
    private var state: CameraAuthorization
    private let grantsAccess: Bool

    init(option: String) {
        switch option {
            case "notDetermined":
                state = .notDetermined
                grantsAccess = true
            case "notDeterminedDeny":
                state = .notDetermined
                grantsAccess = false
            case "denied":
                state = .denied
                grantsAccess = false
            case "restricted":
                state = .restricted
                grantsAccess = false
            case "unavailable":
                state = .unavailable
                grantsAccess = false
            default:
                state = .authorized
                grantsAccess = true
        }
    }

    func currentState() -> CameraAuthorization { state }

    func requestAccess() async -> Bool {
        state = grantsAccess ? .authorized : .denied
        return grantsAccess
    }
}

enum ScanFixture: String, CaseIterable {
    case url, text, long, burst

    var payloads: [String] {
        switch self {
            case .url:
                return ["https://example.com/qrreader/fixture?id=1"]
            case .text:
                return ["QRReader fixture text\nsecond line"]
            case .long:
                let host = String(repeating: String(repeating: "a", count: 45) + ".", count: 3) + "example.com"
                return ["https://" + host + "/long?" + (1...120).map { "key\($0)=value\($0)" }.joined(separator: "&")]
            case .burst:
                // Two scanner callbacks in the same turn; only the first may be accepted.
                return ["https://example.com/qrreader/burst-first", "burst second payload"]
        }
    }

    var title: String { rawValue.capitalized }
}

/// Stand-in for the camera preview in UI tests.
struct MockCameraBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(white: 0.35), Color(white: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .accessibilityHidden(true)
    }
}

/// Fixture buttons plus a `scan.status` element whose value is `ready` or `paused` (`ScanController.canScan`).
struct MockFixtureControls: View {
    @EnvironmentObject private var controller: ScanController

    var body: some View {
        VStack(spacing: 4) {
            Text("Mock camera")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.74))
                .accessibilityIdentifier("scan.status")
                .accessibilityValue(controller.canScan ? "ready" : "paused")
            HStack(spacing: 8) {
                ForEach(ScanFixture.allCases, id: \.self) { fixture in
                    Button(fixture.title) {
                        for payload in fixture.payloads {
                            controller.handleScan(payload)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .frame(minWidth: AppMetrics.minTarget, minHeight: AppMetrics.minTarget)
                    .accessibilityIdentifier("ui.fixture.\(fixture.rawValue)")
                }
            }
        }
        .font(.footnote)
    }
}
#endif
