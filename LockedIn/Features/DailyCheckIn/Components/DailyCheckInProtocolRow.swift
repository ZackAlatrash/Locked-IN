import SwiftUI

struct DailyCheckInProtocolRow: View {
    let item: DailyCheckInProtocolItem
    let onMarkDone: () -> Void
    let isRecoveryThemeActive: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var surfaceColor: Color {
        colorScheme == .dark ? Color(hex: "#0E0E11").opacity(0.9) : Color.white.opacity(0.96)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color(hex: "#849495").opacity(0.2) : Color.black.opacity(0.1)
    }

    private var mutedText: Color {
        colorScheme == .dark ? Color(hex: "#B9CACB") : Color(hex: "#6B7280")
    }

    private var primaryTone: Color {
        if isRecoveryThemeActive {
            return colorScheme == .dark ? Color(hex: "#F87171") : Color(hex: "#B91C1C")
        }
        return Color(hex: "#00F0FF")
    }

    private var secondaryTone: Color {
        if isRecoveryThemeActive {
            return colorScheme == .dark ? Color(hex: "#EF4444") : Color(hex: "#DC2626")
        }
        return Color(hex: "#FF571A")
    }

    private var subtitleLabel: String {
        item.remainingWeekText ?? item.statusText
    }

    private var actionTitle: String {
        item.actionTitle.uppercased()
    }

    private var protocolIconName: String {
        ProtocolIconCatalog.resolvedSymbolName(item.iconSystemName, fallback: "bolt.fill")
    }

    private var actionBackground: Color {
        if item.canMarkDone == false {
            return colorScheme == .dark ? Color(hex: "#353438") : Color(hex: "#E5E7EB")
        }
        return item.needsAttention ? secondaryTone.opacity(0.14) : primaryTone.opacity(0.14)
    }

    private var actionBorder: Color {
        if item.canMarkDone == false {
            return colorScheme == .dark ? Color(hex: "#849495").opacity(0.24) : Color.black.opacity(0.14)
        }
        return item.needsAttention ? secondaryTone.opacity(0.34) : primaryTone.opacity(0.34)
    }

    private var actionText: Color {
        if item.canMarkDone == false {
            return mutedText
        }
        return item.needsAttention ? secondaryTone : primaryTone
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color(hex: "#E5E1E5") : Color(hex: "#1F2937"))
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(subtitleLabel.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.9)
                            .foregroundColor(mutedText)
                            .lineLimit(1)

                        Text("•")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(mutedText.opacity(0.75))

                        Text(item.modeLabel.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.9)
                            .foregroundColor(mutedText)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: protocolIconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryTone.opacity(item.isSuspended ? 0.6 : 1))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color(hex: "#2A2A2D") : Color(hex: "#F3F4F6"))
                    )
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .accessibilityHidden(true)
            }

            Button {
                onMarkDone()
            } label: {
                Text(actionTitle)
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .textCase(.uppercase)
            }
            .buttonStyle(.plain)
            .foregroundColor(actionText)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(actionBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(actionBorder, lineWidth: 1)
            )
            .disabled(item.canMarkDone == false)
            .accessibilityHint(item.actionDisabledReason ?? "")

            if item.canMarkDone == false, let actionDisabledReason = item.actionDisabledReason {
                Text(actionDisabledReason.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
                    .foregroundColor(mutedText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(surfaceColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .opacity(item.isSuspended ? 0.78 : 1)
    }
}
