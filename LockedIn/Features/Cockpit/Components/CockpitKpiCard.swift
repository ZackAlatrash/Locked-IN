import SwiftUI

struct CockpitKpiCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let accentColor: Color
    let emphasized: Bool
    let indicatorFill: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .kerning(1.6)
                .foregroundColor(emphasized ? accentColor : Theme.Colors.textTertiary)

                Text(value)
                    .font(emphasized ? .system(size: 46, weight: .heavy) : .system(size: 39, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.Colors.textMuted)
            }

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.11))
                    .frame(height: 3)
                Capsule()
                    .fill(accentColor)
                    .frame(width: max(8, 72 * max(0, min(indicatorFill, 1))), height: 3)
            }
            .opacity(emphasized ? 0 : 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "#1b2737"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(emphasized ? accentColor.opacity(0.45) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .shadow(color: emphasized ? accentColor.opacity(0.15) : .clear, radius: 14)
    }
}
