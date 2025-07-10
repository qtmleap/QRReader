//
//  ResultView.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import SwiftUI

struct ResultView: View {
    let result: String
    @State private var isPresented: Bool = false

    var body: some View {
        VStack(content: {
            ScrollView(content: {
                Text(result)
                    .contextMenu(menuItems: {
                        Button(action: {
                            UIPasteboard.general.string = result
                        }, label: {
                            Text("クリップボードにコピー")
                        })
                    })
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .border(Color.primary, width: 3.0)
            })
            HStack(spacing: nil, content: {
                Button(action: {
                    if #available(iOS 16.0, *) {
                        isPresented.toggle()
                    } else {
                        UIApplication.shared.presentedViewController?.present(UIActivityViewController(activityItems: [result], applicationActivities: nil), animated: true)
                    }
                }, label: {
                    HStack(content: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body)
                            .imageScale(.medium)
                            .frame(width: 20, height: 20)
                        Text("シェア")
                    })
                })
                .buttonStyle(.borderedProminent)
                Button(action: {
                    UIPasteboard.general.string = result
                }, label: {
                    HStack(content: {
                        Image(systemName: "doc.on.doc")
                            .font(.body)
                            .imageScale(.medium)
                            .frame(width: 20, height: 20)
                        Text("コピー")
                    })
                })
                .buttonStyle(.borderedProminent)
            })
            .padding([.horizontal, .bottom])
        })
        .sheet(isPresented: $isPresented, content: {
            if #available(iOS 16.0, *) {
                ActivityView(activityItems: [result], applicationActivities: nil)
                    .presentationDetents([.medium, .large])
            } else {
                EmptyView()
            }
        })
        .padding([.horizontal])
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("読み取り結果")
    }
}

#Preview {
    ResultView(result: "Hello, World!")
}
