//
//  SettingView.swift
//  QRReader
//
//  Created by devonly on 2025/07/23.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import LicenseList
import SwiftUI

struct SettingView: View {
    private let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.1"
    private let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

    var body: some View {
        Form(content: {
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
                Text("アプリ情報")
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
