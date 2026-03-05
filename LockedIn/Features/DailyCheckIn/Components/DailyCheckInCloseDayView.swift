import SwiftUI

struct DailyCheckInCloseDayView: View {
    let completedCount: Int
    let streakDays: Int
    let line: String
    let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color {
        colorScheme == .dark ? Color(hex: "#22D3EE") : Color(hex: "#0369A1")
    }

    private var textMain: Color {
        colorScheme == .dark ? .white : Color(hex: "#0F172A")
    }

    private var textMuted: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color(hex: "#6B7280")
    }

    var body: some View {
        DailyCheckInCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("DAY CLOSED")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .tracking(1.4)
                    .foregroundColor(accent)

                HStack(spacing: 12) {
                    summaryMetric(title: "Completed", value: "\(completedCount)")
                    summaryMetric(title: "Streak", value: "\(streakDays)d")
                }

                Text(line)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Close") {
                    onClose()
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
            }
        }
    }

    private func summaryMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(textMuted)
            Text(value)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(textMain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
