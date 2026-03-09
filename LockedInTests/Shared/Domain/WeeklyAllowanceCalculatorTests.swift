import XCTest
@testable import LockedIn

final class WeeklyAllowanceCalculatorTests: XCTestCase {
    
    func testDailyModeRemainingCount() {
        // 7 days minus completions minus planned
        let remaining1 = WeeklyAllowanceCalculator.remainingThisWeek(
            mode: .daily, frequencyPerWeek: 7, completionsThisWeek: 2, plannedThisWeek: 3
        )
        XCTAssertEqual(remaining1, 2)
        
        let remaining2 = WeeklyAllowanceCalculator.remainingThisWeek(
            mode: .daily, frequencyPerWeek: 7, completionsThisWeek: 7, plannedThisWeek: 0
        )
        XCTAssertEqual(remaining2, 0)
        
        // Ensure no negative values
        let remaining3 = WeeklyAllowanceCalculator.remainingThisWeek(
            mode: .daily, frequencyPerWeek: 7, completionsThisWeek: 5, plannedThisWeek: 5
        )
        XCTAssertEqual(remaining3, 0)
    }

    func testSessionModeRemainingCount() {
        let remaining1 = WeeklyAllowanceCalculator.remainingThisWeek(
            mode: .session, frequencyPerWeek: 4, completionsThisWeek: 1, plannedThisWeek: 2
        )
        XCTAssertEqual(remaining1, 1)
        
        // Zero planned
        let remaining2 = WeeklyAllowanceCalculator.remainingThisWeek(
            mode: .session, frequencyPerWeek: 3, completionsThisWeek: 1, plannedThisWeek: 0
        )
        XCTAssertEqual(remaining2, 2)
        
        // Exceed target
        let remaining3 = WeeklyAllowanceCalculator.remainingThisWeek(
            mode: .session, frequencyPerWeek: 3, completionsThisWeek: 4, plannedThisWeek: 0
        )
        XCTAssertEqual(remaining3, 0)
    }
}
