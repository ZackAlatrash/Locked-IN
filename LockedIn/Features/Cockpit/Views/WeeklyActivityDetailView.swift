import SwiftUI

struct WeeklyActivityDetailView: View {
    let weeklyCompletionByDay: [Int]
    let weeklyCompletionCount: Int
    let weeklyTargetCount: Int
    let todayCompletionCount: Int
    let accentColor: Color
    let onOpenLogs: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var isDarkMode: Bool { colorScheme == .dark }
    private var pageBackground: Color { isDarkMode ? Color.black : Color(hex: "F2F2F7") }
    private var cardBackground: Color { isDarkMode ? Color(hex: "#1C1C1E") : Color.white }
    private var textMain: Color { isDarkMode ? Color.white : Color(hex: "101827") }
    private var textSecondary: Color { isDarkMode ? Color.white.opacity(0.72) : Color(hex: "6B7280") }
    private var textMuted: Color { isDarkMode ? Color.white.opacity(0.48) : Color(hex: "9CA3AF") }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                summaryPanel
                barsPanel

                Button {
                    onOpenLogs()
                } label: {
                    Text("Open Logs")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
            }
            .padding(16)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("Weekly Activity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension WeeklyActivityDetailView {
    var summaryPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textMuted)

            Text("\(weeklyCompletionCount) / \(max(weeklyTargetCount, 1)) completions")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(textMain)

            Text("Today: \(todayCompletionCount)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textSecondary)
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var barsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Distribution")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(textSecondary)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(weeklyCompletionByDay.enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(index == currentWeekdayIndex ? accentColor : (isDarkMode ? Color.white.opacity(0.14) : Color.black.opacity(0.14)))
                            .frame(width: 22, height: barHeight(for: value))
                        Text(dayLabel(index))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textMuted)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func barHeight(for value: Int) -> CGFloat {
        let maxValue = max(weeklyCompletionByDay.max() ?? 1, 1)
        let ratio = CGFloat(value) / CGFloat(maxValue)
        return max(16, 72 * ratio)
    }

    func dayLabel(_ index: Int) -> String {
        let labels = ["M", "T", "W", "T", "F", "S", "S"]
        return labels[index]
    }

    var currentWeekdayIndex: Int {
        let weekday = DateRules.isoCalendar.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }
}
