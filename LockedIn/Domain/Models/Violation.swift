import Foundation

enum ViolationKind: String, Codable, Equatable {
    case missedWeeklyFrequency
    case missedDailyCompliance
}

struct Violation: Codable, Equatable {
    let date: Date
    let kind: ViolationKind
    let windowIndex: Int
    let weekId: WeekID
}
