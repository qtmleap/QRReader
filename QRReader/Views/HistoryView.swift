//
//  HistoryView.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import SwiftUI

struct HistoryView: View {
    @AppStorage("QR_HISTORY") var items: [HistoryItem] = []

    var body: some View {
        NavigationView(content: {
            List(items, id: \.id) { item in
                NavigationLink(destination: {
                    ResultView(result: item.value)
                }, label: {
                    VStack(alignment: .leading, content: {
                        Text(item.value)
                            .lineLimit(1)
                        Text(item.date, format: .dateTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    })
                })
            }
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing, content: {
                    NavigationLink(destination: {
                        SettingView()
                    }, label: {
                        Image(systemName: "gearshape")
                    })
                })
            })
            .listStyle(.plain)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("履歴")
        })
    }
}

#Preview {
    ContentView()
}
