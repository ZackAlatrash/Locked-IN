import Foundation

@MainActor
func runPlanCompletionReconciliationSimulation() {
    var calendar = DateRules.isoCalendar
    calendar.timeZone = .current

    let reference = DateRules.date(year: 2026, month: 1, day: 7, hour: 10, calendar: calendar)
    let weekId = DateRules.weekID(for: reference, calendar: calendar)

    do {
        let definition = NonNegotiableDefinition(
            title: "Deep Work",
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )
        let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
        let protocolModel = try nonNegotiableEngine.create(
            definition: definition,
            startDate: DateRules.startOfDay(reference, calendar: calendar),
            totalLockDays: 28
        )

        let thursday = DateRules.date(year: 2026, month: 1, day: 8, hour: 0, calendar: calendar)
        let friday = DateRules.date(year: 2026, month: 1, day: 9, hour: 0, calendar: calendar)

        let initialAllocations = [
            PlanAllocation(
                id: UUID(),
                protocolId: protocolModel.id,
                weekId: weekId,
                day: thursday,
                slot: .pm,
                startTime: nil,
                durationMinutes: 90,
                createdAt: reference,
                updatedAt: reference
            ),
            PlanAllocation(
                id: UUID(),
                protocolId: protocolModel.id,
                weekId: weekId,
                day: friday,
                slot: .am,
                startTime: nil,
                durationMinutes: 90,
                createdAt: reference,
                updatedAt: reference
            )
        ]

        let repository = InMemoryPlanAllocationRepository(value: initialAllocations)
        let planStore = PlanStore(repository: repository, calendar: calendar)
        let system = CommitmentSystem(nonNegotiables: [protocolModel], createdAt: reference)
        planStore.refresh(system: system, calendarEvents: [], referenceDate: reference)

        let firstOutcome = planStore.reconcileAfterCompletion(
            protocolId: protocolModel.id,
            mode: .session,
            completionDate: reference,
            completionKind: .counted
        )
        switch firstOutcome {
        case .released(let info):
            print("Reconciliation release day: \(info.day) slot: \(info.slot.title) (expected THU PM)")
        case .none:
            print("Reconciliation did not release allocation (unexpected)")
        }

        let afterFirst = planStore.currentWeekSnapshot().currentWeekAllocations.count
        print("Allocations after first reconcile: \(afterFirst) (expected 1)")

        let secondOutcome = planStore.reconcileAfterCompletion(
            protocolId: protocolModel.id,
            mode: .session,
            completionDate: DateRules.date(year: 2026, month: 1, day: 9, hour: 23, minute: 30, calendar: calendar),
            completionKind: .counted
        )
        print("No future allocation outcome: \(secondOutcome) (expected none)")

        let thirdOutcome = planStore.reconcileAfterCompletion(
            protocolId: protocolModel.id,
            mode: .session,
            completionDate: reference,
            completionKind: .extra
        )
        print("Extra completion outcome: \(thirdOutcome) (expected none)")
    } catch {
        print("Plan reconciliation simulation failed with error: \(error)")
    }
}

@MainActor
func runRecoveryExitAllocationCleanupSimulation() {
    var calendar = DateRules.isoCalendar
    calendar.timeZone = .current

    let reference = DateRules.date(year: 2026, month: 2, day: 11, hour: 10, calendar: calendar)
    let weekId = DateRules.weekID(for: reference, calendar: calendar)

    func makeProtocol(title: String) -> NonNegotiable {
        let definition = NonNegotiableDefinition(
            title: title,
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )
        let engine = NonNegotiableEngine(calendar: calendar)
        return try! engine.create(
            definition: definition,
            startDate: DateRules.startOfDay(reference, calendar: calendar),
            totalLockDays: 28
        )
    }

    func makePausedAllocation(protocolId: UUID, day: Date, slot: PlanSlot) -> PlanAllocation {
        PlanAllocation(
            id: UUID(),
            protocolId: protocolId,
            weekId: weekId,
            day: day,
            slot: slot,
            startTime: nil,
            durationMinutes: 90,
            createdAt: reference,
            updatedAt: reference,
            status: .paused
        )
    }

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("Recovery-Exit Cleanup Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    // Case 1: still-active paused protocol restores future allocations.
    do {
        let activeProtocol = makeProtocol(title: "Active")
        let futureDay = DateRules.date(year: 2026, month: 2, day: 12, hour: 0, calendar: calendar)
        let allocation = makePausedAllocation(protocolId: activeProtocol.id, day: futureDay, slot: .pm)

        let repository = InMemoryPlanAllocationRepository(value: [allocation])
        let planStore = PlanStore(repository: repository, calendar: calendar)
        let system = CommitmentSystem(nonNegotiables: [activeProtocol], createdAt: reference)
        planStore.refresh(system: system, calendarEvents: [], referenceDate: reference)

        planStore.finalizeRecoveryAllocationStatuses(
            referenceDate: reference,
            restorableProtocolIds: [activeProtocol.id]
        )

        let status = planStore.currentWeekSnapshot().currentWeekAllocations.first?.status
        verify("Case 1 - future paused restored for active protocol", status == .active)
    }

    // Case 2: retired paused protocol does not restore future allocations.
    do {
        var protocolModel = makeProtocol(title: "Retired")
        protocolModel.state = .suspended
        let futureDay = DateRules.date(year: 2026, month: 2, day: 12, hour: 0, calendar: calendar)
        let allocation = makePausedAllocation(protocolId: protocolModel.id, day: futureDay, slot: .eve)

        let repository = InMemoryPlanAllocationRepository(value: [allocation])
        let planStore = PlanStore(repository: repository, calendar: calendar)
        let system = CommitmentSystem(nonNegotiables: [protocolModel], createdAt: reference)
        planStore.refresh(system: system, calendarEvents: [], referenceDate: reference)

        planStore.finalizeRecoveryAllocationStatuses(
            referenceDate: reference,
            restorableProtocolIds: []
        )

        let status = planStore.currentWeekSnapshot().currentWeekAllocations.first?.status
        verify("Case 2 - future paused not restored for retired protocol", status == .skippedDueToRecovery)
    }

    // Case 3: mixed active + retired paused protocols.
    do {
        let activeProtocol = makeProtocol(title: "Active-Mixed")
        var retiredProtocol = makeProtocol(title: "Retired-Mixed")
        retiredProtocol.state = .suspended

        let futureDay = DateRules.date(year: 2026, month: 2, day: 13, hour: 0, calendar: calendar)
        let activeAllocation = makePausedAllocation(protocolId: activeProtocol.id, day: futureDay, slot: .am)
        let retiredAllocation = makePausedAllocation(protocolId: retiredProtocol.id, day: futureDay, slot: .pm)

        let repository = InMemoryPlanAllocationRepository(value: [activeAllocation, retiredAllocation])
        let planStore = PlanStore(repository: repository, calendar: calendar)
        let system = CommitmentSystem(nonNegotiables: [activeProtocol, retiredProtocol], createdAt: reference)
        planStore.refresh(system: system, calendarEvents: [], referenceDate: reference)

        planStore.finalizeRecoveryAllocationStatuses(
            referenceDate: reference,
            restorableProtocolIds: [activeProtocol.id]
        )

        let statuses = Dictionary(uniqueKeysWithValues: planStore.currentWeekSnapshot().currentWeekAllocations.map { ($0.protocolId, $0.status) })
        verify("Case 3 - active protocol restored", statuses[activeProtocol.id] == .active)
        verify("Case 3 - retired protocol not restored", statuses[retiredProtocol.id] == .skippedDueToRecovery)
    }

    // Case 4: past paused allocations keep existing skipped-due-to-recovery handling.
    do {
        let activeProtocol = makeProtocol(title: "Active-Past")
        let pastDay = DateRules.date(year: 2026, month: 2, day: 10, hour: 0, calendar: calendar)
        let allocation = makePausedAllocation(protocolId: activeProtocol.id, day: pastDay, slot: .am)

        let repository = InMemoryPlanAllocationRepository(value: [allocation])
        let planStore = PlanStore(repository: repository, calendar: calendar)
        let system = CommitmentSystem(nonNegotiables: [activeProtocol], createdAt: reference)
        planStore.refresh(system: system, calendarEvents: [], referenceDate: reference)

        planStore.finalizeRecoveryAllocationStatuses(
            referenceDate: reference,
            restorableProtocolIds: [activeProtocol.id]
        )

        let status = planStore.currentWeekSnapshot().currentWeekAllocations.first?.status
        verify("Case 4 - past paused becomes skipped", status == .skippedDueToRecovery)
    }

    // Case 5: recovery exits after retirement-driven domain exhaustion.
    do {
        var exhaustedProtocol = makeProtocol(title: "Exhausted")
        exhaustedProtocol.state = .suspended
        let futureDay = DateRules.date(year: 2026, month: 2, day: 14, hour: 0, calendar: calendar)
        let allocation = makePausedAllocation(protocolId: exhaustedProtocol.id, day: futureDay, slot: .pm)

        let repository = InMemoryPlanAllocationRepository(value: [allocation])
        let planStore = PlanStore(repository: repository, calendar: calendar)
        let system = CommitmentSystem(nonNegotiables: [exhaustedProtocol], createdAt: reference)
        planStore.refresh(system: system, calendarEvents: [], referenceDate: reference)

        planStore.finalizeRecoveryAllocationStatuses(
            referenceDate: reference,
            restorableProtocolIds: []
        )

        let status = planStore.currentWeekSnapshot().currentWeekAllocations.first?.status
        verify("Case 5 - exhausted-domain paused allocation resolved terminally", status == .skippedDueToRecovery)
    }
}

@MainActor
func runInitialGraceWindowSurfaceAlignmentSimulation() {
    var calendar = DateRules.isoCalendar
    calendar.timeZone = .current

    let creationDate = DateRules.date(year: 2026, month: 1, day: 7, hour: 10, calendar: calendar)
    let referenceDate = DateRules.date(year: 2026, month: 1, day: 10, hour: 9, calendar: calendar)

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("Grace-Surfaces Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    do {
        let definition = NonNegotiableDefinition(
            title: "Grace Surface",
            frequencyPerWeek: 7,
            mode: .session,
            goalId: UUID()
        )
        let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
        let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine)
        let protocolModel = try nonNegotiableEngine.create(
            definition: definition,
            startDate: creationDate,
            totalLockDays: 28
        )

        let system = CommitmentSystem(nonNegotiables: [protocolModel], createdAt: creationDate)
        let planStore = PlanStore(repository: InMemoryPlanAllocationRepository(value: []), calendar: calendar)
        planStore.refresh(system: system, calendarEvents: [], referenceDate: referenceDate)

        let queueEntry = planStore.queueItems.first(where: { $0.protocolId == protocolModel.id })
        verify("Case 1 - plan queue does not pressure grace-week protocol", queueEntry == nil)
        verify("Case 1 - today summary shows zero owed sessions", planStore.todaySummary.remainingSessions == 0)

        let commitmentStore = CommitmentSystemStore(
            repository: InMemoryCommitmentSystemRepository(initialSystem: system),
            systemEngine: commitmentEngine,
            nonNegotiableEngine: nonNegotiableEngine,
            policy: CommitmentPolicyEngine(calendar: calendar),
            streakEngine: StreakEngine(),
            calendar: calendar
        )
        let router = AppRouter()
        let viewModel = DailyCheckInViewModel(
            commitmentStore: commitmentStore,
            planStore: planStore,
            router: router,
            referenceDateProvider: { referenceDate },
            calendar: calendar
        )

        viewModel.refresh()
        let item = viewModel.protocolItems.first(where: { $0.protocolId == protocolModel.id })

        verify("Case 2 - check-in does not flag grace-week protocol as needs-attention", item?.needsAttention == false)
        verify("Case 2 - check-in status labels grace week explicitly", item?.statusText == "Grace week")
        verify("Case 2 - check-in action remains regular completion", item?.actionTitle == "Mark Done")
        verify("Case 2 - check-in remaining text avoids weekly debt framing", item?.remainingWeekText == "Grace week")

        viewModel.markDone(protocolId: protocolModel.id)
        let completionKind = commitmentStore
            .nonNegotiable(id: protocolModel.id)?
            .completions
            .last?
            .kind
        verify("Case 3 - grace-week completion remains counted (not extra)", completionKind == .counted)
    } catch {
        print("Grace-Surfaces Simulation failed with error: \(error)")
    }
}
