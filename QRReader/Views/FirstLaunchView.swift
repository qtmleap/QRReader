//
//  FirstLaunchView.swift
//  QRReader
//
//  Created by devonly on 2025/07/25.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftUIIntrospect
import QuantumLeap

struct FirstLaunchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection, content: {
            FirstLaunch(content: {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 140)
                Text("アプリの使い方")
                    .font(.title)
                    .fontWeight(.bold)
                Text("QRコードの情報を簡単に取得できます")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            })
                .tag(0)
            FirstLaunch(content: {
                Image("Scan")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 140)
                Text("QRコードにかざすだけ")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("ピントが合うと自動で読み取りが始まります")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            })
                .tag(1)
            FirstLaunch(content: {
                Image("Result")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 140)
                Text("内容をその場で確認")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("QRコードの情報がすぐに表示されます")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            })
                .tag(2)
            FirstLaunch(content: {
                Image("Share")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                Text("家族や友人と情報を共有できます")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("読み取った内容は簡単にシェアできます")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            })
                .tag(3)
        })
        .disabled(true)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .bottom, content: {
            HStack(content: {
                Button(action: {
                    withAnimation(.spring) {
                        selection = max(0, selection - 1)
                    }
                }, label: {
                    Text("BUTTON_BACK")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                })
                .disabled(selection == 0)
                Button(action: {
                    withAnimation(.spring) {
                        selection != 3 ? selection += 1 : dismiss()
                    }
                }, label: {
                    Text(selection != 3 ? "BUTTON_NEXT" : "BUTTON_END")
                        .fontWeight(.bold)
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                })
            })
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: 300)
        })
        .overlay(alignment: .topTrailing, content: {
            Button(action: {
                dismiss()
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
            })
            .padding()
        })
    }
}

#Preview {
    FirstLaunchView()
}
