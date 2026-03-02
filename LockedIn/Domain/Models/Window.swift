import Foundation

struct Window: Codable, Equatable {
    let index: Int
    let startDate: Date
    let endDate: Date
    var weeklyViolationCount: Int
    var weeksEvaluated: Set<WeekID>

    init(
        index: Int,
        startDate: Date,
        endDate: Date,
        weeklyViolationCount: Int = 0,
        weeksEvaluated: Set<WeekID> = []
    ) {
        self.index = index
        self.startDate = startDate
        self.endDate = endDate
        self.weeklyViolationCount = weeklyViolationCount
        self.weeksEvaluated = weeksEvaluated
    }
}
