import XCTest
@testable import LockedIn

@MainActor
final class RecoveryModeTests: XCTestCase {
    private let calendar = DateRules.isoCalendar
    private let migrationSentinelKey = "didRunThresholdMigration20260506"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: migrationSentinelKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: migrationSentinelKey)
        super.tearDown()
    }

    func testA_nonNegotiableStateTerminalFlags() {
        XCTAssertTrue(NonNegotiableState.retired.isTerminal)
        XCTAssertTrue(NonNegotiableState.completed.isTerminal)

        XCTAssertFalse(NonNegotiableState.active.isTerminal)
        XCTAssertFalse(NonNegotiableState.recovery.isTerminal)
        XCTAssertFalse(NonNegotiableState.suspended.isTerminal)
    }

    func testB_recoveryViolationThresholdsByMode() throws {
        var dailyAtThreshold = try makeNonNegotiable(title: "Daily at threshold", mode: .daily)
        addViolations(count: 2, to: &dailyAtThreshold, startingDayOffset: 1, kind: .missedDailyCompliance)
        addCountedCompletions(to: &dailyAtThreshold, dayOffsets: 0...6)
        evaluateCurrentWeek(&dailyAtThreshold)
        XCTAssertEqual(dailyAtThreshold.state, .recovery)

        var dailyBelowThreshold = try makeNonNegotiable(title: "Daily below threshold", mode: .daily)
        addViolations(count: 1, to: &dailyBelowThreshold, startingDayOffset: 1, kind: .missedDailyCompliance)
        addCountedCompletions(to: &dailyBelowThreshold, dayOffsets: 0...6)
        evaluateCurrentWeek(&dailyBelowThreshold)
        XCTAssertEqual(dailyBelowThreshold.state, .active)

        var sessionAtThreshold = try makeNonNegotiable(title: "Session at threshold", mode: .session)
        addViolations(count: 1, to: &sessionAtThreshold, startingDayOffset: 1, kind: .missedWeeklyFrequency)
        addCountedCompletions(to: &sessionAtThreshold, dayOffsets: 2...2)
        evaluateCurrentWeek(&sessionAtThreshold)
        XCTAssertEqual(sessionAtThreshold.state, .recovery)

        var sessionBelowThreshold = try makeNonNegotiable(title: "Session below threshold", mode: .session)
        addCountedCompletions(to: &sessionBelowThreshold, dayOffsets: 2...2)
        evaluateCurrentWeek(&sessionBelowThreshold)
        XCTAssertEqual(sessionBelowThreshold.state, .active)
    }

    func testC_recoveryPauseCandidateIdsOnlyIncludesActiveProtocols() throws {
        let recovering = try makeNonNegotiable(title: "Recovering", state: .recovery, mode: .session)
        let active = try makeNonNegotiable(title: "Active", state: .active, mode: .session, startDayOffset: 1)
        let systemWithActiveCandidate = CommitmentSystem(
            nonNegotiables: [recovering, active],
            createdAt: testDate(day: 5),
            recoveryEntryPendingResolution: true,
            recoveryEntryRequiresPauseSelection: true,
            recoveryEntryTriggerProtocolId: recovering.id
        )
        let storeWithActiveCandidate = makeStore(system: systemWithActiveCandidate)

        XCTAssertEqual(storeWithActiveCandidate.recoveryEntryContext()?.candidateProtocolIds, [active.id])

        let recoveryOnlySystem = CommitmentSystem(
            nonNegotiables: [recovering],
            createdAt: testDate(day: 5),
            recoveryEntryPendingResolution: true,
            recoveryEntryRequiresPauseSelection: true,
            recoveryEntryTriggerProtocolId: recovering.id
        )
        let recoveryOnlyStore = makeStore(system: recoveryOnlySystem)

        XCTAssertEqual(recoveryOnlyStore.recoveryEntryContext()?.candidateProtocolIds, [])
    }

    func testD_normalizeRecoveryDomainSingleProtocolAutoExit() throws {
        let engine = makeSystemEngine()
        let referenceDate = testDate(day: 10)

        var oneRecovery = CommitmentSystem(
            nonNegotiables: [try makeNonNegotiable(title: "Recovering", state: .recovery, mode: .session)],
            createdAt: testDate(day: 5)
        )
        let oneRecoveryDecision = engine.normalizeRecoveryDomain(in: &oneRecovery, referenceDate: referenceDate)
        XCTAssertTrue(oneRecoveryDecision.exitedRecovery)
        XCTAssertFalse(oneRecovery.nonNegotiables.contains { $0.state == .recovery })

        var twoRecovery = CommitmentSystem(
            nonNegotiables: [
                try makeNonNegotiable(title: "Recovering A", state: .recovery, mode: .session),
                try makeNonNegotiable(title: "Recovering B", state: .recovery, mode: .session, startDayOffset: 1)
            ],
            createdAt: testDate(day: 5)
        )
        let twoRecoveryDecision = engine.normalizeRecoveryDomain(in: &twoRecovery, referenceDate: referenceDate)
        XCTAssertTrue(twoRecoveryDecision.exitedRecovery)
        XCTAssertFalse(twoRecovery.nonNegotiables.contains { $0.state == .recovery })

        var recoveryWithActive = CommitmentSystem(
            nonNegotiables: [
                try makeNonNegotiable(title: "Recovering", state: .recovery, mode: .session),
                try makeNonNegotiable(title: "Active", state: .active, mode: .session, startDayOffset: 1)
            ],
            createdAt: testDate(day: 5)
        )
        let recoveryWithActiveDecision = engine.normalizeRecoveryDomain(
            in: &recoveryWithActive,
            referenceDate: referenceDate
        )
        XCTAssertFalse(recoveryWithActiveDecision.exitedRecovery)
        XCTAssertTrue(recoveryWithActive.nonNegotiables.contains { $0.state == .recovery })
    }

    func testE_postDecodeValidationClearsStaleTerminalRecoveryIds() throws {
        let completed = try makeNonNegotiable(title: "Completed", state: .completed, mode: .session)
        let terminalSystem = CommitmentSystem(
            nonNegotiables: [completed],
            createdAt: testDate(day: 5),
            recoveryEntryTriggerProtocolId: completed.id,
            recoveryPausedProtocolId: completed.id
        )

        let decodedTerminalSystem = try roundTrip(terminalSystem)

        XCTAssertNil(decodedTerminalSystem.recoveryEntryTriggerProtocolId)
        XCTAssertNil(decodedTerminalSystem.recoveryPausedProtocolId)

        let suspended = try makeNonNegotiable(title: "Suspended", state: .suspended, mode: .session)
        let suspendedSystem = CommitmentSystem(
            nonNegotiables: [suspended],
            createdAt: testDate(day: 5),
            recoveryPausedProtocolId: suspended.id
        )

        let decodedSuspendedSystem = try roundTrip(suspendedSystem)

        XCTAssertEqual(decodedSuspendedSystem.recoveryPausedProtocolId, suspended.id)
    }

    func testF_thresholdMigrationPromotesOnlyAtThresholdAndRunsOnce() throws {
        let referenceDate = testDate(day: 8)
        var atThreshold = try makeNonNegotiable(title: "Daily at threshold", mode: .daily)
        addViolations(count: 2, to: &atThreshold, startingDayOffset: 1, kind: .missedDailyCompliance)
        var belowThreshold = try makeNonNegotiable(title: "Daily below threshold", mode: .daily, startDayOffset: 1)
        addViolations(count: 1, to: &belowThreshold, startingDayOffset: 2, kind: .missedDailyCompliance)
        let store = makeStore(system: CommitmentSystem(
            nonNegotiables: [atThreshold, belowThreshold],
            createdAt: testDate(day: 5)
        ))

        store.runThresholdMigrationIfNeeded(referenceDate: referenceDate)

        XCTAssertEqual(store.nonNegotiable(id: atThreshold.id)?.state, .recovery)
        XCTAssertEqual(store.nonNegotiable(id: belowThreshold.id)?.state, .active)

        var secondAtThreshold = try makeNonNegotiable(title: "Second daily at threshold", mode: .daily)
        addViolations(count: 2, to: &secondAtThreshold, startingDayOffset: 1, kind: .missedDailyCompliance)
        let secondStore = makeStore(system: CommitmentSystem(
            nonNegotiables: [secondAtThreshold],
            createdAt: testDate(day: 5)
        ))

        secondStore.runThresholdMigrationIfNeeded(referenceDate: referenceDate)

        XCTAssertEqual(secondStore.nonNegotiable(id: secondAtThreshold.id)?.state, .active)
    }

    func testG_recoveryEntryTriggerSelectsMostViolationsThenOldestCreatedAt() throws {
        let referenceDate = testDate(day: 8)
        var twoViolations = try makeNonNegotiable(title: "Two violations", mode: .daily)
        addViolations(count: 2, to: &twoViolations, startingDayOffset: 1, kind: .missedDailyCompliance)
        var threeViolations = try makeNonNegotiable(title: "Three violations", mode: .daily, startDayOffset: 1)
        addViolations(count: 3, to: &threeViolations, startingDayOffset: 2, kind: .missedDailyCompliance)
        let moreViolationsStore = makeStore(system: CommitmentSystem(
            nonNegotiables: [twoViolations, threeViolations],
            createdAt: testDate(day: 5)
        ))

        moreViolationsStore.runThresholdMigrationIfNeeded(referenceDate: referenceDate)

        XCTAssertEqual(moreViolationsStore.system.recoveryEntryTriggerProtocolId, threeViolations.id)

        UserDefaults.standard.removeObject(forKey: migrationSentinelKey)

        var older = try makeNonNegotiable(title: "Older", mode: .daily)
        addViolations(count: 2, to: &older, startingDayOffset: 1, kind: .missedDailyCompliance)
        var newer = try makeNonNegotiable(title: "Newer", mode: .daily, startDayOffset: 1)
        addViolations(count: 2, to: &newer, startingDayOffset: 2, kind: .missedDailyCompliance)
        let equalViolationStore = makeStore(system: CommitmentSystem(
            nonNegotiables: [newer, older],
            createdAt: testDate(day: 5)
        ))

        equalViolationStore.runThresholdMigrationIfNeeded(referenceDate: referenceDate)

        XCTAssertEqual(equalViolationStore.system.recoveryEntryTriggerProtocolId, older.id)
    }

    func testH_recoveryCleanDayStreakExitsAfterSevenCleanDays() throws {
        let engine = makeSystemEngine()
        var recovering = try makeNonNegotiable(title: "Recovering", state: .recovery, mode: .session)
        var system = CommitmentSystem(nonNegotiables: [recovering], createdAt: testDate(day: 5))

        for offset in 1...7 {
            let cleanDay = testDate(day: 5 + offset)
            recovering.completions.append(CompletionRecord(
                date: testDate(day: 5 + offset, hour: 9),
                weekId: DateRules.weekID(for: cleanDay, calendar: calendar),
                kind: .counted
            ))
            system.nonNegotiables[0] = recovering

            let referenceDate = testDate(day: 6 + offset)
            engine.evaluateRecoveryDay(referenceDate: referenceDate, in: &system, calendar: calendar)

            if offset < 7 {
                XCTAssertEqual(system.recoveryCleanDayStreak, offset)
                XCTAssertEqual(system.nonNegotiables[0].state, .recovery)
            }
        }

        XCTAssertEqual(system.recoveryCleanDayStreak, 0)
        XCTAssertEqual(system.nonNegotiables[0].state, .active)
    }

    private func makeStore(system: CommitmentSystem) -> CommitmentSystemStore {
        let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
        return CommitmentSystemStore(
            repository: InMemoryCommitmentSystemRepository(initialSystem: system),
            systemEngine: CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine),
            nonNegotiableEngine: nonNegotiableEngine,
            policy: CommitmentPolicyEngine(calendar: calendar),
            streakEngine: StreakEngine(),
            calendar: calendar
        )
    }

    private func makeSystemEngine() -> CommitmentSystemEngine {
        CommitmentSystemEngine(nonNegotiableEngine: NonNegotiableEngine(calendar: calendar))
    }

    private func makeNonNegotiable(
        title: String,
        state: NonNegotiableState = .active,
        mode: NonNegotiableMode,
        frequencyPerWeek: Int = 1,
        startDayOffset: Int = 0
    ) throws -> NonNegotiable {
        let startDate = DateRules.addingDays(startDayOffset, to: testDate(day: 5), calendar: calendar)
        let definition = NonNegotiableDefinition(
            title: title,
            frequencyPerWeek: mode == .daily ? 7 : frequencyPerWeek,
            mode: mode,
            goalId: UUID()
        )
        var nonNegotiable = try NonNegotiableEngine(calendar: calendar).create(
            definition: definition,
            startDate: startDate,
            totalLockDays: 28
        )
        nonNegotiable.state = state
        return nonNegotiable
    }

    private func addViolations(
        count: Int,
        to nonNegotiable: inout NonNegotiable,
        startingDayOffset: Int,
        kind: ViolationKind
    ) {
        guard count > 0 else { return }

        for offset in startingDayOffset..<(startingDayOffset + count) {
            let date = DateRules.addingDays(offset, to: nonNegotiable.lock.startDate, calendar: calendar)
            nonNegotiable.violations.append(Violation(
                date: date,
                kind: kind,
                windowIndex: 0,
                weekId: DateRules.weekID(for: date, calendar: calendar)
            ))
        }
    }

    private func addCountedCompletions(
        to nonNegotiable: inout NonNegotiable,
        dayOffsets: ClosedRange<Int>
    ) {
        for offset in dayOffsets {
            let day = DateRules.addingDays(offset, to: nonNegotiable.lock.startDate, calendar: calendar)
            let completionDate = DateRules.addingDays(offset, to: nonNegotiable.lock.startDate, calendar: calendar)
            nonNegotiable.completions.append(CompletionRecord(
                date: completionDate,
                weekId: DateRules.weekID(for: day, calendar: calendar),
                kind: .counted
            ))
        }
    }

    private func evaluateCurrentWeek(_ nonNegotiable: inout NonNegotiable) {
        let weekEnding = DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar)
        NonNegotiableEngine(calendar: calendar).evaluateWeekIfNeeded(&nonNegotiable, weekEnding: weekEnding)
    }

    private func roundTrip(_ system: CommitmentSystem) throws -> CommitmentSystem {
        let data = try JSONEncoder().encode(system)
        return try JSONDecoder().decode(CommitmentSystem.self, from: data)
    }

    private func testDate(day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        DateRules.date(year: 2026, month: 1, day: day, hour: hour, minute: minute, calendar: calendar)
    }
}
