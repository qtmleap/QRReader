import SwiftUI

/// Production configuration is the standard defaults and the system camera.
/// DEBUG builds may be switched to isolated UI-test storage only by the explicit `-ui-testing` argument
/// (see `UITestSupport.swift`); Release builds contain none of that.
struct AppConfiguration {
    let defaults: UserDefaults
    let cameraProvider: CameraAuthorizationProviding
    let repeatSuppression: TimeInterval
    /// Only ever true for DEBUG `-ui-testing` launches.
    var usesMockCamera: Bool = false

    @MainActor
    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppConfiguration {
        #if DEBUG
        if let options = UITestingOptions(arguments: arguments) {
            return options.makeConfiguration()
        }
        #endif
        return AppConfiguration(
            defaults: .standard,
            cameraProvider: SystemCameraAuthorizationProvider(),
            repeatSuppression: 3
        )
    }
}

private struct UsesMockCameraKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var usesMockCamera: Bool {
        get { self[UsesMockCameraKey.self] }
        set { self[UsesMockCameraKey.self] = newValue }
    }
}
