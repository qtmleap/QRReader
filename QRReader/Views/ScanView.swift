//
//  ScanView.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import CodeScanner
import SwiftUI

#if targetEnvironment(simulator)
struct ScanView: View {
    @State private var isPresented: Bool = false

    var body: some View {
        Image("Dummy")
            .alert("このURLを開きますか？", isPresented: $isPresented, actions: {
                Button(role: .cancel, action: {
                    NotificationCenter.default.post(name: .AVCaptureResumeScan, object: nil)
                }, label: {
                    Text("いいえ")
                })
                Button(action: {
                    if let url: URL = .init(string: "https://qleap.jp") {
                        UIApplication.shared.open(url)
                    }
                }, label: {
                    Text("はい")
                })
            }, message: {
                Text("https://qleap.jp")
            })
    }
}
#else
struct ScanView: View {
    @AppStorage("QR_HISTORY") var items: [HistoryItem] = []
    @State private var result: String = ""
    @State private var isURL: Bool = false
    @State private var isPresented: Bool = false
    @State private var isPaused: Bool = false

    var body: some View {
        CodeScannerView(codeTypes: [.qr], scanMode: .continuous, isPaused: isPaused, completion: { result in
            isPaused = true
            switch result {
                case let .success(result):
                    let isURL: Bool = result.string.isURL
                    self.result = result.string
                    self.isURL = isURL
                    isPresented = !isURL
                    items.append(.init(value: result.string, date: .now))
                case let .failure(error):
                    print(error)
            }
        })
        .edgesIgnoringSafeArea(.top)
        .sheet(isPresented: $isPresented, onDismiss: {
            isPaused = false
        }, content: {
            NavigationView(content: {
                ResultView(result: result)
            })
        })
        .onAppear(perform: {
            isPaused = false
        })
        .onDisappear(perform: {
            isPaused = true
        })
        .alert("このURLを開きますか？", isPresented: $isURL, actions: {
            Button(role: .cancel, action: {
                isPaused = false
            }, label: {
                Text("いいえ")
                    .foregroundColor(.primary)
            })
            Button(action: {
                // 失敗することはないと思うけれど、一応念の為
                if let resultURL: URL = .init(string: result) {
                    UIApplication.shared.open(resultURL)
                }
            }, label: {
                Text("はい")
                    .foregroundColor(.primary)
            })
        }, message: {
            Text(result)
        })
    }
}
#endif

extension String {
    var isURL: Bool {
        guard let url: URL = .init(string: self) else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }
}

#Preview {
    ContentView()
}
