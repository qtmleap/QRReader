//
//  ContentView.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import QuantumLeap
import SwiftUI

struct ContentView: View {
    @Environment(\.isFirstLaunch) private var isFirstLaunch: Binding<Bool>
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var controller: ScanController
    @EnvironmentObject private var camera: CameraAuthorizationModel

    @State private var tab: AppTab = .scan
    /// Drives the intro cover. Lags `isFirstLaunch` while the settings sheet is still dismissing.
    @State private var isIntroPresented = false
    #if DEBUG
    @State private var didPresentLaunchFixture = false
    #endif

    var body: some View {
        Group {
            switch tab {
                case .scan:
                    ScanView(onOpenSettings: { controller.isSettingsPresented = true })
                case .history:
                    HistoryView(onOpenSettings: { controller.isSettingsPresented = true }, onGoToScan: { selectedTab.wrappedValue = .scan })
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppTabBar(selection: selectedTab, overCamera: tab == .scan)
        }
        .sheet(item: $controller.result) { result in
            ResultSheet(result: result)
        }
        .sheet(isPresented: $controller.isSettingsPresented, onDismiss: presentIntroIfNeeded) {
            SettingView()
        }
        .fullScreenCover(isPresented: $isIntroPresented) {
            FirstLaunchView(
                willRequestCamera: camera.state == .notDetermined,
                requestCamera: { await camera.request() },
                onComplete: {
                    camera.refresh()
                    isFirstLaunch.wrappedValue = false
                }
            )
        }
        .onAppear {
            controller.isOnboardingPresented = isFirstLaunch.wrappedValue
            controller.isAuthorized = camera.state == .authorized
            controller.sceneChanged(scenePhase)
            isIntroPresented = isFirstLaunch.wrappedValue
            presentLaunchFixtureIfNeeded()
        }
        .onChange(of: isFirstLaunch.wrappedValue) { isFirst in
            controller.isOnboardingPresented = isFirst
            if isFirst {
                // Support's "how to use" turns this on while settings may be open: close settings first.
                if controller.isSettingsPresented {
                    controller.isSettingsPresented = false
                } else {
                    isIntroPresented = true
                }
            } else {
                isIntroPresented = false
                camera.refresh()
            }
        }
        .onChange(of: camera.state) { state in
            controller.isAuthorized = state == .authorized
            presentLaunchFixtureIfNeeded()
        }
        .onChange(of: scenePhase) { phase in
            controller.sceneChanged(phase)
            if phase == .active {
                camera.refresh()
                presentLaunchFixtureIfNeeded()
            }
        }
    }

    private func presentLaunchFixtureIfNeeded() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard UITestingOptions.isRequested, !didPresentLaunchFixture, controller.canScan,
              let index = arguments.firstIndex(of: "-ui-initial-result"), arguments.indices.contains(index + 1),
              let fixture = ScanFixture(rawValue: arguments[index + 1]) else { return }
        didPresentLaunchFixture = true
        for payload in fixture.payloads { controller.handleScan(payload) }
        #endif
    }

    private var selectedTab: Binding<AppTab> {
        Binding(get: { tab }, set: { selection in
            controller.isScanTabVisible = selection == .scan
            tab = selection
        })
    }

    private func presentIntroIfNeeded() {
        if isFirstLaunch.wrappedValue {
            isIntroPresented = true
        }
    }
}
