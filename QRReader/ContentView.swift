//
//  ContentView.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import SwiftUI
import QuantumLeap

struct ContentView: View {
    @Environment(\.isFirstLaunch) private var isFirstLaunch: Binding<Bool>
    
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
        .sheet(isPresented: isFirstLaunch, content: {
            FirstLaunchView()
                .interactiveDismissDisabled(true)
        })
    }
}

#Preview {
    ContentView()
}
