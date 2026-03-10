import XCTest
@testable import LockedIn

final class DailyCheckInReliabilityCalculatorTests: XCTestCase {
    private typealias Fixtures = RepositoryCommitmentServiceTestFixtures

    func testScoreStartsDynamicBaseNot92() {
        let nn = Fixtures.makeProtocol(frequencyPerWeek: 1)
        // 0 completions / 1 target = 0 completionRate
        // 0 * 40 + 58 = 58
        let score = ReliabilityCalculator.calculateDailyCheckInScore(for: [nn], referenceDate: Fixtures.referenceDate)
        XCTAssertEqual(score, 58)
    }

    func testCompletionsIncreaseScoreByFraction() {
        let date = Fixtures.referenceDate
        var nn = Fixtures.makeProtocol(frequencyPerWeek: 4)
        
        nn.completions = [
            Fixtures.makeCompletion(date: date)
        ]

        let score = ReliabilityCalculator.calculateDailyCheckInScore(for: [nn], referenceDate: date)
        
        // 1 completion / 4 target = 0.25 completionRate
        // 0.25 * 40 + 58 = 68
        XCTAssertEqual(score, 68)
    }

    func testSuspendedProtocolReducesScoreBy8() {
        let nn = Fixtures.makeProtocol(frequencyPerWeek: 1, state: .suspended)
        // base 58 - 8 = 50
        let score = ReliabilityCalculator.calculateDailyCheckInScore(for: [nn], referenceDate: Fixtures.referenceDate)
        XCTAssertEqual(score, 50)
    }

    func testRecoveryProtocolReducesScoreBy12() {
        let nn = Fixtures.makeProtocol(frequencyPerWeek: 1, state: .recovery)
        // base 58 - 12 = 46
        let score = ReliabilityCalculator.calculateDailyCheckInScore(for: [nn], referenceDate: Fixtures.referenceDate)
        XCTAssertEqual(score, 46)
    }
    
    func testViolationsAreIgnored() {
        var nn = Fixtures.makeProtocol(frequencyPerWeek: 1)
        let weekId = DateRules.weekID(for: Fixtures.referenceDate, calendar: Fixtures.calendar)
        nn.violations = [
            Violation(date: Fixtures.referenceDate, kind: .missedWeeklyFrequency, windowIndex: 0, weekId: weekId),
            Violation(date: Fixtures.referenceDate, kind: .missedDailyCompliance, windowIndex: 0, weekId: weekId)
        ]
        let score = ReliabilityCalculator.calculateDailyCheckInScore(for: [nn], referenceDate: Fixtures.referenceDate)
        // base 58 - 0 penalty = 58
        XCTAssertEqual(score, 58)
    }

    func testEmptySystemReturns92() {
        let score = ReliabilityCalculator.calculateDailyCheckInScore(for: [], referenceDate: Fixtures.referenceDate)
        XCTAssertEqual(score, 92)
    }
}
