import XCTest
@testable import LockedIn

@MainActor
final class CrossFeatureCompletionParityTests: XCTestCase {
    func testCockpitAndDailyCheckIn_countedCompletionWithPlanReleaseStayInParity() {
        let calendar = TestCalendarSupport.utcISO8601
        let referenceDate = CommitmentSystemStoreTestFixtures.date(year: 2026, month: 1, day: 7, hour: 9)
        let protocolId = UUID()
        let releasedAllocationId = UUID()
        let remainingAllocationId = UUID()

        let protocolModel = CommitmentSystemStoreTestFixtures.makeProtocol(
            id: protocolId,
            title: "Deep Work",
            mode: .session,
            frequencyPerWeek: 3,
            startDate: CommitmentSystemStoreTestFixtures.referenceDate,
            createdAt: CommitmentSystemStoreTestFixtures.referenceDate
        )
        let system = CommitmentSystemStoreTestFixtures.makeSystem(nonNegotiables: [protocolModel])

        let releasedAllocation = PlanStoreTestFixtures.makeAllocation(
            id: releasedAllocationId,
            protocolId: protocolId,
            day: CommitmentSystemStoreTestFixtures.date(year: 2026, month: 1, day: 8, hour: 6),
            slot: .am
        )
        let remainingAllocation = PlanStoreTestFixtures.makeAllocation(
            id: remainingAllocationId,
            protocolId: protocolId,
            day: CommitmentSystemStoreTestFixtures.date(year: 2026, month: 1, day: 9, hour: 18),
            slot: .eve
        )

        let cockpitHarness = makeHarness(
            system: system,
            allocations: [releasedAllocation, remainingAllocation],
            calendar: calendar,
            referenceDate: referenceDate
        )
        let dailyHarness = makeHarness(
            system: system,
            allocations: [releasedAllocation, remainingAllocation],
            calendar: calendar,
            referenceDate: referenceDate
        )

        let cockpitFeedback = runCockpitCompletion(
            protocolId: protocolId,
            referenceDate: referenceDate,
            harness: cockpitHarness
        )

        let dailyViewModel = makeRetainedDailyViewModel(
            harness: dailyHarness,
            referenceDate: referenceDate,
            calendar: calendar
        )
        dailyViewModel.markDone(protocolId: protocolId)
        let dailyFeedback = CompletionFeedbackObservation(
            warningMessage: dailyViewModel.warningMessage,
            toastMessage: dailyViewModel.toastMessage
        )

        assertParity(
            protocolId: protocolId,
            referenceDate: referenceDate,
            cockpitHarness: cockpitHarness,
            dailyHarness: dailyHarness,
            cockpitFeedback: cockpitFeedback,
            dailyFeedback: dailyFeedback,
            expectedFeedbackCategory: .releasedToast
        )

        let cockpitSnapshot = snapshot(protocolId: protocolId, harness: cockpitHarness)
        XCTAssertEqual(cockpitSnapshot.completionKinds, [.counted])
        XCTAssertEqual(cockpitSnapshot.planAllocations.map(\.id), [remainingAllocationId])
        XCTAssertEqual(cockpitSnapshot.planSaveCount, 1)
    }

    func testCockpitAndDailyCheckIn_extraCompletionPathStayInParity() {
        let calendar = TestCalendarSupport.utcISO8601
        let referenceDate = CommitmentSystemStoreTestFixtures.date(year: 2026, month: 1, day: 7, hour: 9)
        let protocolId = UUID()
        let allocationId = UUID()

        let priorCountedCompletion = CompletionRecord(
            date: CommitmentSystemStoreTestFixtures.date(year: 2026, month: 1, day: 6, hour: 8),
            weekId: DateRules.weekID(for: referenceDate, calendar: calendar),
            kind: .counted
        )
        let protocolModel = CommitmentSystemStoreTestFixtures.makeProtocol(
            id: protocolId,
            title: "Deep Work",
            mode: .session,
            frequencyPerWeek: 1,
            startDate: CommitmentSystemStoreTestFixtures.referenceDate,
            createdAt: CommitmentSystemStoreTestFixtures.referenceDate,
            completions: [priorCountedCompletion]
        )
        let system = CommitmentSystemStoreTestFixtures.makeSystem(nonNegotiables: [protocolModel])

        let allocation = PlanStoreTestFixtures.makeAllocation(
            id: allocationId,
            protocolId: protocolId,
            day: CommitmentSystemStoreTestFixtures.date(year: 2026, month: 1, day: 8, hour: 6),
            slot: .am
        )

        let cockpitHarness = makeHarness(
            system: system,
            allocations: [allocation],
            calendar: calendar,
            referenceDate: referenceDate
        )
        let dailyHarness = makeHarness(
            system: system,
            allocations: [allocation],
            calendar: calendar,
            referenceDate: referenceDate
        )

        let cockpitFeedback = runCockpitCompletion(
            protocolId: protocolId,
            referenceDate: referenceDate,
            harness: cockpitHarness
        )

        let dailyViewModel = makeRetainedDailyViewModel(
            harness: dailyHarness,
            referenceDate: referenceDate,
            calendar: calendar
        )
        dailyViewModel.markDone(protocolId: protocolId)
        let dailyFeedback = CompletionFeedbackObservation(
            warningMessage: dailyViewModel.warningMessage,
            toastMessage: dailyViewModel.toastMessage
        )

        assertParity(
            protocolId: protocolId,
            referenceDate: referenceDate,
            cockpitHarness: cockpitHarness,
            dailyHarness: dailyHarness,
            cockpitFeedback: cockpitFeedback,
            dailyFeedback: dailyFeedback,
            expectedFeedbackCategory: .extraToast
        )

        let cockpitSnapshot = snapshot(protocolId: protocolId, harness: cockpitHarness)
        XCTAssertEqual(cockpitSnapshot.completionKinds, [.counted, .extra])
        XCTAssertEqual(cockpitSnapshot.planAllocations.map(\.id), [allocationId])
        XCTAssertEqual(cockpitSnapshot.planSaveCount, 0)
    }
}

private extension CrossFeatureCompletionParityTests {
    enum AppRouterParityTestRetainer {
        static var routers: [AppRouter] = []

        static func retain(_ router: AppRouter) {
            routers.append(router)
        }
    }

    enum DailyCheckInViewModelParityTestRetainer {
        static var viewModels: [DailyCheckInViewModel] = []

        static func retain(_ viewModel: DailyCheckInViewModel) {
            viewModels.append(viewModel)
        }
    }

    enum CockpitViewModelParityTestRetainer {
        static var viewModels: [CockpitViewModel] = []

        static func retain(_ viewModel: CockpitViewModel) {
            viewModels.append(viewModel)
        }
    }

    struct CompletionHarness {
        let commitmentStore: CommitmentSystemStore
        let commitmentRepository: RecordingCommitmentSystemRepository
        let planStore: PlanStore
        let planRepository: RecordingPlanAllocationRepository
    }

    struct CompletionFeedbackObservation: Equatable {
        let warningMessage: String?
        let toastMessage: String?
    }

    enum CompletionFeedbackCategory: Equatable {
        case none
        case extraToast
        case releasedToast
        case warning
        case otherToast
    }

    func makeRetainedRouter() -> AppRouter {
        let router = AppRouter()
        AppRouterParityTestRetainer.retain(router)
        return router
    }

    func makeRetainedDailyViewModel(
        harness: CompletionHarness,
        referenceDate: Date,
        calendar: Calendar
    ) -> DailyCheckInViewModel {
        let viewModel = DailyCheckInViewModel(
            commitmentStore: harness.commitmentStore,
            planStore: harness.planStore,
            commitmentService: LegacyCommitmentWrapper(store: harness.commitmentStore),
            planService: LegacyPlanWrapper(store: harness.planStore),
            router: makeRetainedRouter(),
            referenceDateProvider: { referenceDate },
            calendar: calendar
        )
        DailyCheckInViewModelParityTestRetainer.retain(viewModel)
        return viewModel
    }

    struct PlanAllocationDigest: Equatable {
        let id: UUID
        let protocolId: UUID
        let day: Date
        let slot: PlanSlot
        let status: PlanAllocationStatus
    }

    struct CompletionPathSnapshot: Equatable {
        let completionKinds: [CompletionKind]
        let countedCompletionCount: Int
        let extraCompletionCount: Int
        let planAllocations: [PlanAllocationDigest]
        let lastRecoveryEvaluationDay: Date?
        let recoveryCleanDayStreak: Int
        let commitmentSaveCount: Int
        let planSaveCount: Int
    }

    func makeHarness(
        system: CommitmentSystem,
        allocations: [PlanAllocation],
        calendar: Calendar,
        referenceDate: Date
    ) -> CompletionHarness {
        let commitmentRepository = RecordingCommitmentSystemRepository(initialSystem: system)
        let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
        let commitmentStore = CommitmentSystemStore(
            repository: commitmentRepository,
            systemEngine: CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine),
            nonNegotiableEngine: nonNegotiableEngine,
            policy: CommitmentPolicyEngine(calendar: calendar),
            streakEngine: StreakEngine(calendar: calendar),
            calendar: calendar
        )
        CommitmentSystemStoreTestRetainer.retain(commitmentStore)

        let planRepository = RecordingPlanAllocationRepository(initialAllocations: allocations)
        let planStore = PlanStore(
            repository: planRepository,
            policy: CommitmentPolicyEngine(calendar: calendar),
            calendar: calendar
        )
        PlanStoreTestRetainer.retain(planStore)
        planStore.refresh(system: system, calendarEvents: [], referenceDate: referenceDate)

        return CompletionHarness(
            commitmentStore: commitmentStore,
            commitmentRepository: commitmentRepository,
            planStore: planStore,
            planRepository: planRepository
        )
    }

    func runCockpitCompletion(
        protocolId: UUID,
        referenceDate: Date,
        harness: CompletionHarness
    ) -> CompletionFeedbackObservation {
        guard let protocolModel = harness.commitmentStore.system.nonNegotiables.first(where: { $0.id == protocolId }) else {
            return CompletionFeedbackObservation(
                warningMessage: "This protocol is no longer available.",
                toastMessage: nil
            )
        }

        let viewModel = CockpitViewModel(
            commitmentService: LegacyCommitmentWrapper(store: harness.commitmentStore),
            planService: LegacyPlanWrapper(store: harness.planStore),
            nowProvider: { referenceDate }
        )
        CockpitViewModelParityTestRetainer.retain(viewModel)

        do {
            let result = try viewModel.complete(protocolModel: protocolModel)
            return CompletionFeedbackObservation(
                warningMessage: nil,
                toastMessage: result.toastMessage
            )
        } catch {
            return CompletionFeedbackObservation(
                warningMessage: harness.commitmentStore.policyCopy(for: error)?.message ?? error.localizedDescription,
                toastMessage: nil
            )
        }
    }

    func feedbackCategory(for feedback: CompletionFeedbackObservation) -> CompletionFeedbackCategory {
        if feedback.warningMessage != nil {
            return .warning
        }

        guard let toastMessage = feedback.toastMessage else {
            return .none
        }

        if toastMessage.contains("EXTRA") {
            return .extraToast
        }

        if toastMessage.contains("wasn't scheduled today") {
            return .releasedToast
        }

        return .otherToast
    }

    func snapshot(protocolId: UUID, harness: CompletionHarness) -> CompletionPathSnapshot {
        let completionKinds = harness.commitmentStore.system.nonNegotiables
            .first(where: { $0.id == protocolId })?
            .completions
            .sorted { lhs, rhs in
                if lhs.date != rhs.date {
                    return lhs.date < rhs.date
                }
                return lhs.kind.rawValue < rhs.kind.rawValue
            }
            .map(\.kind) ?? []

        let planAllocations = harness.planStore.currentWeekSnapshot().currentWeekAllocations
            .sorted { lhs, rhs in
                if lhs.day != rhs.day {
                    return lhs.day < rhs.day
                }
                if lhs.slot != rhs.slot {
                    return lhs.slot.sortIndex < rhs.slot.sortIndex
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
            .map {
                PlanAllocationDigest(
                    id: $0.id,
                    protocolId: $0.protocolId,
                    day: $0.day,
                    slot: $0.slot,
                    status: $0.status
                )
            }

        return CompletionPathSnapshot(
            completionKinds: completionKinds,
            countedCompletionCount: harness.commitmentStore.countedCompletionLog.count,
            extraCompletionCount: harness.commitmentStore.extraCompletionLog.count,
            planAllocations: planAllocations,
            lastRecoveryEvaluationDay: harness.commitmentStore.system.lastRecoveryEvaluationDay,
            recoveryCleanDayStreak: harness.commitmentStore.system.recoveryCleanDayStreak,
            commitmentSaveCount: harness.commitmentRepository.saveCalls.count,
            planSaveCount: harness.planRepository.saveCalls.count
        )
    }

    func assertParity(
        protocolId: UUID,
        referenceDate: Date,
        cockpitHarness: CompletionHarness,
        dailyHarness: CompletionHarness,
        cockpitFeedback: CompletionFeedbackObservation,
        dailyFeedback: CompletionFeedbackObservation,
        expectedFeedbackCategory: CompletionFeedbackCategory,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let cockpitCategory = feedbackCategory(for: cockpitFeedback)
        let dailyCategory = feedbackCategory(for: dailyFeedback)

        XCTAssertEqual(cockpitCategory, dailyCategory, file: file, line: line)
        XCTAssertEqual(cockpitCategory, expectedFeedbackCategory, file: file, line: line)
        XCTAssertEqual(cockpitFeedback.warningMessage, dailyFeedback.warningMessage, file: file, line: line)
        XCTAssertEqual(cockpitFeedback.toastMessage, dailyFeedback.toastMessage, file: file, line: line)

        let cockpitSnapshot = snapshot(protocolId: protocolId, harness: cockpitHarness)
        let dailySnapshot = snapshot(protocolId: protocolId, harness: dailyHarness)
        XCTAssertEqual(cockpitSnapshot, dailySnapshot, file: file, line: line)

        let expectedEvaluationDay = DateRules.startOfDay(referenceDate, calendar: TestCalendarSupport.utcISO8601)
        XCTAssertEqual(cockpitSnapshot.lastRecoveryEvaluationDay, expectedEvaluationDay, file: file, line: line)
    }
}

private extension PlanSlot {
    var sortIndex: Int {
        switch self {
        case .am:
            return 0
        case .pm:
            return 1
        case .eve:
            return 2
        }
    }
}
