//
//  FirstLaunchView.swift
//  QRReader
//
//  Created by devonly on 2025/07/25.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import SwiftUI

/// One-page introduction. The camera permission is requested only by the primary button,
/// and the intro completes whatever the answer is, so a denial leads to the permission-help panel.
struct FirstLaunchView: View {
    /// True while the system prompt can still be shown; changes only the button title.
    let willRequestCamera: Bool
    let requestCamera: () async -> Void
    let onComplete: () -> Void

    @State private var isWorking = false

    private let steps: [(symbol: String, title: LocalizedStringKey, detail: LocalizedStringKey)] = [
        ("qrcode.viewfinder", "intro.step1.title", "intro.step1.detail"),
        ("doc.text.magnifyingglass", "intro.step2.title", "intro.step2.detail"),
        ("square.and.arrow.up", "intro.step3.title", "intro.step3.detail"),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.067, green: 0.075, blue: 0.09).ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.appAccent)
                            .accessibilityHidden(true)
                        Text("intro.title")
                            .font(.largeTitle.weight(.bold))
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("intro.title")
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(steps.indices, id: \.self) { index in
                                HStack(alignment: .top, spacing: 16) {
                                    SymbolIcon(name: steps[index].symbol)
                                        .foregroundStyle(Color.appAccent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(steps[index].title).font(.headline)
                                        Text(steps[index].detail)
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.74))
                                    }
                                    .fixedSize(horizontal: false, vertical: true)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                        Text("intro.note")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.74))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(24)
                    .frame(maxWidth: 520, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                VStack(spacing: 8) {
                    Button(action: start, label: {
                        ActionLabel(title: willRequestCamera ? "intro.start.camera" : "intro.start", symbol: "camera")
                    })
                    .buttonStyle(.primaryAction)
                    .disabled(isWorking)
                    .accessibilityIdentifier("intro.start")
                    if willRequestCamera {
                        Text("intro.fine")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.74))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .frame(maxWidth: 520)
                .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
        }
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("intro.root")
    }

    private func start() {
        isWorking = true
        Task {
            await requestCamera()
            isWorking = false
            onComplete()
        }
    }
}
