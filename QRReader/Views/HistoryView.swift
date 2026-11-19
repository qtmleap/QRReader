//
//  HistoryView.swift
//  QRReader
//
//  Created by devonly on 2025/07/07.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import SwiftUI

struct HistoryView: View {
    let onOpenSettings: () -> Void
    let onGoToScan: () -> Void

    @EnvironmentObject private var store: HistoryStore
    @EnvironmentObject private var controller: ScanController
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var pendingDelete: HistoryItem?
    @State private var confirmClear = false

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "history.title") {
                HStack(spacing: 0) {
                    if !store.items.isEmpty || store.hasLoadError {
                        if typeSize.isAccessibilitySize {
                            IconButton(symbol: "trash", label: "history.clear", identifier: "history.clear") { confirmClear = true }
                                .foregroundStyle(Color.appDanger)
                        } else {
                            Button("history.clear") { confirmClear = true }
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.appDanger)
                                .multilineTextAlignment(.trailing)
                                .frame(minHeight: AppMetrics.minTarget)
                                .padding(.horizontal, 8)
                                .accessibilityIdentifier("history.clear")
                        }
                    }
                    IconButton(symbol: "gearshape", label: "settings.title", identifier: "history.settings", action: onOpenSettings)
                }
            }
            content
        }
        .background(Color.appBackground.ignoresSafeArea())
        .alert(
            "history.delete.title",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            presenting: pendingDelete,
            actions: { item in
                Button("common.cancel", role: .cancel) {}
                Button("history.delete", role: .destructive) { store.remove(id: item.id) }
            },
            message: { item in
                Text(item.value)
            }
        )
        .alert("history.clear.title", isPresented: $confirmClear) {
            Button("common.cancel", role: .cancel) {}
            Button("history.clear.confirm", role: .destructive) { store.clear() }
        } message: {
            if store.hasLoadError {
                Text("history.clear.damagedMessage")
            } else {
                Text("history.clear.message \(store.items.count)")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.hasLoadError {
            StatePanel(symbol: "exclamationmark.triangle", title: "history.error.title", message: "history.error.message") {
                Button(action: { confirmClear = true }, label: {
                    ActionLabel(title: "history.error.action", symbol: "trash")
                })
                .buttonStyle(.dangerAction)
                .accessibilityIdentifier("history.error.clear")
            }
            .accessibilityIdentifier("history.error")
        } else if store.items.isEmpty {
            StatePanel(symbol: "clock", title: "history.empty.title", message: "history.empty.message") {
                Button(action: onGoToScan, label: {
                    ActionLabel(title: "history.empty.action", symbol: "qrcode.viewfinder")
                })
                .buttonStyle(.primaryAction)
                .accessibilityIdentifier("history.empty.scan")
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("history.empty")
        } else {
            List {
                ForEach(store.items) { item in
                    HistoryRow(item: item) { controller.showHistoryItem(item) }
                        .listRowBackground(Color.appBackground)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive, action: { pendingDelete = item }, label: {
                                Label("history.delete", systemImage: "trash")
                            })
                            .accessibilityIdentifier("history.delete")
                        }
                        .accessibilityAction(named: Text("history.delete")) { pendingDelete = item }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .accessibilityIdentifier("history.list")
        }
    }
}

private struct HistoryRow: View {
    let item: HistoryItem
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    private var content: QRContent { QRContent(value: item.value) }

    var body: some View {
        Button(action: action, label: {
            HStack(spacing: 12) {
                SymbolIcon(name: content.isWebURL ? "link" : "doc.text")
                    .foregroundStyle(Color.appAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(firstLine)
                        .font(.body)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    if typeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(content.typeLabel)
                            Text(item.date, format: .dateTime.year().month().day().hour().minute())
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 4) {
                            Text(content.typeLabel)
                            Text("・")
                            Text(item.date, format: .dateTime.year().month().day().hour().minute())
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: AppMetrics.minTarget)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("history.row.\(item.id.uuidString)")
    }

    private var firstLine: String {
        item.value.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? item.value
    }
}
