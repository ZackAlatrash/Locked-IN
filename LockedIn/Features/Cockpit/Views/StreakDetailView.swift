import SwiftUI

struct StreakDetailView: View {
    let currentStreakDays: Int
    let todayCompleted: Bool
    let lastCompletionDate: Date?
    let firstTask: TodayTask?
    let accentColor: Color
    let onMarkTodayDone: (UUID) -> Void
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
                streakPanel
                todayPanel
                actionsPanel
            }
            .padding(16)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("Streak")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension StreakDetailView {
    var streakPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Streak")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textMuted)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(currentStreakDays)")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundColor(accentColor)
                Text("days")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(textSecondary)
            }

            if let lastCompletionDate {
                Text("Last completion: \(dateTitle(lastCompletionDate))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textSecondary)
            } else {
                Text("No completion history yet")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textSecondary)
            }
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var todayPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textMuted)

            Text(todayCompleted ? "Completed" : "Not completed")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(textMain)

            if let firstTask {
                Text(firstTask.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textSecondary)
            }
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var actionsPanel: some View {
        VStack(spacing: 10) {
            if let firstTask {
                Button {
                    onMarkTodayDone(firstTask.nnId)
                } label: {
                    Text(firstTask.ctaTitle)
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
                .disabled(!firstTask.isCtaEnabled)
            }

            Button {
                onOpenLogs()
            } label: {
                Text("Open Logs")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(accentColor)
        }
    }

    func dateTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
