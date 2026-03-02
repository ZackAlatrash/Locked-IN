import Foundation

struct LockConfiguration: Codable, Equatable {
    let startDate: Date
    let totalLockDays: Int
    let windowLengthDays: Int

    init(startDate: Date, totalLockDays: Int, windowLengthDays: Int = 14) {
        self.startDate = startDate
        self.totalLockDays = totalLockDays
        self.windowLengthDays = windowLengthDays
    }
}
