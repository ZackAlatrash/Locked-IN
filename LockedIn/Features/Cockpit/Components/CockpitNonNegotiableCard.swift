import SwiftUI

struct CockpitNonNegotiableCard: View {
    let model: CockpitNonNegotiableCardModel
    let accentColor: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "#162331"))

            cardTexture
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#162331").opacity(0.95),
                            Color(hex: "#162331").opacity(0.88),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.title)
                            .font(.system(size: 50, weight: .heavy))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        HStack(spacing: 8) {
                            Image(systemName: iconName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(iconColor)

                            Text("\(model.subtitle) • \(model.weeklyProgressText)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.textSecondary)
                                .lineLimit(1)
                        }

                        if let stateHint = model.stateHint {
                            Text(stateHint)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(accentColor.opacity(0.92))
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    badge
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DEADLINE")
                            .font(.system(size: 10, weight: .bold))
                            .kerning(1.8)
                            .foregroundColor(Theme.Colors.textTertiary)

                        Text(model.daysLeftText)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(accentColor)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 20)

                    if model.badge == .done || model.badge == .verified {
                        Circle()
                            .stroke(accentColor.opacity(0.6), lineWidth: 2)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(accentColor)
                            )
                    } else {
                        VStack(spacing: 6) {
                            HStack {
                                Text(model.lockProgressText)
                                Spacer()
                                Text("TARGET")
                            }
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.Colors.textMuted)

                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 10)
                                GeometryReader { proxy in
                                    Capsule()
                                        .fill(accentColor)
                                        .frame(width: max(14, proxy.size.width * CGFloat(model.progress)), height: 10)
                                }
                                .frame(height: 10)
                            }
                        }
                        .frame(width: 196)
                    }
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
        .opacity(model.isDimmed ? 0.58 : 1)
    }

    private var cardTexture: some View {
        ZStack {
            if model.title.lowercased().contains("gym") {
                HStack(spacing: 20) {
                    Circle().fill(Color.white.opacity(0.06)).frame(width: 90, height: 90)
                    Circle().fill(Color.white.opacity(0.04)).frame(width: 110, height: 110)
                    Circle().fill(Color.white.opacity(0.03)).frame(width: 70, height: 70)
                }
                .offset(x: 140, y: 24)
            } else {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 120, height: 120)
                    .offset(x: 130, y: 20)

                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 180, height: 180)
                    .offset(x: 160, y: 70)
            }
        }
    }

    private var iconName: String {
        if model.title.lowercased().contains("gym") { return "dumbbell.fill" }
        if model.title.lowercased().contains("sleep") { return "moon.fill" }
        return "checklist"
    }

    private var iconColor: Color {
        model.badge == .due ? accentColor : Theme.Colors.textMuted
    }

    private var badge: some View {
        Text(model.badge.title)
            .font(.system(size: 10, weight: .black))
            .kerning(1.4)
            .foregroundColor(badgeTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(badgeBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(badgeBorderColor, lineWidth: 1)
            )
    }

    private var badgeTextColor: Color {
        switch model.badge {
        case .due, .done, .verified, .suspended, .recovery:
            return accentColor
        case .pending:
            return .clear
        }
    }

    private var badgeBackground: Color {
        switch model.badge {
        case .due:
            return accentColor.opacity(0.16)
        case .done, .verified:
            return accentColor.opacity(0.14)
        case .suspended:
            return accentColor.opacity(0.10)
        case .recovery:
            return accentColor.opacity(0.22)
        case .pending:
            return .clear
        }
    }

    private var badgeBorderColor: Color {
        switch model.badge {
        case .due:
            return accentColor.opacity(0.35)
        case .done, .verified:
            return accentColor.opacity(0.30)
        case .suspended:
            return accentColor.opacity(0.24)
        case .recovery:
            return accentColor.opacity(0.45)
        case .pending:
            return .clear
        }
    }
}
