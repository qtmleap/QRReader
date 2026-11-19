import SwiftUI
import UIKit

/// The single result presentation, used for live scans and history rows, for URLs and plain text.
struct ResultSheet: View {
    let result: PresentedResult

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var copied = false
    @State private var showShare = false
    @State private var resetCopied: Task<Void, Never>?

    private var content: QRContent { result.content }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            topRow
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if typeSize.isAccessibilitySize {
                        dateText.fixedSize(horizontal: false, vertical: true)
                    }
                    titleText
                        .font(.title2.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("result.title")
                    Text(content.value)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: AppMetrics.cornerRadius).fill(Color.appSurface))
                        .accessibilityIdentifier("result.payload")
                }
            }
            if !result.wasSaved {
                Text("result.notSaved")
                    .font(.footnote)
                    .foregroundStyle(Color.appDanger)
                    .accessibilityIdentifier("result.notSaved")
            }
            if copied {
                Label("result.copied", systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                    .accessibilityIdentifier("result.copyFeedback")
            }
            actions
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.appBackground.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("result.sheet")
        .presentationDetents(typeSize >= .accessibility1 ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [content.value])
                .presentationDetents([.medium, .large])
        }
        .onDisappear { resetCopied?.cancel() }
    }

    private var titleText: Text {
        if let host = content.host {
            return Text(verbatim: host)
        }
        return Text("result.type.text")
    }

    private var topRow: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(content.typeLabel)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.appSurface))
                .accessibilityIdentifier("result.type")
            if !typeSize.isAccessibilitySize { dateText }
            Spacer(minLength: 8)
            IconButton(symbol: "xmark", label: "result.close", identifier: "result.close") {
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
    }

    private var dateText: some View {
        Text(result.date, format: .dateTime.year().month().day().hour().minute())
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("result.date")
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if let url = content.webURL {
                Button(action: { openURL(url) }, label: {
                    ActionLabel(title: "result.open", symbol: "arrow.up.right.square")
                })
                .buttonStyle(.primaryAction)
                .accessibilityIdentifier("result.open")
            }
            if typeSize.isAccessibilitySize {
                VStack(spacing: 10) { copyButton; shareButton }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { copyButton; shareButton }
                    VStack(spacing: 10) { copyButton; shareButton }
                }
            }
        }
    }

    private var copyButton: some View {
        Button(action: copy, label: {
            ActionLabel(title: copied ? "result.copied" : "result.copy", symbol: copied ? "checkmark" : "doc.on.doc")
        })
        .buttonStyle(content.isWebURL ? ActionButtonStyle(kind: .secondary) : ActionButtonStyle(kind: .primary))
        .accessibilityIdentifier("result.copy")
    }

    private var shareButton: some View {
        Button(action: { showShare = true }, label: {
            ActionLabel(title: "result.share", symbol: "square.and.arrow.up")
        })
        .buttonStyle(.secondaryAction)
        .accessibilityIdentifier("result.share")
    }

    private func copy() {
        UIPasteboard.general.string = content.value
        copied = true
        UIAccessibility.post(notification: .announcement, argument: String(localized: "result.copied"))
        resetCopied?.cancel()
        resetCopied = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if !Task.isCancelled {
                copied = false
            }
        }
    }
}
