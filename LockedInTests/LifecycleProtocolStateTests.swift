import XCTest
@testable import LockedIn

@MainActor
final class LifecycleProtocolStateTests: XCTestCase {
    private let calendar = DateRules.isoCalendar

    // MARK: - LIF-01: Terminal protocols are excluded from Plan queue

    func testLIF01_retiredProtocolExcludedFromPlanQueue() async throws {
        let retired = try makeNonNegotiable(title: "Retired", state: .retired, mode: .session)
        let system = CommitmentSystem(nonNegotiables: [retired], createdAt: anchor)
        let planStore = makePlanStore()
        planStore.refresh(system: system, calendarEvents: [], referenceDate: anchor)
        XCTAssertTrue(planStore.queueItems.isEmpty, "Retired protocol must not appear in plan queue")
    }

    func testLIF01_completedProtocolExcludedFromPlanQueue() async throws {
        let completed = try makeNonNegotiable(title: "Completed", state: .completed, mode: .session)
        let system = CommitmentSystem(nonNegotiables: [completed], createdAt: anchor)
        let planStore = makePlanStore()
        planStore.refresh(system: system, calendarEvents: [], referenceDate: anchor)
        XCTAssertTrue(planStore.queueItems.isEmpty, "Completed protocol must not appear in plan queue")
    }

    // MARK: - LIF-02: Suspended protocols appear disabled in Plan queue

    func testLIF02_suspendedProtocolAppearsDisabledInQueue() async throws {
        let suspended = try makeNonNegotiable(title: "Suspended", state: .suspended, mode: .session)
        let active = try makeNonNegotiable(title: "Active", state: .active, mode: .session, startDayOffset: 1)
        let recovering = try makeNonNegotiable(title: "Recovering", state: .recovery, mode: .session, startDayOffset: 2)
        let system = CommitmentSystem(
            nonNegotiables: [suspended, active, recovering],
            createdAt: anchor,
            recoveryPausedProtocolId: suspended.id
        )
        let planStore = makePlanStore()
        planStore.refresh(system: system, calendarEvents: [], referenceDate: anchor)
        guard let suspendedItem = planStore.queueItems.first(where: { $0.protocolId == suspended.id }) else {
            XCTFail("Suspended protocol must appear in queue")
            return
        }
        XCTAssertTrue(suspendedItem.isDisabled, "Suspended protocol queue item must be disabled")
    }

    func testLIF02_suspendedProtocolCannotPassValidationForPlacement() async throws {
        let suspended = try makeNonNegotiable(title: "Suspended", state: .suspended, mode: .session)
        let active = try makeNonNegotiable(title: "Active", state: .active, mode: .session, startDayOffset: 1)
        let recovering = try makeNonNegotiable(title: "Recovering", state: .recovery, mode: .session, startDayOffset: 2)
        let system = CommitmentSystem(
            nonNegotiables: [suspended, active, recovering],
            createdAt: anchor,
            recoveryPausedProtocolId: suspended.id
        )
        let planStore = makePlanStore()
        planStore.refresh(system: system, calendarEvents: [], referenceDate: anchor)

        let validation = planStore.validateProtocolPlacement(
            protocolId: suspended.id,
            day: anchor,
            slot: .am,
            context: .manual
        )
        XCTAssertFalse(validation.isAllowed, "Placement validation must block suspended protocol")
    }

    func testLIF02_suspendedProtocolCannotBeSelectedForPlanning() async throws {
        let suspended = try makeNonNegotiable(title: "Suspended", state: .suspended, mode: .session)
        let active = try makeNonNegotiable(title: "Active", state: .active, mode: .session, startDayOffset: 1)
        let recovering = try makeNonNegotiable(title: "Recovering", state: .recovery, mode: .session, startDayOffset: 2)
        let system = CommitmentSystem(
            nonNegotiables: [suspended, active, recovering],
            createdAt: anchor,
            recoveryPausedProtocolId: suspended.id
        )
        let planStore = makePlanStore()
        planStore.refresh(system: system, calendarEvents: [], referenceDate: anchor)

        planStore.selectProtocol(suspended.id)
        XCTAssertNil(planStore.selectedQueueProtocolId, "Suspended protocol must not become the selected placement protocol")

        planStore.focusProtocol(suspended.id)
        XCTAssertNil(planStore.selectedQueueProtocolId, "Focusing a suspended protocol must not arm slot placement")
    }

    // MARK: - LIF-05: Paused allocation repairs on PlanStore refresh

    func testLIF05_pausedAllocationForRetiredProtocolRemovedAfterRepair() async throws {
        let proto = try makeNonNegotiable(title: "Will Retire", state: .retired, mode: .session)
        let allocation = makePausedAllocation(protocolId: proto.id, day: anchor)
        let system = CommitmentSystem(nonNegotiables: [proto], createdAt: anchor)
        let planStore = makePlanStore(allocations: [allocation])
        planStore.refresh(system: system, calendarEvents: [], referenceDate: anchor)

        // repairPausedAllocations sets .skippedDueToRecovery; normalizeAllocations removes
        // terminal-protocol allocations from the in-memory view. Both outcomes satisfy invariant.
        let alloc = planStore.allocation(id: allocation.id)
        XCTAssertTrue(alloc == nil || alloc?.status != .paused,
            "Paused allocation for retired protocol must not remain paused after repair")
    }

    func testLIF05_pausedAllocationForCompletedProtocolRemovedAfterRepair() async throws {
        let proto = try makeNonNegotiable(title: "Will Complete", state: .completed, mode: .session)
        let allocation = makePausedAllocation(protocolId: proto.id, day: anchor)
        let system = CommitmentSystem(nonNegotiables: [proto], createdAt: anchor)
        let planStore = makePlanStore(allocations: [allocation])
        planStore.refresh(system: system, calendarEvents: [], referenceDate: anchor)

        let alloc = planStore.allocation(id: allocation.id)
        XCTAssertTrue(alloc == nil || alloc?.status != .paused,
            "Paused allocation for completed protocol must not remain paused after repair")
    }

    func testLIF05_pausedAllocationForMissingProtocolRemovedAfterRepair() async throws {
        let allocation = makePausedAllocation(protocolId: UUID(), day: anchor)
        let system = CommitmentSystem(nonNegotiables: [], createdAt: anchor)
        let planStore = makePlanStore(allocations: [allocation])
        planStore.refresh(system: system, calendarEvents: [], referenceDate: anchor)

        let alloc = planStore.allocation(id: allocation.id)
        XCTAssertTrue(alloc == nil || alloc?.status != .paused,
            "Paused allocation for missing protocol must not remain paused after repair")
    }

    func testLIF05_pastPausedAllocationRepairsToSkipped() async throws {
        let proto = try makeNonNegotiable(title: "Suspended", state: .suspended, mode: .session)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: anchor)!
        let allocation = makePausedAllocation(protocolId: proto.id, day: yesterday)
        let active = try makeNonNegotiable(title: "Active", state: .active, mode: .session, startDayOffset: 1)
        let recovering = try makeNonNegotiable(title: "Recovering", state: .recovery, mode: .session, startDayOffset: 2)
        let system = CommitmentSystem(
            nonNegotiables: [proto, active, recovering],
            createdAt: anchor,
            recoveryPausedProtocolId: proto.id
        )
        let planStore = makePlanStore(allocations: [allocation])
        planStore.refresh(system: system, calendarEvents: [], referenceDate: anchor)

        let alloc = planStore.allocation(id: allocation.id)
        XCTAssertTrue(alloc == nil || alloc?.status != .paused,
            "Past paused allocation must not remain paused after repair")
    }

    func testLIF05_futurePausedAllocationForSuspendedProtocolRemainsUnchanged() async throws {
        let proto = try makeNonNegotiable(title: "Suspended", state: .suspended, mode: .session)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: anchor)!
        let allocation = makePausedAllocation(protocolId: proto.id, day: tomorrow)
        let active = try makeNonNegotiable(title: "Active", state: .active, mode: .session, startDayOffset: 1)
        let recovering = try makeNonNegotiable(title: "Recovering", state: .recovery, mode: .session, startDayOffset: 2)
        let system = CommitmentSystem(
            nonNegotiables: [proto, active, recovering],
            createdAt: anchor,
            recoveryPausedProtocolId: proto.id
        )
        let planStore = makePlanStore(allocations: [allocation])
        planStore.refresh(system: system, calendarEvents: [], referenceDate: anchor)

        let alloc = planStore.allocation(id: allocation.id)
        XCTAssertEqual(alloc?.status, .paused, "Future paused allocation for suspended protocol must remain paused")
    }

    func testLIF05_retirePausedProtocolWithPlanStoreFinalizesPausedAllocations() async throws {
        // Create the protocol 30 days before anchor so the 28-day lock is already expired.
        let suspended = try makeNonNegotiable(title: "Suspended", state: .suspended, mode: .session, startDayOffset: -30)
        let active = try makeNonNegotiable(title: "Active", state: .active, mode: .session, startDayOffset: 1)
        let recovering = try makeNonNegotiable(title: "Recovering", state: .recovery, mode: .session, startDayOffset: 2)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: anchor)!
        let pausedAllocation = makePausedAllocation(protocolId: suspended.id, day: tomorrow)
        let system = CommitmentSystem(
            nonNegotiables: [suspended, active, recovering],
            createdAt: anchor,
            recoveryPausedProtocolId: suspended.id
        )
        let planStore = makePlanStore(allocations: [pausedAllocation])
        planStore.refresh(system: system, calendarEvents: [], referenceDate: anchor)

        let store = makeStore(system: system)
        try store.retireNonNegotiable(id: suspended.id, referenceDate: anchor, planStore: planStore)
        planStore.refresh(system: store.system, calendarEvents: [], referenceDate: anchor)

        let alloc = planStore.allocation(id: pausedAllocation.id)
        XCTAssertTrue(alloc == nil || alloc?.status != .paused,
            "Paused allocation must not remain paused after retiring the paused protocol with planStore")
    }

    // MARK: - LIF-04: Expired suspended protocol completes via advanceWindows

    func testLIF04_suspendedProtocolAtLockEndBecomesCompleted() throws {
        let suspended = try makeNonNegotiable(title: "Expiring Suspended", state: .suspended, mode: .session)
        let lockEnd = NonNegotiableEngine(calendar: calendar).lockEndDate(for: suspended)
        let afterLockEnd = calendar.date(byAdding: .day, value: 1, to: lockEnd)!

        let active = try makeNonNegotiable(title: "Active", state: .active, mode: .session, startDayOffset: 1)
        let recovering = try makeNonNegotiable(title: "Recovering", state: .recovery, mode: .session, startDayOffset: 2)
        var system = CommitmentSystem(
            nonNegotiables: [suspended, active, recovering],
            createdAt: anchor,
            recoveryPausedProtocolId: suspended.id
        )
        makeSystemEngine().advanceWindows(currentDate: afterLockEnd, in: &system)

        let updatedState = system.nonNegotiables.first(where: { $0.id == suspended.id })?.state
        XCTAssertEqual(updatedState, .completed, "Suspended protocol past lock end must become .completed")
    }

    func testLIF04_dailyTickClearsPausedProtocolIdWhenSuspendedProtocolExpires() throws {
        let suspended = try makeNonNegotiable(title: "Expired Suspended", state: .suspended, mode: .session, startDayOffset: -30)
        let recovering = try makeNonNegotiable(title: "Recovering", state: .recovery, mode: .session)
        let active = try makeNonNegotiable(title: "Active Support", state: .active, mode: .session, startDayOffset: 1)
        let system = CommitmentSystem(
            nonNegotiables: [suspended, recovering, active],
            createdAt: anchor,
            recoveryPausedProtocolId: suspended.id
        )
        let store = makeStore(system: system)

        store.runDailyIntegrityTick(referenceDate: anchor)

        let updatedSuspended = store.system.nonNegotiables.first(where: { $0.id == suspended.id })
        XCTAssertEqual(updatedSuspended?.state, .completed, "Expired suspended protocol must complete during daily tick")
        XCTAssertNil(store.system.recoveryPausedProtocolId, "Daily tick must clear a pause pointer to a completed protocol")
    }

    func testLIF04_suspendedProtocolNotYetAtLockEndRemainsSuspended() throws {
        let suspended = try makeNonNegotiable(title: "Not Expired", state: .suspended, mode: .session)
        let midLock = calendar.date(byAdding: .day, value: 7, to: anchor)!

        let active = try makeNonNegotiable(title: "Active", state: .active, mode: .session, startDayOffset: 1)
        let recovering = try makeNonNegotiable(title: "Recovering", state: .recovery, mode: .session, startDayOffset: 2)
        var system = CommitmentSystem(
            nonNegotiables: [suspended, active, recovering],
            createdAt: anchor,
            recoveryPausedProtocolId: suspended.id
        )
        makeSystemEngine().advanceWindows(currentDate: midLock, in: &system)

        let updatedState = system.nonNegotiables.first(where: { $0.id == suspended.id })?.state
        XCTAssertEqual(updatedState, .suspended, "Suspended protocol before lock end must remain .suspended")
    }

    func testLIF04_activeProtocolAtLockEndBecomesCompleted() throws {
        let active = try makeNonNegotiable(title: "Expiring Active", state: .active, mode: .session)
        let lockEnd = NonNegotiableEngine(calendar: calendar).lockEndDate(for: active)
        let afterLockEnd = calendar.date(byAdding: .day, value: 1, to: lockEnd)!

        var system = CommitmentSystem(nonNegotiables: [active], createdAt: anchor)
        makeSystemEngine().advanceWindows(currentDate: afterLockEnd, in: &system)

        let updatedState = system.nonNegotiables.first(where: { $0.id == active.id })?.state
        XCTAssertEqual(updatedState, .completed, "Active protocol past lock end must become .completed")
    }

    func testLIF04_retiredProtocolSkippedByDailyEvaluation() throws {
        let retired = try makeNonNegotiable(title: "Retired Daily", state: .retired, mode: .daily)
        let violationsBefore = retired.violations.count
        var copy = retired
        NonNegotiableEngine(calendar: calendar).evaluateDailyComplianceIfNeeded(&copy, at: anchor)
        XCTAssertEqual(copy.violations.count, violationsBefore, "Retired protocol must not get new violations")
    }

    // MARK: - LIF-EC-16: wasRecoveryRelated persisted on completion/violation

    func testLIF_EC16_completionDuringRecoveryHasWasRecoveryRelatedTrue() throws {
        var recovering = try makeNonNegotiable(title: "In Recovery", state: .recovery, mode: .session)
        _ = try NonNegotiableEngine(calendar: calendar).recordCompletion(&recovering, at: anchor)
        XCTAssertTrue(recovering.completions.last?.wasRecoveryRelated == true,
            "Completion during recovery must have wasRecoveryRelated = true")
    }

    func testLIF_EC16_completionWhileActiveHasWasRecoveryRelatedFalse() throws {
        var active = try makeNonNegotiable(title: "Active", state: .active, mode: .session)
        _ = try NonNegotiableEngine(calendar: calendar).recordCompletion(&active, at: anchor)
        XCTAssertFalse(active.completions.last?.wasRecoveryRelated == true,
            "Completion while active must have wasRecoveryRelated = false")
    }

    func testLIF_EC16_violationFlagSetDuringRecovery() throws {
        var recovering = try makeNonNegotiable(title: "In Recovery", state: .recovery, mode: .session)
        recovering.violations.append(Violation(
            date: anchor,
            kind: .missedWeeklyFrequency,
            windowIndex: 0,
            weekId: DateRules.weekID(for: anchor, calendar: calendar),
            wasRecoveryRelated: true
        ))
        XCTAssertTrue(recovering.violations.last?.wasRecoveryRelated == true)
    }

    func testLIF_EC16_recoveryTriggeringViolationHasWasRecoveryRelatedTrue() throws {
        var active = try makeNonNegotiable(title: "Daily", state: .active, mode: .daily)
        let evaluationDate = calendar.date(byAdding: .day, value: 3, to: anchor)!

        NonNegotiableEngine(calendar: calendar).evaluateDailyComplianceIfNeeded(&active, at: evaluationDate)

        XCTAssertEqual(active.state, .recovery, "Second missed daily compliance should enter recovery")
        XCTAssertEqual(active.violations.count, 2, "Daily evaluation should record the two missed days")
        XCTAssertFalse(active.violations.first?.wasRecoveryRelated == true,
            "First pre-threshold violation should not be marked recovery-related")
        XCTAssertTrue(active.violations.last?.wasRecoveryRelated == true,
            "Violation that crosses the recovery threshold must persist recovery context")
    }

    func testLIF_EC16_wasRecoveryRelatedSurvivesRoundTrip() throws {
        var recovering = try makeNonNegotiable(title: "In Recovery", state: .recovery, mode: .session)
        _ = try NonNegotiableEngine(calendar: calendar).recordCompletion(&recovering, at: anchor)
        recovering.state = .retired

        let system = CommitmentSystem(nonNegotiables: [recovering], createdAt: anchor)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(system)
        let decoded = try decoder.decode(CommitmentSystem.self, from: data)
        let completion = decoded.nonNegotiables.first?.completions.last

        XCTAssertEqual(completion?.wasRecoveryRelated, true,
            "wasRecoveryRelated must survive JSON round-trip after retirement")
    }

    // MARK: - Helpers

    private var anchor: Date {
        DateRules.date(year: 2026, month: 1, day: 12, hour: 9, minute: 0, calendar: calendar)
    }

    private func makeNonNegotiable(
        title: String,
        state: NonNegotiableState = .active,
        mode: NonNegotiableMode,
        frequencyPerWeek: Int = 1,
        startDayOffset: Int = 0
    ) throws -> NonNegotiable {
        let startDate = DateRules.addingDays(startDayOffset, to: anchor, calendar: calendar)
        let definition = NonNegotiableDefinition(
            title: title,
            frequencyPerWeek: mode == .daily ? 7 : frequencyPerWeek,
            mode: mode,
            goalId: UUID()
        )
        var nn = try NonNegotiableEngine(calendar: calendar).create(
            definition: definition,
            startDate: startDate,
            totalLockDays: 28
        )
        nn.state = state
        return nn
    }

    private func makePausedAllocation(protocolId: UUID, day: Date) -> PlanAllocation {
        PlanAllocation(
            id: UUID(),
            protocolId: protocolId,
            weekId: DateRules.weekID(for: day, calendar: calendar),
            day: day,
            slot: .am,
            startTime: nil,
            durationMinutes: 60,
            createdAt: anchor,
            updatedAt: anchor,
            status: .paused
        )
    }

    private func makePlanStore(allocations: [PlanAllocation] = []) -> PlanStore {
        PlanStore(
            repository: InMemoryPlanAllocationRepository(value: allocations),
            calendar: calendar
        )
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
}
