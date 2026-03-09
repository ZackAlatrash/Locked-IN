import XCTest
@testable import LockedIn

final class LockedInSmokeTests: XCTestCase {
    func testDateRulesWeekIDSmoke() {
        let calendar = TestCalendarSupport.utcISO8601
        let date = DateRules.date(year: 2026, month: 1, day: 5, hour: 9, calendar: calendar)
        let weekID = DateRules.weekID(for: date, calendar: calendar)

        XCTAssertEqual(weekID.yearForWeekOfYear, 2026)
        XCTAssertEqual(weekID.weekOfYear, 2)
    }
}
