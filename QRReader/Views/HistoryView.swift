//
//  HistoryView.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
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
            .listStyle(.plain)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("履歴")
        })
    }
}

#Preview {
    ContentView()
}
