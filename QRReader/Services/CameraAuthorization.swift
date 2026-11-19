import AVFoundation
import Foundation

/// Explicit camera states the UI distinguishes between.
enum CameraAuthorization: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable
}

@MainActor
protocol CameraAuthorizationProviding: AnyObject {
    func currentState() -> CameraAuthorization
    /// Returns whether access was granted. Must only be called from an explicit user action.
    func requestAccess() async -> Bool
}

@MainActor
final class SystemCameraAuthorizationProvider: CameraAuthorizationProviding {
    func currentState() -> CameraAuthorization {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .restricted:
                return .restricted
            case .denied:
                return .denied
            case .authorized:
                return AVCaptureDevice.default(for: .video) == nil ? .unavailable : .authorized
            case .notDetermined:
                // Never prompt on hardware without a camera.
                return AVCaptureDevice.default(for: .video) == nil ? .unavailable : .notDetermined
            @unknown default:
                return .unavailable
        }
    }

    func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}

/// Observable camera state. Refresh on launch, foreground, and after the explicit permission request.
@MainActor
final class CameraAuthorizationModel: ObservableObject {
    @Published private(set) var state: CameraAuthorization

    private let provider: CameraAuthorizationProviding

    init(provider: CameraAuthorizationProviding) {
        self.provider = provider
        self.state = provider.currentState()
    }

    func refresh() {
        let latest = provider.currentState()
        if latest != state {
            state = latest
        }
    }

    /// Shows the system prompt only while the status is undetermined.
    func request() async {
        guard provider.currentState() == .notDetermined else {
            refresh()
            return
        }
        _ = await provider.requestAccess()
        refresh()
    }
}
