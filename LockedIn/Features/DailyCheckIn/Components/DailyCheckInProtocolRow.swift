import SwiftUI

struct DailyCheckInProtocolRow: View {
    let item: DailyCheckInProtocolItem
    let onMarkDone: () -> Void
    let onResolve: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color {
        colorScheme == .dark ? Color(hex: "#22D3EE") : Color(hex: "#0369A1")
    }

    private var extraAccent: Color {
        colorScheme == .dark ? Color(hex: "#FDE047") : Color(hex: "#A16207")
    }

    private var textMain: Color {
        colorScheme == .dark ? .white : Color(hex: "#0F172A")
    }

    private var textMuted: Color {
        colorScheme == .dark ? Color.white.opacity(0.62) : Color(hex: "#6B7280")
    }

    private var rowBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.035) : Color.black.opacity(0.03)
    }

    private var statusTint: Color {
        if item.isSuspended { return textMuted }
        if item.isExtraToday { return extraAccent }
        if item.needsAttention { return Color(hex: "#F59E0B") }
        if item.completedToday { return accent }
        return textMuted
    }

    private var actionTint: Color {
        item.isExtraToday ? extraAccent : accent
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: ProtocolIconCatalog.resolvedSymbolName(item.iconSystemName, fallback: "bolt.fill"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(statusTint)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(statusTint.opacity(colorScheme == .dark ? 0.2 : 0.14))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(textMain)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(item.modeLabel)
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule(style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        )
                        .foregroundColor(textMuted)

                    Text(item.statusText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(statusTint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                if let remainingWeekText = item.remainingWeekText {
                    Text(remainingWeekText.uppercased())
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(textMuted)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Button(item.actionTitle) {
                    onMarkDone()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(actionTint)
                .disabled(item.canMarkDone == false)
                .font(.system(size: 12, weight: .bold))

                if item.canResolve {
                    Button("Resolve") {
                        onResolve()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .font(.system(size: 11, weight: .bold))
                }

                if item.canMarkDone == false, let actionDisabledReason = item.actionDisabledReason {
                    Text(actionDisabledReason.uppercased())
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(textMuted)
                        .frame(maxWidth: 110, alignment: .trailing)
                }
            }
            .frame(minWidth: 100)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(rowBackground)
        )
        .opacity(item.isSuspended ? 0.75 : 1)
    }
}
