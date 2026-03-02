import Foundation

struct StreakEngine {
    private let calendar: Calendar

    init(calendar: Calendar = DateRules.isoCalendar) {
        self.calendar = calendar
    }

    func currentStreakDays(from completions: [CompletionRecord], referenceDate: Date) -> Int {
        guard completedOnDay(referenceDate, completions: completions) else {
            return 0
        }

        var streak = 0
        var cursor = DateRules.startOfDay(referenceDate, calendar: calendar)

        while completedOnDay(cursor, completions: completions) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }

        return streak
    }

    func completedOnDay(_ date: Date, completions: [CompletionRecord]) -> Bool {
        let targetDay = DateRules.startOfDay(date, calendar: calendar)
        return completions.contains { completion in
            calendar.isDate(DateRules.startOfDay(completion.date, calendar: calendar), inSameDayAs: targetDay)
        }
    }
}
