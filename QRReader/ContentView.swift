//
//  ContentView.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("IS_FIRST_LAUNCH") private var isFirstLaunch: Bool = true

    var body: some View {
        TabView(content: {
            ScanView()
                .tag(0)
                .tabItem {
                    Label("スキャン", systemImage: "qrcode.viewfinder")
                }
            HistoryView()
                .tag(1)
                .tabItem {
                    Label("履歴", systemImage: "clock")
                }
        })
        .sheet(isPresented: $isFirstLaunch, content: {
            FirstLaunchView()
                .interactiveDismissDisabled(true)
        })
    }
}

#Preview {
    ContentView()
}
