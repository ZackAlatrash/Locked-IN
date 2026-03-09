import XCTest
@testable import LockedIn

@MainActor
final class CommitmentSystemStoreBehaviorLockTests: XCTestCase {
    func testRunDailyIntegrityTick_seventhCleanRecoveryDayPromotesRecoveryAndClearsEntryState() {
        let referenceDate = CommitmentSystemStoreTestFixtures.referenceDate
        let recoveryProtocol = CommitmentSystemStoreTestFixtures.makeProtocol(
            title: "Recovery Protocol",
            mode: .session,
            frequencyPerWeek: 1,
            state: .recovery,
            completions: [
                CommitmentSystemStoreTestFixtures.makeCompletion(date: referenceDate, kind: .counted)
            ]
        )
        let initialSystem = CommitmentSystemStoreTestFixtures.makeSystem(
            nonNegotiables: [recoveryProtocol],
            recoveryCleanDayStreak: 6,
            recoveryEntryPendingResolution: true,
            recoveryEntryRequiresPauseSelection: false,
            recoveryEntryTriggerProtocolId: recoveryProtocol.id,
            recoveryPausedProtocolId: UUID()
        )
        let (store, repository) = makeStore(system: initialSystem)

        store.runDailyIntegrityTick(referenceDate: referenceDate)

        XCTAssertEqual(store.system.nonNegotiables.first?.state, .active)
        XCTAssertEqual(store.system.recoveryCleanDayStreak, 0)
        XCTAssertEqual(
            store.system.lastRecoveryEvaluationDay,
            DateRules.startOfDay(referenceDate, calendar: CommitmentSystemStoreTestFixtures.calendar)
        )
        XCTAssertFalse(store.system.recoveryEntryPendingResolution)
        XCTAssertFalse(store.system.recoveryEntryRequiresPauseSelection)
        XCTAssertNil(store.system.recoveryEntryTriggerProtocolId)
        XCTAssertNil(store.system.recoveryPausedProtocolId)
        XCTAssertEqual(repository.saveCalls.count, 1)
    }

    func testRecoveryEntryContext_returnsPendingRecoveryCandidatesAndFlags() {
        let activeProtocol = CommitmentSystemStoreTestFixtures.makeProtocol(
            title: "Active",
            state: .active
        )
        let recoveryProtocol = CommitmentSystemStoreTestFixtures.makeProtocol(
            title: "Recovery",
            state: .recovery
        )
        let suspendedProtocol = CommitmentSystemStoreTestFixtures.makeProtocol(
            title: "Suspended",
            state: .suspended
        )
        let initialSystem = CommitmentSystemStoreTestFixtures.makeSystem(
            nonNegotiables: [activeProtocol, recoveryProtocol, suspendedProtocol],
            recoveryEntryPendingResolution: true,
            recoveryEntryRequiresPauseSelection: true,
            recoveryEntryTriggerProtocolId: recoveryProtocol.id,
            recoveryPausedProtocolId: suspendedProtocol.id
        )
        let (store, _) = makeStore(system: initialSystem)

        let context = store.recoveryEntryContext(referenceDate: CommitmentSystemStoreTestFixtures.referenceDate)

        XCTAssertEqual(
            context,
            CommitmentSystemStore.RecoveryEntryContext(
                triggerProtocolId: recoveryProtocol.id,
                pausedProtocolId: suspendedProtocol.id,
                requiresPauseSelection: true,
                candidateProtocolIds: [activeProtocol.id, recoveryProtocol.id]
            )
        )
    }

    func testPauseProtocolForRecovery_updatesProtocolStateAndRecoveryFlags() throws {
        let recoveryProtocol = CommitmentSystemStoreTestFixtures.makeProtocol(
            title: "Recovery",
            state: .recovery
        )
        let activeProtocol = CommitmentSystemStoreTestFixtures.makeProtocol(
            title: "Active",
            state: .active
        )
        let initialSystem = CommitmentSystemStoreTestFixtures.makeSystem(
            nonNegotiables: [recoveryProtocol, activeProtocol],
            recoveryEntryPendingResolution: true,
            recoveryEntryRequiresPauseSelection: true,
            recoveryEntryTriggerProtocolId: recoveryProtocol.id
        )
        let (store, repository) = makeStore(system: initialSystem)

        try store.pauseProtocolForRecovery(
            protocolId: activeProtocol.id,
            referenceDate: CommitmentSystemStoreTestFixtures.referenceDate
        )

        let paused = store.system.nonNegotiables.first { $0.id == activeProtocol.id }
        XCTAssertEqual(paused?.state, .suspended)
        XCTAssertTrue(store.system.recoveryEntryPendingResolution)
        XCTAssertFalse(store.system.recoveryEntryRequiresPauseSelection)
        XCTAssertEqual(store.system.recoveryEntryTriggerProtocolId, recoveryProtocol.id)
        XCTAssertEqual(store.system.recoveryPausedProtocolId, activeProtocol.id)
        XCTAssertEqual(repository.saveCalls.count, 1)
    }

    func testCompleteRecoveryEntryResolution_clearsPendingFlagsAndTriggerOnly() {
        let recoveryProtocol = CommitmentSystemStoreTestFixtures.makeProtocol(
            title: "Recovery",
            state: .recovery
        )
        let pausedProtocolId = UUID()
        let initialSystem = CommitmentSystemStoreTestFixtures.makeSystem(
            nonNegotiables: [recoveryProtocol],
            recoveryEntryPendingResolution: true,
            recoveryEntryRequiresPauseSelection: true,
            recoveryEntryTriggerProtocolId: recoveryProtocol.id,
            recoveryPausedProtocolId: pausedProtocolId
        )
        let (store, repository) = makeStore(system: initialSystem)

        store.completeRecoveryEntryResolution()

        XCTAssertFalse(store.system.recoveryEntryPendingResolution)
        XCTAssertFalse(store.system.recoveryEntryRequiresPauseSelection)
        XCTAssertNil(store.system.recoveryEntryTriggerProtocolId)
        XCTAssertEqual(store.system.recoveryPausedProtocolId, pausedProtocolId)
        XCTAssertEqual(repository.saveCalls.count, 1)
    }
}

private extension CommitmentSystemStoreBehaviorLockTests {
    func makeStore(
        system: CommitmentSystem
    ) -> (CommitmentSystemStore, RecordingCommitmentSystemRepository) {
        let repository = RecordingCommitmentSystemRepository(initialSystem: system)
        let nonNegotiableEngine = NonNegotiableEngine(calendar: CommitmentSystemStoreTestFixtures.calendar)
        let systemEngine = CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine)
        let store = CommitmentSystemStore(
            repository: repository,
            systemEngine: systemEngine,
            nonNegotiableEngine: nonNegotiableEngine,
            policy: CommitmentPolicyEngine(calendar: CommitmentSystemStoreTestFixtures.calendar),
            streakEngine: StreakEngine(calendar: CommitmentSystemStoreTestFixtures.calendar),
            calendar: CommitmentSystemStoreTestFixtures.calendar
        )
        CommitmentSystemStoreTestRetainer.retain(store)
        return (store, repository)
    }
}
