import XCTest
@testable import LockedIn

final class ReliabilityCalculatorTests: XCTestCase {
    private typealias Fixtures = RepositoryCommitmentServiceTestFixtures

    func testScoreStartsAt92ForNewProtocol() {
        let nn = Fixtures.makeProtocol()
        let score = ReliabilityCalculator.calculateCockpitScore(for: [nn], referenceDate: Fixtures.referenceDate)
        XCTAssertEqual(score, 92)
    }

    func testCompletionsIncreaseScoreBy2UpToCap() {
        let date = Fixtures.referenceDate
        var nn = Fixtures.makeProtocol(frequencyPerWeek: 3)
        
        nn.completions = [
            Fixtures.makeCompletion(date: date),
            Fixtures.makeCompletion(date: date),
            Fixtures.makeCompletion(date: date),
            Fixtures.makeCompletion(date: date) // 4th completion, over cap
        ]

        let score = ReliabilityCalculator.calculateCockpitScore(for: [nn], referenceDate: date)
        
        // Base 92 + (3 capped completions * 2) = 98
        XCTAssertEqual(score, 98)
    }

    func testSuspendedProtocolReducesScoreBy14() {
        let nn = Fixtures.makeProtocol(state: .suspended)
        let score = ReliabilityCalculator.calculateCockpitScore(for: [nn], referenceDate: Fixtures.referenceDate)
        // 92 - 14 = 78
        XCTAssertEqual(score, 78)
    }

    func testRecoveryProtocolReducesScoreBy22() {
        let nn = Fixtures.makeProtocol(state: .recovery)
        let score = ReliabilityCalculator.calculateCockpitScore(for: [nn], referenceDate: Fixtures.referenceDate)
        // 92 - 22 = 70
        XCTAssertEqual(score, 70)
    }
    
    func testViolationsReduceScoreBy16() {
        var nn = Fixtures.makeProtocol()
        let weekId = DateRules.weekID(for: Fixtures.referenceDate, calendar: Fixtures.calendar)
        nn.violations = [
            Violation(date: Fixtures.referenceDate, kind: .missedWeeklyFrequency, windowIndex: 0, weekId: weekId)
        ]
        let score = ReliabilityCalculator.calculateCockpitScore(for: [nn], referenceDate: Fixtures.referenceDate)
        // 92 - 16 = 76
        XCTAssertEqual(score, 76)
    }

    func testEmptySystemReturns92() {
        let score = ReliabilityCalculator.calculateCockpitScore(for: [], referenceDate: Fixtures.referenceDate)
        XCTAssertEqual(score, 92)
    }
}
