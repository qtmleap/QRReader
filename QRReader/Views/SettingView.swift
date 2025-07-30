//
//  SettingView.swift
//  QRReader
//
//  Created by devonly on 2025/07/23.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import LicenseList
import QuantumLeap
import StoreKit
import SwiftUI

struct SettingView: View {
    var body: some View {
        Form(content: {
            QuantumLeap.Support()
            QuantumLeap.Policy()
            QuantumLeap.Version()
        })
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("設定")
    }
}

#Preview {
    NavigationView(content: {
        SettingView()
    })
}
