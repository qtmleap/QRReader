import SwiftUI

enum AppTab: String, CaseIterable {
    case scan, history

    var symbol: String {
        switch self {
            case .scan: return "qrcode.viewfinder"
            case .history: return "clock"
        }
    }

    var title: LocalizedStringKey {
        switch self {
            case .scan: return "tab.scan"
            case .history: return "tab.history"
        }
    }
}

/// Shared bottom bar installed with `safeAreaInset`; symbols are exactly 28pt, targets at least 44pt.
struct AppTabBar: View {
    @Binding var selection: AppTab
    /// Translucent dark chrome over the camera preview; system surface otherwise.
    let overCamera: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button(action: { selection = tab }, label: {
                    VStack(spacing: 2) {
                        SymbolIcon(name: tab.symbol, size: AppMetrics.tabSymbolSize)
                        Text(tab.title)
                            .font(.caption.weight(.medium))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(selection == tab ? Color.appAccent : Color.secondary)
                    .frame(maxWidth: .infinity, minHeight: AppMetrics.minTarget + 12)
                    .contentShape(Rectangle())
                })
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab.\(tab.rawValue)")
                .accessibilityAddTraits(selection == tab ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(
            (overCamera ? Color.black.opacity(0.72) : Color.appBackground)
                .ignoresSafeArea(edges: .bottom)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tabbar")
    }
}
