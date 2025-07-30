//
//  HistoryView.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import SwiftUI

struct HistoryView: View {
    #if targetEnvironment(simulator)
    @AppStorage("QR_HISTORY") var items: [HistoryItem] = [
        .init(value: "https://qleap.jp", date: .init(timeIntervalSince1970: 1_735_657_200)),
        .init(value: "https://www.youtube.com", date: .init(timeIntervalSince1970: 1_735_657_200)),
        .init(value: "b2d521f0cb74160d70abc8b514506b80e5659757b0083df98a5221ea558b6ce6", date: .init(timeIntervalSince1970: 1_735_657_200)),
        .init(value: "https://bsky.app", date: .init(timeIntervalSince1970: 1_735_657_200)),
        .init(value: "https://blog.tkgstrator.work", date: .init(timeIntervalSince1970: 1_735_657_200)),
    ]
    #else
    @AppStorage("QR_HISTORY") var items: [HistoryItem] = []
    #endif

    func onDelete(offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    var body: some View {
        NavigationView(content: {
            List(content: {
                ForEach(items, content: { item in
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
                })
                .onDelete(perform: onDelete)
            })
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing, content: {
                    NavigationLink(destination: {
                        SettingView()
                    }, label: {
                        Image(systemName: "gearshape")
                    })
                })
                ToolbarItem(placement: .topBarLeading, content: {
                    Button(action: {
                        items.removeAll()
                    }, label: {
                        Image(systemName: "xmark.circle")
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
    HistoryView()
}
