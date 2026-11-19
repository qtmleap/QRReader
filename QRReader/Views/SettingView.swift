//
//  SettingView.swift
//  QRReader
//
//  Created by devonly on 2025/07/23.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import QuantumLeap
import SwiftUI

/// Settings presented as a sheet from either tab.
struct SettingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                QuantumLeap.Support()
                QuantumLeap.Policy()
                QuantumLeap.Version()
            }
            .accessibilityIdentifier("settings.form")
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("settings.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.close") { dismiss() }
                        .frame(minWidth: AppMetrics.minTarget, minHeight: AppMetrics.minTarget)
                        .accessibilityIdentifier("settings.close")
                }
            }
        }
    }
}
