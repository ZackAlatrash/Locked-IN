import SwiftUI

struct DailyCheckInResolutionSheet: View {
    let protocolItem: DailyCheckInProtocolItem
    let recommendation: DailyCheckInRecommendationModel?
    let onRescheduleInPlan: () -> Void
    let onRegulator: () -> Void
    let onApplyRecommendation: () -> Void
    let onChooseManual: () -> Void
    let onDismissRecommendation: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color {
        colorScheme == .dark ? Color(hex: "#22D3EE") : Color(hex: "#0369A1")
    }

    private var textMain: Color {
        colorScheme == .dark ? .white : Color(hex: "#0F172A")
    }

    private var textMuted: Color {
        colorScheme == .dark ? Color.white.opacity(0.65) : Color(hex: "#6B7280")
    }

    var body: some View {
        DailyCheckInCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Resolve \(protocolItem.title)")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(textMain)

                Text("Pick one path. You can place it manually in Plan or use the regulator for a deterministic recommendation.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textMuted)

                if let recommendation {
                    recommendationBlock(recommendation)
                } else {
                    pendingActions
                }
            }
        }
    }

    @ViewBuilder
    private var pendingActions: some View {
        VStack(spacing: 10) {
            Button {
                onRescheduleInPlan()
            } label: {
                Label("Reschedule in Plan", systemImage: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)

            Button {
                onRegulator()
            } label: {
                Label("Let Regulator Place It", systemImage: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
        }
    }

    private func recommendationBlock(_ recommendation: DailyCheckInRecommendationModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Recommendation")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(accent)
                Text("\(recommendation.dayLabel) • \(recommendation.slotLabel) • \(recommendation.durationLabel)")
                    .font(.system(size: 17, weight: .black))
                    .foregroundColor(textMain)
                Text("\(recommendation.reason) \(recommendation.confidenceLabel) confidence.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textMuted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(colorScheme == .dark ? 0.14 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(accent.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )

            VStack(spacing: 10) {
                Button("Apply") {
                    onApplyRecommendation()
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .frame(maxWidth: .infinity)

                HStack(spacing: 10) {
                    Button("Choose Manually") {
                        onChooseManual()
                    }
                    .buttonStyle(.bordered)

                    Button("Dismiss") {
                        onDismissRecommendation()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
