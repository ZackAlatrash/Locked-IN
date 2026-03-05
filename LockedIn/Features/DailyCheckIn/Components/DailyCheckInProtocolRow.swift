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

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: ProtocolIconCatalog.resolvedSymbolName(item.iconSystemName, fallback: "bolt.fill"))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(item.isExtraToday ? extraAccent : (item.completedToday ? textMuted : accent))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill((item.isExtraToday ? extraAccent : (item.completedToday ? textMuted : accent)).opacity(colorScheme == .dark ? 0.18 : 0.14))
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(textMain)
                        .lineLimit(1)
                    Text(item.modeLabel)
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule(style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        )
                        .foregroundColor(textMuted)
                }

                Text(item.statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(item.isExtraToday ? extraAccent : (item.needsAttention ? Color(hex: "#F59E0B") : textMuted))

                if let remainingWeekText = item.remainingWeekText {
                    Text(remainingWeekText.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(textMuted)
                }
            }

            Spacer(minLength: 8)

            VStack(spacing: 8) {
                Button(item.actionTitle) {
                    onMarkDone()
                }
                .buttonStyle(.borderedProminent)
                .tint(item.isExtraToday ? extraAccent : accent)
                .disabled(item.canMarkDone == false)
                .font(.system(size: 12, weight: .bold))

                if item.canMarkDone == false, let actionDisabledReason = item.actionDisabledReason {
                    Text(actionDisabledReason.uppercased())
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(textMuted)
                        .frame(maxWidth: 96, alignment: .trailing)
                }

                if item.canResolve {
                    Button("Resolve") {
                        onResolve()
                    }
                    .buttonStyle(.bordered)
                    .font(.system(size: 11, weight: .bold))
                }
            }
            .frame(minWidth: 96)
        }
        .opacity(item.isSuspended ? 0.7 : 1)
    }
}
