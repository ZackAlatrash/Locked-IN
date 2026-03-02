import Foundation

struct WeekID: Hashable, Codable, Equatable, CustomStringConvertible {
    let yearForWeekOfYear: Int
    let weekOfYear: Int

    var description: String {
        String(format: "%04d-W%02d", yearForWeekOfYear, weekOfYear)
    }
}

enum DateRules {
    static var isoCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        return calendar
    }

    static func startOfDay(_ date: Date, calendar: Calendar = DateRules.isoCalendar) -> Date {
        calendar.startOfDay(for: date)
    }

    static func addingDays(_ days: Int, to date: Date, calendar: Calendar = DateRules.isoCalendar) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    static func weekID(for date: Date, calendar: Calendar = DateRules.isoCalendar) -> WeekID {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return WeekID(
            yearForWeekOfYear: components.yearForWeekOfYear ?? 0,
            weekOfYear: components.weekOfYear ?? 0
        )
    }

    static func weekInterval(containing date: Date, calendar: Calendar = DateRules.isoCalendar) -> DateInterval {
        if let interval = calendar.dateInterval(of: .weekOfYear, for: date) {
            return interval
        }
        let start = startOfDay(date, calendar: calendar)
        let end = addingDays(7, to: start, calendar: calendar)
        return DateInterval(start: start, end: end)
    }

    static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int = 0,
        second: Int = 0,
        calendar: Calendar = DateRules.isoCalendar
    ) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }
}
