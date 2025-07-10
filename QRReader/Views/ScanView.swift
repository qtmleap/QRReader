//
//  ScanView.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import SwiftUI

struct ScanView: View {
    @AppStorage("QR_HISTORY") var items: [HistoryItem] = []
    @State private var isPresented: Bool = false
    @State private var isURL: Bool = false
    @State private var result: String = ""

    var body: some View {
        QRCodeView()
            .onReceive(NotificationCenter.default.publisher(for: .AVCaptureMetadataOoutputDetected), perform: { notification in
                if let stringValue: String = notification.object as? String {
                    result = stringValue
                    items.append(.init(value: stringValue, date: .now))
                }
                if let stringValue: String = notification.object as? String,
                   let url: URL = .init(string: stringValue)
                {
                    isURL = UIApplication.shared.canOpenURL(url)
                } else {
                    isPresented.toggle()
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
                // アラートが表示されていない状態であればカメラを再起動
                if !isURL {
                    NotificationCenter.default.post(name: .AVCaptureResumeScan, object: nil)
                }
            })
            .sheet(isPresented: $isPresented, onDismiss: {
                NotificationCenter.default.post(name: .AVCaptureResumeScan, object: nil)
            }, content: {
                NavigationView(content: {
                    ResultView(result: result)
                })
            })
            .onAppear(perform: {
                // 初めて表示されたときにカメラを再起動(多分不要)
                NotificationCenter.default.post(name: .AVCaptureResumeScan, object: nil)
            })
            .alert("このURLを開きますか？", isPresented: $isURL, actions: {
                Button(role: .cancel, action: {
                    NotificationCenter.default.post(name: .AVCaptureResumeScan, object: nil)
                }, label: {
                    Text("いいえ")
                })
                Button(action: {
                    if let url: URL = .init(string: result) {
                        UIApplication.shared.open(url)
                    }
                }, label: {
                    Text("はい")
                })
            }, message: {
                Text(result)
            })
    }
}

#Preview {
    ContentView()
}
