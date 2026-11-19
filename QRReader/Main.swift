//
//  Main.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import FirebaseAppCheck
import FirebaseCore
import QuantumLeap
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        #if DEBUG
        // Development builds run without Firebase for UI tests or when the config file is not present.
        if UITestingOptions.isRequested || Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") == nil {
            return true
        }
        #endif
        #if DEBUG || targetEnvironment(simulator)
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #endif
        FirebaseApp.configure()
        return true
    }
}

@main
struct Main: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.appAccent)
                .environmentObject(model.store)
                .environmentObject(model.controller)
                .environmentObject(model.camera)
                .environment(\.usesMockCamera, model.configuration.usesMockCamera)
                .environmentIsFirstLaunch()
                // Outside the QuantumLeap provider so IS_FIRST_LAUNCH uses the same (possibly isolated) defaults.
                .defaultAppStorage(model.configuration.defaults)
        }
    }
}
