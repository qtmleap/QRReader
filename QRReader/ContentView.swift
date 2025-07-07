//
//  ContentView.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
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
        }
    }
}

#Preview {
    ContentView()
}
