import XCTest
@testable import LockedIn

@MainActor
final class RepositoryPlanServiceBehaviorLockTests: XCTestCase {
    func testValidateProtocolPlacement_allowsPlacementForAvailableSlot() {
        let protocolModel = RepositoryPlanServiceTestFixtures.makeSessionProtocol()
        let (store, _) = makeStore(
            protocols: [protocolModel],
            allocations: []
        )
        let targetDay = RepositoryPlanServiceTestFixtures.date(year: 2026, month: 1, day: 6)

        let result = store.validateProtocolPlacement(
            protocolId: protocolModel.id,
            day: targetDay,
            slot: .am
        )

        XCTAssertEqual(result, .allowed)
    }

    func testValidateMove_blocksWhenProtocolAlreadyScheduledSameDay() {
        let protocolModel = RepositoryPlanServiceTestFixtures.makeSessionProtocol()
        let sourceDay = RepositoryPlanServiceTestFixtures.date(year: 2026, month: 1, day: 5)
        let targetDay = RepositoryPlanServiceTestFixtures.date(year: 2026, month: 1, day: 6)

        let allocationToMove = RepositoryPlanServiceTestFixtures.makeAllocation(
            protocolId: protocolModel.id,
            day: sourceDay,
            slot: .am
        )
        let existingSameDayAllocation = RepositoryPlanServiceTestFixtures.makeAllocation(
            protocolId: protocolModel.id,
            day: targetDay,
            slot: .pm
        )

        let (store, _) = makeStore(
            protocols: [protocolModel],
            allocations: [allocationToMove, existingSameDayAllocation]
        )

        let result = store.validateMove(
            allocationId: allocationToMove.id,
            day: targetDay,
            slot: .eve
        )

        guard case .blocked(_, let reason) = result else {
            XCTFail("Expected blocked move validation.")
            return
        }
        XCTAssertEqual(reason, .protocolAlreadyScheduledThatDay)
    }

    func testMoveThenRemove_updatesAndDeletesAllocation() {
        let protocolModel = RepositoryPlanServiceTestFixtures.makeSessionProtocol()
        let originalDay = RepositoryPlanServiceTestFixtures.date(year: 2026, month: 1, day: 5)
        let destinationDay = RepositoryPlanServiceTestFixtures.date(year: 2026, month: 1, day: 7)
        let allocation = RepositoryPlanServiceTestFixtures.makeAllocation(
            protocolId: protocolModel.id,
            day: originalDay,
            slot: .am
        )

        let (store, repository) = makeStore(
            protocols: [protocolModel],
            allocations: [allocation]
        )

        let mutation = store.moveAllocation(
            id: allocation.id,
            newDay: destinationDay,
            newSlot: .pm
        )

        guard case .moved(let allocationId, _, _, _, let movedDay, let movedSlot) = mutation else {
            XCTFail("Expected move mutation.")
            return
        }
        XCTAssertEqual(allocationId, allocation.id)
        XCTAssertEqual(movedDay, DateRules.startOfDay(destinationDay, calendar: RepositoryPlanServiceTestFixtures.calendar))
        XCTAssertEqual(movedSlot, .pm)

        let movedAllocation = store.currentWeekSnapshot().currentWeekAllocations.first(where: { $0.id == allocation.id })
        XCTAssertEqual(movedAllocation?.slot, .pm)
        XCTAssertEqual(
            movedAllocation?.day,
            DateRules.startOfDay(destinationDay, calendar: RepositoryPlanServiceTestFixtures.calendar)
        )

        store.removeAllocation(id: allocation.id)

        XCTAssertFalse(store.currentWeekSnapshot().currentWeekAllocations.contains(where: { $0.id == allocation.id }))
        XCTAssertTrue(repository.saveCalls.count >= 2)
    }

    func testApplyDraft_successAddsAllocationAndReturnsCount() {
        let protocolModel = RepositoryPlanServiceTestFixtures.makeSessionProtocol()
        let draftDay = RepositoryPlanServiceTestFixtures.date(year: 2026, month: 1, day: 8)
        let draft = PlanAllocationDraft(
            protocolId: protocolModel.id,
            weekId: DateRules.weekID(for: draftDay, calendar: RepositoryPlanServiceTestFixtures.calendar),
            day: draftDay,
            slot: .eve,
            durationMinutes: 45
        )
        let (store, repository) = makeStore(
            protocols: [protocolModel],
            allocations: []
        )

        let result = store.applyDraft([draft])

        switch result {
        case .success(let count):
            XCTAssertEqual(count, 1)
        case .failure(let error):
            XCTFail("Expected draft apply success, got \(error.localizedDescription)")
        }

        let appliedAllocation = store.currentWeekSnapshot().currentWeekAllocations.first
        XCTAssertEqual(appliedAllocation?.protocolId, protocolModel.id)
        XCTAssertEqual(appliedAllocation?.slot, .eve)
        XCTAssertEqual(appliedAllocation?.durationMinutes, 45)
        XCTAssertEqual(repository.storedAllocations.count, 1)
    }

    func testApplyDraft_failureForUnknownProtocolLeavesStateUnchanged() {
        let protocolModel = RepositoryPlanServiceTestFixtures.makeSessionProtocol()
        let unknownProtocolId = UUID()
        let draftDay = RepositoryPlanServiceTestFixtures.date(year: 2026, month: 1, day: 8)
        let draft = PlanAllocationDraft(
            protocolId: unknownProtocolId,
            weekId: DateRules.weekID(for: draftDay, calendar: RepositoryPlanServiceTestFixtures.calendar),
            day: draftDay,
            slot: .am,
            durationMinutes: 30
        )
        let (store, repository) = makeStore(
            protocols: [protocolModel],
            allocations: []
        )

        let result = store.applyDraft([draft])

        switch result {
        case .success:
            XCTFail("Expected draft apply failure.")
        case .failure(let error):
            XCTAssertEqual(error.localizedDescription, "Protocol is no longer available.")
        }
        XCTAssertTrue(store.currentWeekSnapshot().currentWeekAllocations.isEmpty)
        XCTAssertTrue(repository.saveCalls.isEmpty)
    }

    func testReconcileAfterCompletion_releasesNearestFutureAllocation() {
        let protocolModel = RepositoryPlanServiceTestFixtures.makeSessionProtocol()
        let completionDate = RepositoryPlanServiceTestFixtures.date(year: 2026, month: 1, day: 5, hour: 9)
        let firstFutureDay = RepositoryPlanServiceTestFixtures.date(year: 2026, month: 1, day: 6, hour: 6)
        let secondFutureDay = RepositoryPlanServiceTestFixtures.date(year: 2026, month: 1, day: 7, hour: 18)

        let firstFutureAllocation = RepositoryPlanServiceTestFixtures.makeAllocation(
            protocolId: protocolModel.id,
            day: firstFutureDay,
            slot: .am
        )
        let secondFutureAllocation = RepositoryPlanServiceTestFixtures.makeAllocation(
            protocolId: protocolModel.id,
            day: secondFutureDay,
            slot: .eve
        )

        let (store, repository) = makeStore(
            protocols: [protocolModel],
            allocations: [firstFutureAllocation, secondFutureAllocation]
        )

        let outcome = store.reconcileAfterCompletion(
            protocolId: protocolModel.id,
            mode: .session,
            completionDate: completionDate,
            completionKind: .counted
        )

        XCTAssertEqual(
            outcome,
            .released(
                ReleasedAllocationInfo(
                    protocolId: protocolModel.id,
                    day: DateRules.startOfDay(firstFutureDay, calendar: RepositoryPlanServiceTestFixtures.calendar),
                    slot: .am
                )
            )
        )
        XCTAssertFalse(store.currentWeekSnapshot().currentWeekAllocations.contains(where: { $0.id == firstFutureAllocation.id }))
        XCTAssertTrue(store.currentWeekSnapshot().currentWeekAllocations.contains(where: { $0.id == secondFutureAllocation.id }))
        XCTAssertEqual(repository.storedAllocations.count, 1)
    }
}

private extension RepositoryPlanServiceBehaviorLockTests {
    func makeStore(
        protocols: [NonNegotiable],
        allocations: [PlanAllocation]
    ) -> (RepositoryPlanService, RecordingPlanAllocationRepository) {
        let repository = RecordingPlanAllocationRepository(initialAllocations: allocations)
        let store = RepositoryPlanService(
            repository: repository,
            policy: CommitmentPolicyEngine(calendar: RepositoryPlanServiceTestFixtures.calendar),
            calendar: RepositoryPlanServiceTestFixtures.calendar
        )

        let system = RepositoryPlanServiceTestFixtures.makeSystem(protocols: protocols)
        store.refresh(
            system: system,
            calendarEvents: [],
            referenceDate: RepositoryPlanServiceTestFixtures.referenceDate
        )
        RepositoryPlanServiceTestRetainer.retain(store)
        return (store, repository)
    }
}

@MainActor
final class AppRouterPlanRouteIntentLifecycleTests: XCTestCase {
    private static var retainedRouters: [AppRouter] = []

    func testOpenPlan_producesFocusIntent_andConsumeClearsIt() {
        let router = makeRouter()
        let protocolId = UUID()

        router.openPlan(protocolId: protocolId)

        XCTAssertEqual(router.selectedTab, .plan)
        XCTAssertEqual(router.pendingPlanFocusProtocolId, protocolId)
        XCTAssertNil(router.pendingPlanEditProtocolId)

        router.consumePlanFocusIntent()

        XCTAssertNil(router.pendingPlanFocusProtocolId)
        XCTAssertNil(router.pendingPlanEditProtocolId)
    }

    func testOpenPlanEditor_producesEditIntent_andConsumeClearsOnlyEditIntent() {
        let router = makeRouter()
        let protocolId = UUID()

        router.openPlanEditor(protocolId: protocolId)

        XCTAssertEqual(router.selectedTab, .plan)
        XCTAssertEqual(router.pendingPlanFocusProtocolId, protocolId)
        XCTAssertEqual(router.pendingPlanEditProtocolId, protocolId)

        router.consumePlanEditIntent()

        XCTAssertEqual(router.pendingPlanFocusProtocolId, protocolId)
        XCTAssertNil(router.pendingPlanEditProtocolId)
    }

    func testConsumeWithoutNewIntent_afterClear_isNoOp() {
        let router = makeRouter()
        let editorProtocolId = UUID()

        router.openPlan(protocolId: UUID())
        router.consumePlanFocusIntent()
        router.consumePlanFocusIntent()

        router.openPlanEditor(protocolId: editorProtocolId)
        router.consumePlanEditIntent()
        router.consumePlanEditIntent()

        XCTAssertEqual(router.pendingPlanFocusProtocolId, editorProtocolId)
        XCTAssertNil(router.pendingPlanEditProtocolId)
        XCTAssertEqual(router.selectedTab, .plan)
    }

    func testNewerPlanIntentReplacesOlderPendingIntent_beforeConsumption() {
        let router = makeRouter()
        let first = UUID()
        let second = UUID()

        router.openPlan(protocolId: first)
        router.openPlan(protocolId: second)

        XCTAssertEqual(router.pendingPlanFocusProtocolId, second)

        router.consumePlanFocusIntent()

        XCTAssertNil(router.pendingPlanFocusProtocolId)

        router.openPlanEditor(protocolId: first)
        router.openPlanEditor(protocolId: second)

        XCTAssertEqual(router.pendingPlanFocusProtocolId, second)
        XCTAssertEqual(router.pendingPlanEditProtocolId, second)
    }

    private func makeRouter() -> AppRouter {
        let router = AppRouter()
        Self.retainedRouters.append(router)
        return router
    }
}
