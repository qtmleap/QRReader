import SwiftUI

/// Composition root: one history store, one scan controller and one camera model for the whole app.
@MainActor
final class AppModel: ObservableObject {
    let configuration: AppConfiguration
    let store: HistoryStore
    let controller: ScanController
    let camera: CameraAuthorizationModel

    init(configuration: AppConfiguration = .make()) {
        self.configuration = configuration
        store = HistoryStore(defaults: configuration.defaults)
        controller = ScanController(store: store, repeatSuppression: configuration.repeatSuppression)
        camera = CameraAuthorizationModel(provider: configuration.cameraProvider)
    }
}
