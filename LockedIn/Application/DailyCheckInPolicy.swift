import Foundation

enum DailyCheckInPromptType {
    case initial
    case reprompt
}

enum DailyCheckInPolicy {
    enum Keys {
        static let lastCompletedDay = "dailyCheckInLastCompletedDayKey"
        static let lastPromptedDay = "dailyCheckInLastPromptedDayKey"
        static let repromptedDay = "dailyCheckInRepromptedDayKey"
        static let deferredUntilTimestamp = "dailyCheckInDeferredUntilTimestamp"
        static let hour = "dailyCheckInHour"
        static let minute = "dailyCheckInMinute"
    }

    static func dayIdentifier(for date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func thresholdDate(
        on date: Date,
        hour: Int,
        minute: Int,
        calendar: Calendar = .current
    ) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        let safeHour = max(0, min(hour, 23))
        let safeMinute = max(0, min(minute, 59))
        return calendar.date(
            bySettingHour: safeHour,
            minute: safeMinute,
            second: 0,
            of: dayStart
        ) ?? dayStart
    }

    static func promptType(
        now: Date,
        lastCompletedDay: String,
        lastPromptedDay: String,
        repromptedDay: String,
        deferredUntilTimestamp: Double,
        hour: Int,
        minute: Int,
        calendar: Calendar = .current
    ) -> DailyCheckInPromptType? {
        let today = dayIdentifier(for: now, calendar: calendar)
        if lastCompletedDay == today {
            return nil
        }

        if now < thresholdDate(on: now, hour: hour, minute: minute, calendar: calendar) {
            return nil
        }

        if lastPromptedDay != today {
            return .initial
        }

        if repromptedDay == today {
            return nil
        }

        guard deferredUntilTimestamp > 0 else {
            return nil
        }

        return now.timeIntervalSince1970 >= deferredUntilTimestamp ? .reprompt : nil
    }

    static func deferredTimestamp(from now: Date, minutes: Int = 30) -> Double {
        now.addingTimeInterval(TimeInterval(max(1, minutes) * 60)).timeIntervalSince1970
    }
}
