//
//  ScanView.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import CodeScanner
import QuantumLeap
import SwiftUI

/// Full-bleed camera screen. The scanner is mounted only when the intro is complete and camera access is
/// authorized; every callback goes through `ScanController.handleScan`, which applies `ScanSessionState.canScan`.
struct ScanView: View {
    let onOpenSettings: () -> Void

    @Environment(\.isFirstLaunch) private var isFirstLaunch: Binding<Bool>
    @Environment(\.usesMockCamera) private var usesMockCamera
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var controller: ScanController
    @EnvironmentObject private var camera: CameraAuthorizationModel
    @ScaledMetric(relativeTo: .title2) private var headerHeight: CGFloat = 36

    private let background = Color(red: 0.067, green: 0.075, blue: 0.09)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            cameraLayer
            if camera.state == .authorized && !isFirstLaunch.wrappedValue && !controller.scanFailed {
                LinearGradient(colors: [.black.opacity(0.65), .clear, .clear, .black.opacity(0.45)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 0) {
                ScreenHeader(title: "scan.title") {
                    IconButton(symbol: "gearshape", label: "settings.title", identifier: "scan.settings", action: onOpenSettings)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .tint(.white)
        }
        // Dark window while the camera is shown keeps the status bar and home indicator legible.
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var cameraLayer: some View {
        Group {
            if isFirstLaunch.wrappedValue {
                Color.clear
            } else if controller.scanFailed {
                StatePanel(symbol: "exclamationmark.triangle", title: "scan.failed.title", message: "scan.failed.message") {
                    Button(action: controller.retryScanner, label: {
                        ActionLabel(title: "scan.failed.retry", symbol: "arrow.clockwise")
                    })
                    .buttonStyle(.primaryAction)
                    .accessibilityIdentifier("scan.retry")
                }
                .foregroundStyle(.white)
                .accessibilityIdentifier("scan.failed")
            } else {
                switch camera.state {
                    case .authorized:
                        scanner
                    case .notDetermined:
                        StatePanel(symbol: "camera", title: "camera.notDetermined.title", message: "camera.notDetermined.message") {
                            Button(action: { Task { await camera.request() } }, label: {
                                ActionLabel(title: "camera.notDetermined.action", symbol: "camera")
                            })
                            .buttonStyle(.primaryAction)
                            .accessibilityIdentifier("scan.permission.request")
                        }
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("scan.permission.notDetermined")
                    case .denied:
                        StatePanel(symbol: "camera.fill", title: "camera.denied.title", message: "camera.denied.message") {
                            Button(action: openAppSettings, label: {
                                ActionLabel(title: "camera.denied.action", symbol: "gearshape")
                            })
                            .buttonStyle(.primaryAction)
                            .accessibilityIdentifier("scan.permission.openSettings")
                        }
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("scan.permission.denied")
                    case .restricted:
                        StatePanel(symbol: "nosign", title: "camera.restricted.title", message: "camera.restricted.message") { EmptyView() }
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("scan.permission.restricted")
                    case .unavailable:
                        StatePanel(symbol: "camera.fill", title: "camera.unavailable.title", message: "camera.unavailable.message") { EmptyView() }
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("scan.permission.unavailable")
                }
            }
        }
        .padding(.top, camera.state != .authorized || controller.scanFailed ? max(52, headerHeight) + 16 : 0)
    }

    @ViewBuilder
    private var scanner: some View {
        ZStack {
            #if DEBUG
            if usesMockCamera {
                MockCameraBackground().ignoresSafeArea()
            } else {
                liveScanner
            }
            #else
            liveScanner
            #endif
            VStack(spacing: 16) {
                Spacer(minLength: 0)
                Viewfinder()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .shadow(color: .black.opacity(0.7), radius: 1)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 240)
                    .layoutPriority(-1)
                    .opacity(controller.canScan ? 1 : 0.35)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
                Text("scan.hint")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)
                    .padding(.horizontal, 24)
                    .accessibilityIdentifier("scan.hint")
                #if DEBUG
                if usesMockCamera && !ProcessInfo.processInfo.arguments.contains("-ui-hide-controls") {
                    MockFixtureControls().padding(.bottom, 12)
                }
                #endif
            }
            .padding(.top, max(52, headerHeight) + 16)
            .padding(.bottom, 24)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("scan.camera")
    }

    private var liveScanner: some View {
        let generation = controller.scannerGeneration
        return CodeScannerView(
            codeTypes: [.qr],
            scanMode: .continuous,
            scanInterval: 1,
            showViewfinder: false,
            requiresPhotoOutput: false,
            isPaused: !controller.canScan,
            completion: { handle($0, generation: generation) }
        )
        .id(generation)
        .ignoresSafeArea()
    }

    private func handle(_ result: Result<ScanResult, ScanError>, generation: Int) {
        if case .failure(.permissionDenied) = result {
            camera.refresh()
            return
        }
        guard controller.accepts(generation: generation) else { return }
        switch result {
            case let .success(scan):
                controller.handleScan(scan.string, generation: generation)
            case .failure:
                controller.reportScannerFailure(generation: generation)
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

/// Four rounded white corner brackets.
struct Viewfinder: Shape {
    func path(in rect: CGRect) -> Path {
        let arm: CGFloat = 32
        let radius: CGFloat = 10
        var path = Path()
        for (sx, sy) in [(CGFloat(1), CGFloat(1)), (-1, 1), (1, -1), (-1, -1)] {
            let cx = sx > 0 ? rect.minX : rect.maxX
            let cy = sy > 0 ? rect.minY : rect.maxY
            path.move(to: CGPoint(x: cx, y: cy + sy * arm))
            path.addLine(to: CGPoint(x: cx, y: cy + sy * radius))
            path.addQuadCurve(to: CGPoint(x: cx + sx * radius, y: cy), control: CGPoint(x: cx, y: cy))
            path.addLine(to: CGPoint(x: cx + sx * arm, y: cy))
        }
        return path
    }
}
