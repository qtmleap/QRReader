import SwiftUI

enum AppMetrics {
    /// Bottom-bar destination symbols.
    static let tabSymbolSize: CGFloat = 28
    /// Action symbols (settings, close, copy, share, ...).
    static let actionSymbolSize: CGFloat = 24
    static let minTarget: CGFloat = 44
    static let cornerRadius: CGFloat = 14
}

extension Color {
    static let appAccent = Color("AccentColor")
    static let appBackground = Color("AppBackground")
    static let appSurface = Color("AppSurface")
    static let appAccentOn = Color("AppAccentOn")
    static let appDanger = Color("AppDanger")
}

extension QRContent {
    var typeLabel: LocalizedStringKey { isWebURL ? "result.type.url" : "result.type.text" }
}

/// SF Symbol at an exact point size; decorative, so hidden from accessibility.
struct SymbolIcon: View {
    let name: String
    var size: CGFloat = AppMetrics.actionSymbolSize

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .regular))
            .frame(minWidth: size, minHeight: size)
            .accessibilityHidden(true)
    }
}

/// Icon-only button with a 44pt minimum target.
struct IconButton: View {
    let symbol: String
    let label: LocalizedStringKey
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SymbolIcon(name: symbol)
                .frame(minWidth: AppMetrics.minTarget, minHeight: AppMetrics.minTarget)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
    }
}

struct ActionButtonStyle: ButtonStyle {
    enum Kind {
        case primary, secondary, danger
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
        return configuration.label
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: AppMetrics.minTarget)
            .foregroundStyle(foreground)
            .background(shape.fill(background))
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.75 : 1)
    }

    private var foreground: Color {
        switch kind {
            case .primary: return .appAccentOn
            case .secondary: return .primary
            case .danger: return .appAccentOn
        }
    }

    private var background: Color {
        switch kind {
            case .primary: return .appAccent
            case .secondary: return .appSurface
            case .danger: return .appDanger
        }
    }
}

extension ButtonStyle where Self == ActionButtonStyle {
    static var primaryAction: ActionButtonStyle { .init(kind: .primary) }
    static var secondaryAction: ActionButtonStyle { .init(kind: .secondary) }
    static var dangerAction: ActionButtonStyle { .init(kind: .danger) }
}

/// Icon + multiline title for `ActionButtonStyle` buttons.
struct ActionLabel: View {
    let title: LocalizedStringKey
    var symbol: String?

    var body: some View {
        HStack(spacing: 8) {
            if let symbol {
                SymbolIcon(name: symbol)
            }
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Title row shared by Scan and History.
struct ScreenHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("screen.title")
            Spacer(minLength: 8)
            trailing
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .frame(minHeight: 52)
    }
}

/// Centered icon/title/message panel with optional actions.
struct StatePanel<Actions: View>: View {
    let symbol: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ViewBuilder let actions: Actions

    var body: some View {
        ViewThatFits(in: .vertical) {
            VStack(spacing: 12) {
                information
                actions.padding(.top, 8)
            }
            .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 12) {
                GeometryReader { geometry in
                    ScrollView {
                        information
                            .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    }
                }
                actions
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }

    private var information: some View {
        VStack(spacing: 12) {
            SymbolIcon(name: symbol, size: 32)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
