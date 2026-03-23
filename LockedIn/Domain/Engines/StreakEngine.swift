import Foundation

struct StreakEngine {
    private let calendar: Calendar

    init(calendar: Calendar = DateRules.isoCalendar) {
        self.calendar = calendar
    }

    func currentStreakDays(
        from completions: [CompletionRecord],
        violations: [Violation] = [],
        referenceDate: Date,
        trackingStartDate: Date? = nil
    ) -> Int {
        obligationStreakDays(
            completions: completions,
            violations: violations,
            referenceDate: referenceDate,
            trackingStartDate: trackingStartDate
        )
    }

    private func completionStreakDays(completions: [CompletionRecord], referenceDate: Date) -> Int {
        let referenceDay = DateRules.startOfDay(referenceDate, calendar: calendar)
        let anchorDay: Date
        if completedOnDay(referenceDay, completions: completions) {
            anchorDay = referenceDay
        } else if let previousDay = calendar.date(byAdding: .day, value: -1, to: referenceDay) {
            anchorDay = previousDay
        } else {
            return 0
        }

        guard completedOnDay(anchorDay, completions: completions) else {
            return 0
        }

        var streak = 0
        var cursor = anchorDay

        while completedOnDay(cursor, completions: completions) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }

        return streak
    }

    private func obligationStreakDays(
        completions: [CompletionRecord],
        violations: [Violation],
        referenceDate: Date,
        trackingStartDate: Date?
    ) -> Int {
        let referenceDay = DateRules.startOfDay(referenceDate, calendar: calendar)
        let hasAnyCountedCompletion = completions.contains { $0.kind == .counted }
        if hasAnyCountedCompletion == false && violations.isEmpty {
            return 0
        }

        let startDay = trackingStartDate.map { DateRules.startOfDay($0, calendar: calendar) } ?? referenceDay
        guard startDay <= referenceDay else { return 0 }

        let violationDays = Set(
            violations.map { violation in
                DateRules.startOfDay(violation.date, calendar: calendar)
            }
        )

        var streak = 0
        var cursor = referenceDay

        while cursor >= startDay {
            if violationDays.contains(cursor) {
                break
            }
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
            completion.kind == .counted &&
            calendar.isDate(DateRules.startOfDay(completion.date, calendar: calendar), inSameDayAs: targetDay)
        }
    }
}
