//
//  SettingView.swift
//  QRReader
//
//  Created by devonly on 2025/07/23.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import LicenseList
import StoreKit
import SwiftUI

struct SettingView: View {
    @AppStorage("IS_FIRST_LAUNCH") private var isFirstLaunch: Bool = true
    private let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.1"
    private let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

    var body: some View {
        Form(content: {
            Section(content: {
                Button(action: {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }, label: {
                    Text("アプリを評価する")
                })
                Button(action: {
                    isFirstLaunch.toggle()
                }, label: {
                    Text("アプリの使い方")
                })
            }, header: {
                Text("サポート")
            })
            Section(content: {
                Link(destination: URL(string: "https://qleap.jp/term/eula")!, label: {
                    Text("利用規約")
                })
                Link(destination: URL(string: "https://qleap.jp/term/privacy_policy")!, label: {
                    Text("プライバシーポリシー")
                })
                NavigationLink(destination: {
                    LicenseListView()
                        .licenseViewStyle(.withRepositoryAnchorLink)
                        .navigationTitle("LICENSE")
                }, label: {
                    Text("ライセンス")
                })
            }, header: {
                Text("ポリシー")
            })
            Section(content: {
                HStack(content: {
                    Text("バージョン")
                    Spacer()
                    Text(version)
                        .foregroundStyle(.secondary)
                })
                HStack(content: {
                    Text("ビルド")
                    Spacer()
                    Text(build)
                        .foregroundStyle(.secondary)
                })
            }, header: {
                Text("バージョン情報")
            })
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
