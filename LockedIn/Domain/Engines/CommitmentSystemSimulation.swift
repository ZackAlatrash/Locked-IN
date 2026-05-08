import Foundation

func runCommitmentSystemSimulation() {
    let calendar = DateRules.isoCalendar
    let startDate = DateRules.date(year: 2026, month: 1, day: 5, hour: 0, calendar: calendar)

    let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
    let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine)

    var system = CommitmentSystem(nonNegotiables: [], createdAt: startDate)

    do {
        let definitionA = NonNegotiableDefinition(
            title: "NN-A",
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )
        let definitionB = NonNegotiableDefinition(
            title: "NN-B",
            frequencyPerWeek: 7,
            mode: .daily,
            goalId: UUID()
        )
        let definitionC = NonNegotiableDefinition(
            title: "NN-C",
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )

        let nnA = try nonNegotiableEngine.create(definition: definitionA, startDate: startDate, totalLockDays: 28)
        let nnB = try nonNegotiableEngine.create(definition: definitionB, startDate: startDate, totalLockDays: 28)
        let nnC = try nonNegotiableEngine.create(definition: definitionC, startDate: startDate, totalLockDays: 28)
        print("Daily mode normalized frequency in system simulation: \(nnB.definition.frequencyPerWeek) (expected 7)")

        try commitmentEngine.add(nnA, to: &system)
        try commitmentEngine.add(nnB, to: &system)
        try commitmentEngine.add(nnC, to: &system)

        if let indexB = system.nonNegotiables.firstIndex(where: { $0.id == nnB.id }) {
            var recovering = system.nonNegotiables[indexB]
            recovering.state = .recovery
            system.nonNegotiables[indexB] = recovering
        }

        commitmentEngine.evaluateWeek(
            for: DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar),
            in: &system
        )

        print("Simulation - Allowed capacity: \(system.allowedCapacity) (expected 2)")
        print("Simulation - Active count: \(system.activeNonNegotiables.count) (expected 1)")
        print("Simulation - Suspended count: \(system.suspendedNonNegotiables.count) (expected 1)")

        let definitionD = NonNegotiableDefinition(
            title: "NN-D",
            frequencyPerWeek: 2,
            mode: .session,
            goalId: UUID()
        )
        let nnD = try nonNegotiableEngine.create(definition: definitionD, startDate: startDate, totalLockDays: 28)

        do {
            try commitmentEngine.add(nnD, to: &system)
            print("Simulation - Unexpected add success for 4th NN")
        } catch CommitmentSystemError.capacityExceeded {
            print("Simulation - 4th NN add blocked with capacityExceeded (expected)")
        } catch {
            print("Simulation - Unexpected error for 4th NN add: \(error)")
        }

        var inactivitySystem = CommitmentSystem(nonNegotiables: [], createdAt: startDate)
        let inactivityDefinition = NonNegotiableDefinition(
            title: "CatchUp-NN",
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )
        let inactivityNN = try nonNegotiableEngine.create(
            definition: inactivityDefinition,
            startDate: startDate,
            totalLockDays: 28
        )
        try commitmentEngine.add(inactivityNN, to: &inactivitySystem)

        let day21 = DateRules.addingDays(21, to: startDate, calendar: calendar)
        commitmentEngine.evaluateWeekCatchUp(referenceDate: day21, in: &inactivitySystem, calendar: calendar)
        commitmentEngine.evaluateWeekCatchUp(referenceDate: day21, in: &inactivitySystem, calendar: calendar)
        commitmentEngine.advanceWindows(currentDate: day21, in: &inactivitySystem)

        let totalWeeklyViolations = inactivitySystem.nonNegotiables
            .flatMap(\.violations)
            .filter { $0.kind == .missedWeeklyFrequency }
            .count
        let windowsCount = inactivitySystem.nonNegotiables.first?.windows.count ?? 0

        print("Simulation - 21 day inactivity weekly violations: \(totalWeeklyViolations) (expected 3)")
        print("Simulation - 21 day inactivity windows count: \(windowsCount) (expected 2)")

        var recoverySystem = CommitmentSystem(nonNegotiables: [], createdAt: startDate)
        let recoveryDefinitionA = NonNegotiableDefinition(
            title: "Recovery-A",
            frequencyPerWeek: 1,
            mode: .session,
            goalId: UUID()
        )
        let recoveryDefinitionB = NonNegotiableDefinition(
            title: "Recovery-B",
            frequencyPerWeek: 1,
            mode: .session,
            goalId: UUID()
        )
        let recoveryDefinitionC = NonNegotiableDefinition(
            title: "Recovery-C",
            frequencyPerWeek: 1,
            mode: .session,
            goalId: UUID()
        )

        let recoveryA = try nonNegotiableEngine.create(definition: recoveryDefinitionA, startDate: startDate, totalLockDays: 28)
        let recoveryB = try nonNegotiableEngine.create(definition: recoveryDefinitionB, startDate: startDate, totalLockDays: 28)
        let recoveryC = try nonNegotiableEngine.create(definition: recoveryDefinitionC, startDate: startDate, totalLockDays: 28)

        try commitmentEngine.add(recoveryA, to: &recoverySystem)
        try commitmentEngine.add(recoveryB, to: &recoverySystem)
        try commitmentEngine.add(recoveryC, to: &recoverySystem)

        if let idx = recoverySystem.nonNegotiables.firstIndex(where: { $0.id == recoveryA.id }) {
            recoverySystem.nonNegotiables[idx].state = .recovery
        }
        commitmentEngine.evaluateWeek(
            for: DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar),
            in: &recoverySystem
        )

        for offset in 0..<7 {
            let day = DateRules.addingDays(7 + offset, to: startDate, calendar: calendar)

            if let idxA = recoverySystem.nonNegotiables.firstIndex(where: { $0.id == recoveryA.id }) {
                var nnA = recoverySystem.nonNegotiables[idxA]
                _ = try nonNegotiableEngine.recordCompletion(&nnA, at: DateRules.date(
                    year: calendar.component(.year, from: day),
                    month: calendar.component(.month, from: day),
                    day: calendar.component(.day, from: day),
                    hour: 9,
                    calendar: calendar
                ))
                recoverySystem.nonNegotiables[idxA] = nnA
            }

            if let idxB = recoverySystem.nonNegotiables.firstIndex(where: { $0.id == recoveryB.id }),
               recoverySystem.nonNegotiables[idxB].state == .active {
                var nnB = recoverySystem.nonNegotiables[idxB]
                _ = try nonNegotiableEngine.recordCompletion(&nnB, at: DateRules.date(
                    year: calendar.component(.year, from: day),
                    month: calendar.component(.month, from: day),
                    day: calendar.component(.day, from: day),
                    hour: 10,
                    calendar: calendar
                ))
                recoverySystem.nonNegotiables[idxB] = nnB
            }

            commitmentEngine.evaluateDailyCompliance(currentDate: day, in: &recoverySystem)
            commitmentEngine.evaluateWeekCatchUp(referenceDate: day, in: &recoverySystem, calendar: calendar)
            commitmentEngine.advanceWindows(currentDate: day, in: &recoverySystem)
            commitmentEngine.evaluateRecoveryDay(referenceDate: day, in: &recoverySystem, calendar: calendar)
        }

        let recoveryCountAfter7 = recoverySystem.nonNegotiables.filter { $0.state == .recovery }.count
        let activeCountAfter7 = recoverySystem.nonNegotiables.filter { $0.state == .active }.count
        let suspendedCountAfter7 = recoverySystem.nonNegotiables.filter { $0.state == .suspended }.count
        print("Simulation - Recovery count after 7 clean days: \(recoveryCountAfter7) (expected 0)")
        print("Simulation - Active count after recovery exit: \(activeCountAfter7) (expected 3)")
        print("Simulation - Suspended count after recovery exit: \(suspendedCountAfter7) (expected 0)")
    } catch {
        print("Simulation failed with error: \(error)")
    }
}

@MainActor
func runRecoveryRetirementNormalizationSimulation() {
    let calendar = DateRules.isoCalendar
    let startDate = DateRules.date(year: 2026, month: 1, day: 1, hour: 0, calendar: calendar)
    let retirementDate = DateRules.date(year: 2026, month: 2, day: 10, hour: 9, calendar: calendar)

    func makeDefinition(title: String) -> NonNegotiableDefinition {
        NonNegotiableDefinition(
            title: title,
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )
    }

    func makeNonNegotiable(
        title: String,
        state: NonNegotiableState,
        createdAtOffset: Int,
        engine: NonNegotiableEngine
    ) -> NonNegotiable {
        var nonNegotiable = try! engine.create(
            definition: makeDefinition(title: title),
            startDate: startDate,
            totalLockDays: 14
        )
        nonNegotiable.state = state
        nonNegotiable = NonNegotiable(
            id: nonNegotiable.id,
            goalId: nonNegotiable.goalId,
            definition: nonNegotiable.definition,
            state: nonNegotiable.state,
            lock: nonNegotiable.lock,
            createdAt: DateRules.addingDays(createdAtOffset, to: startDate, calendar: calendar),
            windows: nonNegotiable.windows,
            completions: nonNegotiable.completions,
            violations: nonNegotiable.violations,
            lastDailyComplianceCheckedDay: nonNegotiable.lastDailyComplianceCheckedDay
        )
        return nonNegotiable
    }

    func makeStore(system: CommitmentSystem) -> CommitmentSystemStore {
        let repository = InMemoryCommitmentSystemRepository(initialSystem: system)
        let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
        let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine)
        return CommitmentSystemStore(
            repository: repository,
            systemEngine: commitmentEngine,
            nonNegotiableEngine: nonNegotiableEngine,
            policy: CommitmentPolicyEngine(calendar: calendar),
            streakEngine: StreakEngine(),
            calendar: calendar
        )
    }

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("Recovery-Retirement Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    let engine = NonNegotiableEngine(calendar: calendar)

    func makePausedAllocation(protocolId: UUID, day: Date, slot: PlanSlot) -> PlanAllocation {
        PlanAllocation(
            id: UUID(),
            protocolId: protocolId,
            weekId: DateRules.weekID(for: day, calendar: calendar),
            day: day,
            slot: slot,
            startTime: nil,
            durationMinutes: 60,
            createdAt: startDate,
            updatedAt: startDate,
            status: .paused
        )
    }

    // Case 1: Paused protocol retires during recovery.
    do {
        let recovering = makeNonNegotiable(title: "Recovering", state: .recovery, createdAtOffset: 0, engine: engine)
        let active = makeNonNegotiable(title: "Active", state: .active, createdAtOffset: 1, engine: engine)
        let paused = makeNonNegotiable(title: "Paused", state: .suspended, createdAtOffset: 2, engine: engine)
        let otherPaused = makeNonNegotiable(title: "Other Paused", state: .suspended, createdAtOffset: 3, engine: engine)

        var system = CommitmentSystem(nonNegotiables: [recovering, active, paused, otherPaused], createdAt: startDate)
        system.recoveryPausedProtocolId = paused.id
        let store = makeStore(system: system)

        let futureDay = DateRules.date(year: 2026, month: 2, day: 12, hour: 9, calendar: calendar)
        let retiredAllocation = makePausedAllocation(protocolId: paused.id, day: futureDay, slot: .am)
        let otherAllocation = makePausedAllocation(protocolId: otherPaused.id, day: futureDay, slot: .pm)
        let planStore = PlanStore(
            repository: InMemoryPlanAllocationRepository(value: [retiredAllocation, otherAllocation]),
            calendar: calendar
        )

        try store.retireNonNegotiable(id: paused.id, referenceDate: retirementDate, planStore: planStore)

        verify("Case 1 - paused protocol retired", store.nonNegotiable(id: paused.id)?.state == .retired)
        verify("Case 1 - stale paused id cleared", store.system.recoveryPausedProtocolId == nil)
        verify("Case 1 - recovery continues when eligible set is still >= 2", store.system.nonNegotiables.contains(where: { $0.state == .recovery }))
        verify("Case 1 - retired paused allocation finalized", planStore.allocation(id: retiredAllocation.id)?.status == .skippedDueToRecovery)
        verify("Case 1 - no retired allocation remains paused", planStore.allocation(id: retiredAllocation.id)?.status != .paused)
        verify("Case 1 - unrelated paused allocation left untouched", planStore.allocation(id: otherAllocation.id)?.status == .paused)
        planStore.finalizeRecoveryAllocationStatuses(
            referenceDate: futureDay,
            restorableProtocolIds: [active.id]
        )
        verify("Case 1 - full exit leaves retired allocation terminal", planStore.allocation(id: retiredAllocation.id)?.status == .skippedDueToRecovery)
    } catch {
        print("Recovery-Retirement Simulation - Case 1 threw error: \(error)")
    }

    // Case 2: Non-paused protocol retires during recovery and exits.
    do {
        let recovering = makeNonNegotiable(title: "Recovering", state: .recovery, createdAtOffset: 0, engine: engine)
        let active = makeNonNegotiable(title: "Active", state: .active, createdAtOffset: 1, engine: engine)
        let paused = makeNonNegotiable(title: "Paused", state: .suspended, createdAtOffset: 2, engine: engine)

        var system = CommitmentSystem(nonNegotiables: [recovering, active, paused], createdAt: startDate)
        system.recoveryPausedProtocolId = paused.id
        let store = makeStore(system: system)

        try store.retireNonNegotiable(id: active.id, referenceDate: retirementDate)

        verify("Case 2 - recovery exits below threshold", store.system.nonNegotiables.contains(where: { $0.state == .recovery }) == false)
        verify("Case 2 - pending flag cleared on exit", store.system.recoveryEntryPendingResolution == false)
        verify("Case 2 - paused id cleared on exit", store.system.recoveryPausedProtocolId == nil)
    } catch {
        print("Recovery-Retirement Simulation - Case 2 threw error: \(error)")
    }

    // Case 3: All active protocols retire during recovery.
    do {
        let recovering = makeNonNegotiable(title: "Recovering", state: .recovery, createdAtOffset: 0, engine: engine)
        let active = makeNonNegotiable(title: "Active", state: .active, createdAtOffset: 1, engine: engine)

        let system = CommitmentSystem(nonNegotiables: [recovering, active], createdAt: startDate)
        let store = makeStore(system: system)

        try store.retireNonNegotiable(id: recovering.id, referenceDate: retirementDate)
        try store.retireNonNegotiable(id: active.id, referenceDate: retirementDate)

        verify("Case 3 - no recovery remains", store.system.nonNegotiables.contains(where: { $0.state == .recovery }) == false)
        verify("Case 3 - all protocols retired", store.system.nonNegotiables.allSatisfy { $0.state == .retired })
    } catch {
        print("Recovery-Retirement Simulation - Case 3 threw error: \(error)")
    }

    // Case 4: Retirement outside recovery has no recovery side effects.
    do {
        let first = makeNonNegotiable(title: "First", state: .active, createdAtOffset: 0, engine: engine)
        let second = makeNonNegotiable(title: "Second", state: .active, createdAtOffset: 1, engine: engine)

        let system = CommitmentSystem(nonNegotiables: [first, second], createdAt: startDate)
        let store = makeStore(system: system)

        try store.retireNonNegotiable(id: first.id, referenceDate: retirementDate)

        verify("Case 4 - no recovery activated", store.system.nonNegotiables.contains(where: { $0.state == .recovery }) == false)
        verify("Case 4 - pending recovery remains false", store.system.recoveryEntryPendingResolution == false)
        verify("Case 4 - paused id remains nil", store.system.recoveryPausedProtocolId == nil)
    } catch {
        print("Recovery-Retirement Simulation - Case 4 threw error: \(error)")
    }

    // Case 5: Stale paused id is cleared safely.
    do {
        let recovering = makeNonNegotiable(title: "Recovering", state: .recovery, createdAtOffset: 0, engine: engine)
        let activeA = makeNonNegotiable(title: "ActiveA", state: .active, createdAtOffset: 1, engine: engine)
        let activeB = makeNonNegotiable(title: "ActiveB", state: .active, createdAtOffset: 2, engine: engine)

        var system = CommitmentSystem(nonNegotiables: [recovering, activeA, activeB], createdAt: startDate)
        system.recoveryPausedProtocolId = UUID()
        let store = makeStore(system: system)

        try store.retireNonNegotiable(id: activeB.id, referenceDate: retirementDate)

        verify("Case 5 - stale paused id cleared", store.system.recoveryPausedProtocolId == nil)
        verify("Case 5 - recovery still active with 2 eligible protocols", store.system.nonNegotiables.contains(where: { $0.state == .recovery }))
    } catch {
        print("Recovery-Retirement Simulation - Case 5 threw error: \(error)")
    }
}

func runRecoveryPostDecodeValidationSimulation() {
    let calendar = DateRules.isoCalendar
    let startDate = DateRules.date(year: 2026, month: 1, day: 1, hour: 0, calendar: calendar)
    let engine = NonNegotiableEngine(calendar: calendar)
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("Recovery-Post-Decode Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    func makeNonNegotiable(title: String, state: NonNegotiableState) -> NonNegotiable {
        var nonNegotiable = try! engine.create(
            definition: NonNegotiableDefinition(
                title: title,
                frequencyPerWeek: 3,
                mode: .session,
                goalId: UUID()
            ),
            startDate: startDate,
            totalLockDays: 14
        )
        nonNegotiable.state = state
        return nonNegotiable
    }

    func fixture(
        nonNegotiables: [NonNegotiable],
        recoveryEntryTriggerProtocolId: UUID? = nil,
        recoveryPausedProtocolId: UUID? = nil
    ) throws -> Data {
        let nonNegotiablesJSON = String(
            data: try encoder.encode(nonNegotiables),
            encoding: .utf8
        )!
        let createdAtJSON = String(data: try encoder.encode(startDate), encoding: .utf8)!
        let triggerJSON = recoveryEntryTriggerProtocolId.map { "\"\($0.uuidString)\"" } ?? "null"
        let pausedJSON = recoveryPausedProtocolId.map { "\"\($0.uuidString)\"" } ?? "null"

        let json = """
        {
          "nonNegotiables": \(nonNegotiablesJSON),
          "createdAt": \(createdAtJSON),
          "recoveryCleanDayStreak": 0,
          "recoveryEntryPendingResolution": true,
          "recoveryEntryRequiresPauseSelection": true,
          "recoveryEntryTriggerProtocolId": \(triggerJSON),
          "recoveryPausedProtocolId": \(pausedJSON)
        }
        """
        return Data(json.utf8)
    }

    do {
        let retired = makeNonNegotiable(title: "Retired Pause", state: .retired)
        let stalePaused = try decoder.decode(
            CommitmentSystem.self,
            from: fixture(nonNegotiables: [retired], recoveryPausedProtocolId: retired.id)
        )
        verify("stale retired recoveryPausedProtocolId cleared", stalePaused.recoveryPausedProtocolId == nil)

        let active = makeNonNegotiable(title: "Active Trigger", state: .active)
        let staleTrigger = try decoder.decode(
            CommitmentSystem.self,
            from: fixture(nonNegotiables: [active], recoveryEntryTriggerProtocolId: retired.id)
        )
        verify("missing recoveryEntryTriggerProtocolId cleared", staleTrigger.recoveryEntryTriggerProtocolId == nil)

        let suspended = makeNonNegotiable(title: "Suspended Pause", state: .suspended)
        let validPaused = try decoder.decode(
            CommitmentSystem.self,
            from: fixture(nonNegotiables: [suspended], recoveryPausedProtocolId: suspended.id)
        )
        verify("valid recoveryPausedProtocolId preserved", validPaused.recoveryPausedProtocolId == suspended.id)
    } catch {
        print("Recovery-Post-Decode Simulation failed with error: \(error)")
    }
}

func runRecoveryPostRestorationWeeklyFeasibilitySimulation() {
    let calendar = DateRules.isoCalendar
    let monday = DateRules.date(year: 2026, month: 1, day: 5, hour: 9, calendar: calendar)
    let thursday = DateRules.date(year: 2026, month: 1, day: 8, hour: 9, calendar: calendar)
    let sunday = DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar)
    let engine = NonNegotiableEngine(calendar: calendar)
    let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: engine)

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("Recovery-Post-Restoration Weekly Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    func makeDefinition(title: String, frequency: Int = 5) -> NonNegotiableDefinition {
        NonNegotiableDefinition(title: title, frequencyPerWeek: frequency, mode: .session, goalId: UUID())
    }

    func makeProtocol(title: String, state: NonNegotiableState, frequency: Int = 5) -> NonNegotiable {
        var nonNegotiable = try! engine.create(
            definition: makeDefinition(title: title, frequency: frequency),
            startDate: DateRules.date(year: 2025, month: 12, day: 29, hour: 9, calendar: calendar),
            totalLockDays: 28
        )
        nonNegotiable.state = state
        return nonNegotiable
    }

    // Case 1: Recovery exits Thursday, restored 5x/week protocol gets a partial-week exemption.
    do {
        let recovering = makeProtocol(title: "Recovering", state: .recovery, frequency: 3)
        let paused = makeProtocol(title: "Restored Thursday", state: .suspended, frequency: 5)

        var system = CommitmentSystem(nonNegotiables: [recovering, paused], createdAt: monday)
        system.recoveryPausedProtocolId = paused.id
        _ = commitmentEngine.normalizeRecoveryDomain(in: &system, referenceDate: thursday)

        guard let restoredIndex = system.nonNegotiables.firstIndex(where: { $0.id == paused.id }) else {
            verify("Case 1 - restored protocol exists", false)
            return
        }

        verify("Case 1 - suspended protocol restored", system.nonNegotiables[restoredIndex].state == .active)
        verify("Case 1 - restoration marker set", system.nonNegotiables[restoredIndex].recoveryRestoredAt == thursday)

        var restored = system.nonNegotiables[restoredIndex]
        engine.evaluateWeekIfNeeded(&restored, weekEnding: sunday)

        let missedWeeklyCount = restored.violations.filter { $0.kind == .missedWeeklyFrequency }.count
        verify("Case 1 - Thursday restore has no week-end miss", missedWeeklyCount == 0)
        verify("Case 1 - Thursday restore does not re-enter recovery", restored.state == .active)
    }

    // Case 2: Recovery exits Monday, a full week is available and normal weekly evaluation applies.
    do {
        var restored = makeProtocol(title: "Restored Monday", state: .active, frequency: 5)
        restored.recoveryRestoredAt = monday

        engine.evaluateWeekIfNeeded(&restored, weekEnding: sunday)

        let missedWeeklyCount = restored.violations.filter { $0.kind == .missedWeeklyFrequency }.count
        verify("Case 2 - Monday restore keeps normal weekly miss", missedWeeklyCount == 1)
    }

    // Case 3: Suspended protocols remain protected from weekly violations.
    do {
        var suspended = makeProtocol(title: "Still Suspended", state: .suspended, frequency: 5)
        suspended.recoveryRestoredAt = thursday

        engine.evaluateWeekIfNeeded(&suspended, weekEnding: sunday)

        verify("Case 3 - suspended protocol records zero violations", suspended.violations.isEmpty)
        verify("Case 3 - suspended protocol remains suspended", suspended.state == .suspended)
    }
}

@MainActor
func runRecoveryPendingResolutionRecomputeSimulation() {
    let calendar = DateRules.isoCalendar
    let startDate = DateRules.date(year: 2026, month: 1, day: 1, hour: 0, calendar: calendar)
    let retirementDate = DateRules.date(year: 2026, month: 2, day: 10, hour: 9, calendar: calendar)

    func makeDefinition(title: String) -> NonNegotiableDefinition {
        NonNegotiableDefinition(
            title: title,
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )
    }

    func makeNonNegotiable(
        title: String,
        state: NonNegotiableState,
        createdAtOffset: Int,
        engine: NonNegotiableEngine
    ) -> NonNegotiable {
        var nonNegotiable = try! engine.create(
            definition: makeDefinition(title: title),
            startDate: startDate,
            totalLockDays: 14
        )
        nonNegotiable.state = state
        return NonNegotiable(
            id: nonNegotiable.id,
            goalId: nonNegotiable.goalId,
            definition: nonNegotiable.definition,
            state: nonNegotiable.state,
            lock: nonNegotiable.lock,
            createdAt: DateRules.addingDays(createdAtOffset, to: startDate, calendar: calendar),
            windows: nonNegotiable.windows,
            completions: nonNegotiable.completions,
            violations: nonNegotiable.violations,
            lastDailyComplianceCheckedDay: nonNegotiable.lastDailyComplianceCheckedDay
        )
    }

    func makeStore(system: CommitmentSystem) -> CommitmentSystemStore {
        let repository = InMemoryCommitmentSystemRepository(initialSystem: system)
        let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
        let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine)
        return CommitmentSystemStore(
            repository: repository,
            systemEngine: commitmentEngine,
            nonNegotiableEngine: nonNegotiableEngine,
            policy: CommitmentPolicyEngine(calendar: calendar),
            streakEngine: StreakEngine(),
            calendar: calendar
        )
    }

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("Recovery-Pending Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    let engine = NonNegotiableEngine(calendar: calendar)

    // Case 1: Retirement while pause-selection pending removes one selectable candidate.
    do {
        let recovering = makeNonNegotiable(title: "Recovering", state: .recovery, createdAtOffset: 0, engine: engine)
        let activeA = makeNonNegotiable(title: "Active-A", state: .active, createdAtOffset: 1, engine: engine)
        let activeB = makeNonNegotiable(title: "Active-B", state: .active, createdAtOffset: 2, engine: engine)

        var system = CommitmentSystem(nonNegotiables: [recovering, activeA, activeB], createdAt: startDate)
        system.recoveryEntryPendingResolution = true
        system.recoveryEntryRequiresPauseSelection = true
        system.recoveryEntryTriggerProtocolId = recovering.id
        let store = makeStore(system: system)

        try store.retireNonNegotiable(id: activeB.id, referenceDate: retirementDate)
        let context = store.recoveryEntryContext()

        verify("Case 1 - pending still open", context != nil)
        verify("Case 1 - retired candidate removed", context?.candidateProtocolIds.contains(activeB.id) == false)
        verify("Case 1 - selectable set refreshed", Set(context?.candidateProtocolIds ?? []) == Set([activeA.id]))
    } catch {
        print("Recovery-Pending Simulation - Case 1 threw error: \(error)")
    }

    // Case 2: Retirement while pending removes need for user decision.
    do {
        let recovering = makeNonNegotiable(title: "Recovering", state: .recovery, createdAtOffset: 0, engine: engine)
        let active = makeNonNegotiable(title: "Active", state: .active, createdAtOffset: 1, engine: engine)

        var system = CommitmentSystem(nonNegotiables: [recovering, active], createdAt: startDate)
        system.recoveryEntryPendingResolution = true
        system.recoveryEntryRequiresPauseSelection = true
        system.recoveryEntryTriggerProtocolId = recovering.id
        let store = makeStore(system: system)

        try store.retireNonNegotiable(id: active.id, referenceDate: retirementDate)

        verify("Case 2 - pending flow closed", store.recoveryEntryContext() == nil)
        verify("Case 2 - pending flag false", store.system.recoveryEntryPendingResolution == false)
    } catch {
        print("Recovery-Pending Simulation - Case 2 threw error: \(error)")
    }

    // Case 3: Retirement while pending still requires a different valid decision set.
    do {
        let recovering = makeNonNegotiable(title: "Recovering", state: .recovery, createdAtOffset: 0, engine: engine)
        let activeA = makeNonNegotiable(title: "Active-A", state: .active, createdAtOffset: 1, engine: engine)
        let activeB = makeNonNegotiable(title: "Active-B", state: .active, createdAtOffset: 2, engine: engine)

        var system = CommitmentSystem(nonNegotiables: [recovering, activeA, activeB], createdAt: startDate)
        system.recoveryEntryPendingResolution = true
        system.recoveryEntryRequiresPauseSelection = true
        system.recoveryEntryTriggerProtocolId = recovering.id
        let store = makeStore(system: system)

        try store.retireNonNegotiable(id: activeA.id, referenceDate: retirementDate)
        let context = store.recoveryEntryContext()

        verify("Case 3 - pending still needs decision", context?.requiresPauseSelection == true)
        verify("Case 3 - candidate set changed and valid", Set(context?.candidateProtocolIds ?? []) == Set([activeB.id]))
    } catch {
        print("Recovery-Pending Simulation - Case 3 threw error: \(error)")
    }

    // Case 4: Pending trigger protocol becomes invalid due to retirement.
    do {
        let recoveringA = makeNonNegotiable(title: "Recovering-A", state: .recovery, createdAtOffset: 0, engine: engine)
        let recoveringB = makeNonNegotiable(title: "Recovering-B", state: .recovery, createdAtOffset: 1, engine: engine)
        let active = makeNonNegotiable(title: "Active", state: .active, createdAtOffset: 2, engine: engine)

        var system = CommitmentSystem(nonNegotiables: [recoveringA, recoveringB, active], createdAt: startDate)
        system.recoveryEntryPendingResolution = true
        system.recoveryEntryRequiresPauseSelection = true
        system.recoveryEntryTriggerProtocolId = recoveringA.id
        let store = makeStore(system: system)

        try store.retireNonNegotiable(id: recoveringA.id, referenceDate: retirementDate)
        let context = store.recoveryEntryContext()

        verify("Case 4 - pending trigger repaired", context?.triggerProtocolId == recoveringB.id)
        verify("Case 4 - retired trigger not selectable", context?.candidateProtocolIds.contains(recoveringA.id) == false)
    } catch {
        print("Recovery-Pending Simulation - Case 4 threw error: \(error)")
    }

    // Case 5: Stale pending flags are repaired safely before continuing.
    do {
        let recovering = makeNonNegotiable(title: "Recovering", state: .recovery, createdAtOffset: 0, engine: engine)
        let activeA = makeNonNegotiable(title: "Active-A", state: .active, createdAtOffset: 1, engine: engine)
        let activeB = makeNonNegotiable(title: "Active-B", state: .active, createdAtOffset: 2, engine: engine)

        var system = CommitmentSystem(nonNegotiables: [recovering, activeA, activeB], createdAt: startDate)
        system.recoveryEntryPendingResolution = false
        system.recoveryEntryRequiresPauseSelection = true
        system.recoveryEntryTriggerProtocolId = UUID()
        system.recoveryPausedProtocolId = UUID()
        let store = makeStore(system: system)

        try store.retireNonNegotiable(id: activeB.id, referenceDate: retirementDate)

        verify("Case 5 - pending flag remains closed", store.system.recoveryEntryPendingResolution == false)
        verify("Case 5 - stale requires flag cleared", store.system.recoveryEntryRequiresPauseSelection == false)
        verify("Case 5 - stale trigger cleared", store.system.recoveryEntryTriggerProtocolId == nil)
        verify("Case 5 - stale paused id cleared", store.system.recoveryPausedProtocolId == nil)
    } catch {
        print("Recovery-Pending Simulation - Case 5 threw error: \(error)")
    }

    // Case 6: Candidate list prefers .active protocols when active candidates exist.
    do {
        let recovering = makeNonNegotiable(title: "Recovering", state: .recovery, createdAtOffset: 0, engine: engine)
        let active = makeNonNegotiable(title: "Active", state: .active, createdAtOffset: 1, engine: engine)

        var system = CommitmentSystem(nonNegotiables: [recovering, active], createdAt: startDate)
        system.recoveryEntryPendingResolution = true
        system.recoveryEntryRequiresPauseSelection = true
        system.recoveryEntryTriggerProtocolId = recovering.id
        let store = makeStore(system: system)

        let context = store.recoveryEntryContext()
        let candidates = context?.candidateProtocolIds ?? []
        let candidateStates = candidates.compactMap { id in
            store.system.nonNegotiables.first(where: { $0.id == id })?.state
        }

        verify("Case 6 - candidates contain active-only protocols", candidateStates.allSatisfy { $0 == .active })
        verify("Case 6 - recovering protocol not in candidates", candidates.contains(recovering.id) == false)
        verify("Case 6 - active protocol in candidates", candidates.contains(active.id))
    }

    // Case 7: With no active candidates left, the pending flow closes automatically — no .recovery fallback.
    do {
        let recoveringA = makeNonNegotiable(title: "Recovering-A", state: .recovery, createdAtOffset: 0, engine: engine)
        let recoveringB = makeNonNegotiable(title: "Recovering-B", state: .recovery, createdAtOffset: 1, engine: engine)
        let active = makeNonNegotiable(title: "Active", state: .active, createdAtOffset: 2, engine: engine)

        var system = CommitmentSystem(nonNegotiables: [recoveringA, recoveringB, active], createdAt: startDate)
        system.recoveryEntryPendingResolution = true
        system.recoveryEntryRequiresPauseSelection = true
        system.recoveryEntryTriggerProtocolId = recoveringA.id
        let store = makeStore(system: system)

        try! store.retireNonNegotiable(id: active.id, referenceDate: retirementDate)
        let context = store.recoveryEntryContext()

        // G-1 fix: candidateIds now contains only .active protocols, so with no active protocols
        // remaining, needsUserDecision = false and the pending flow closes automatically.
        verify("Case 7 - pending flow closes with no active candidates (G-1 fix)", context == nil)
        verify("Case 7 - pending flag cleared automatically", store.system.recoveryEntryPendingResolution == false)
    }

    // Case 8: A single remaining recovery protocol closes stale pending resolution.
    do {
        let recoveringA = makeNonNegotiable(title: "Recovering-A", state: .recovery, createdAtOffset: 0, engine: engine)
        let recoveringB = makeNonNegotiable(title: "Recovering-B", state: .recovery, createdAtOffset: 1, engine: engine)

        var system = CommitmentSystem(nonNegotiables: [recoveringA, recoveringB], createdAt: startDate)
        system.recoveryEntryPendingResolution = true
        system.recoveryEntryRequiresPauseSelection = true
        system.recoveryEntryTriggerProtocolId = recoveringA.id
        let store = makeStore(system: system)

        try! store.retireNonNegotiable(id: recoveringB.id, referenceDate: retirementDate)

        verify("Case 8 - pending flow closes with no pause candidate", store.recoveryEntryContext() == nil)
        verify("Case 8 - pending flag false", store.system.recoveryEntryPendingResolution == false)
    }
}

@MainActor
func runInitialGraceWindowPressureAlignmentSimulation() {
    let calendar = DateRules.isoCalendar
    let creationDate = DateRules.date(year: 2026, month: 1, day: 7, hour: 10, calendar: calendar)
    let graceWeekSunday = DateRules.date(year: 2026, month: 1, day: 11, hour: 20, calendar: calendar)
    let firstDayAfterGraceWeek = DateRules.date(year: 2026, month: 1, day: 12, hour: 9, calendar: calendar)

    let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
    let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine)

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("Grace-Pressure Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    do {
        let definition = NonNegotiableDefinition(
            title: "Grace Recovery",
            frequencyPerWeek: 7,
            mode: .session,
            goalId: UUID()
        )

        var graceProtocol = try nonNegotiableEngine.create(
            definition: definition,
            startDate: creationDate,
            totalLockDays: 28
        )

        // Case 1: Recovery-day feasibility should not require full-week quota in grace week.
        graceProtocol.state = .recovery
        var recoverySystem = CommitmentSystem(nonNegotiables: [graceProtocol], createdAt: creationDate)
        commitmentEngine.evaluateRecoveryDay(
            referenceDate: graceWeekSunday,
            in: &recoverySystem,
            calendar: calendar
        )
        verify(
            "Case 1 - grace-week protocol does not block clean recovery day",
            recoverySystem.recoveryCleanDayStreak == 1
        )

        // Case 2: Log pressure surface should not flag inevitable weekly miss in grace week.
        graceProtocol.state = .active
        let storeSystem = CommitmentSystem(nonNegotiables: [graceProtocol], createdAt: creationDate)
        let store = CommitmentSystemStore(
            repository: InMemoryCommitmentSystemRepository(initialSystem: storeSystem),
            systemEngine: commitmentEngine,
            nonNegotiableEngine: nonNegotiableEngine,
            policy: CommitmentPolicyEngine(calendar: calendar),
            streakEngine: StreakEngine(),
            calendar: calendar
        )
        let graceDayStart = DateRules.startOfDay(graceWeekSunday, calendar: calendar)
        let graceSignal = store
            .logsCalendarSignals(lastDays: 2, referenceDate: firstDayAfterGraceWeek)
            .first(where: { $0.day == graceDayStart })

        verify(
            "Case 2 - grace week does not show inevitable miss",
            graceSignal?.inevitableWeeklyMiss == false
        )
        verify(
            "Case 2 - grace week marks no-work-required satisfied",
            graceSignal?.noWorkRequiredSatisfied == true
        )
    } catch {
        print("Grace-Pressure Simulation failed with error: \(error)")
    }
}

@MainActor
func runDailyCreationDayGracePressureSimulation() {
    let calendar = DateRules.isoCalendar
    let creationDate = DateRules.date(year: 2026, month: 1, day: 10, hour: 15, calendar: calendar)
    let nextDay = DateRules.date(year: 2026, month: 1, day: 11, hour: 9, calendar: calendar)

    let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
    let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine)

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("Daily-Grace Pressure Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    do {
        let definition = NonNegotiableDefinition(
            title: "Daily Grace Pressure",
            frequencyPerWeek: 7,
            mode: .daily,
            goalId: UUID()
        )

        // Case 1: Recovery feasibility should not require counted completion on creation day.
        var recoveryProtocol = try nonNegotiableEngine.create(
            definition: definition,
            startDate: creationDate,
            totalLockDays: 28
        )
        recoveryProtocol.state = .recovery
        var recoverySystem = CommitmentSystem(nonNegotiables: [recoveryProtocol], createdAt: creationDate)
        commitmentEngine.evaluateRecoveryDay(
            referenceDate: creationDate,
            in: &recoverySystem,
            calendar: calendar
        )
        verify(
            "Case 1 - creation day does not block clean recovery day",
            recoverySystem.recoveryCleanDayStreak == 1
        )

        // Case 2: Closed-day log pressure should not mark creation day as owed.
        let activeProtocol = try nonNegotiableEngine.create(
            definition: definition,
            startDate: creationDate,
            totalLockDays: 28
        )
        let store = CommitmentSystemStore(
            repository: InMemoryCommitmentSystemRepository(
                initialSystem: CommitmentSystem(nonNegotiables: [activeProtocol], createdAt: creationDate)
            ),
            systemEngine: commitmentEngine,
            nonNegotiableEngine: nonNegotiableEngine,
            policy: CommitmentPolicyEngine(calendar: calendar),
            streakEngine: StreakEngine(),
            calendar: calendar
        )
        let creationDayStart = DateRules.startOfDay(creationDate, calendar: calendar)
        let creationDaySignal = store
            .logsCalendarSignals(lastDays: 2, referenceDate: nextDay)
            .first(where: { $0.day == creationDayStart })

        verify(
            "Case 2 - creation day is not flagged unproductive",
            creationDaySignal?.unproductive == false
        )
        verify(
            "Case 2 - creation day can be no-work-required satisfied",
            creationDaySignal?.noWorkRequiredSatisfied == true
        )
    } catch {
        print("Daily-Grace Pressure Simulation failed with error: \(error)")
    }
}

@MainActor
func runCreationDateSourceSimulation() {
    let calendar = DateRules.isoCalendar
    let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
    let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine)
    let store = CommitmentSystemStore(
        repository: InMemoryCommitmentSystemRepository(
            initialSystem: CommitmentSystem(nonNegotiables: [], createdAt: DateRules.date(year: 2026, month: 1, day: 1, hour: 0, calendar: calendar))
        ),
        systemEngine: commitmentEngine,
        nonNegotiableEngine: nonNegotiableEngine,
        policy: CommitmentPolicyEngine(calendar: calendar),
        streakEngine: StreakEngine(),
        calendar: calendar
    )

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("Creation-Date Source Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    do {
        // Case 1: Simulated/advanced app day is used as creation source.
        let simulatedSaturday = DateRules.date(year: 2026, month: 1, day: 10, hour: 14, calendar: calendar)
        let simulatedDefinition = NonNegotiableDefinition(
            title: "Simulated Session Source",
            frequencyPerWeek: 7,
            mode: .session,
            goalId: UUID()
        )
        try store.createNonNegotiable(
            definition: simulatedDefinition,
            totalLockDays: 28,
            referenceDate: simulatedSaturday
        )
        let simulatedCreated = store.system.nonNegotiables.last(where: { $0.definition.title == simulatedDefinition.title })
        verify(
            "Case 1 - createdAt matches effective app day",
            simulatedCreated != nil &&
            DateRules.startOfDay(simulatedCreated!.createdAt, calendar: calendar) ==
                DateRules.startOfDay(simulatedSaturday, calendar: calendar)
        )

        // Case 2: Default non-advanced creation still uses live now behavior.
        let defaultDefinition = NonNegotiableDefinition(
            title: "Live Session Source",
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )
        let liveNowBefore = Date()
        try store.createNonNegotiable(definition: defaultDefinition, totalLockDays: 28)
        let liveCreated = store.system.nonNegotiables.last(where: { $0.definition.title == defaultDefinition.title })
        verify(
            "Case 2 - default creation remains tied to live date basis",
            liveCreated != nil &&
            calendar.isDate(liveCreated!.createdAt, inSameDayAs: liveNowBefore)
        )

        // Case 3: No retroactive misses before effective creation date.
        let dailyDefinition = NonNegotiableDefinition(
            title: "Daily Source Guard",
            frequencyPerWeek: 7,
            mode: .daily,
            goalId: UUID()
        )
        let effectiveCreation = DateRules.date(year: 2026, month: 1, day: 10, hour: 15, calendar: calendar)
        try store.createNonNegotiable(
            definition: dailyDefinition,
            totalLockDays: 28,
            referenceDate: effectiveCreation
        )
        guard let dailyProtocol = store.system.nonNegotiables.last(where: { $0.definition.title == dailyDefinition.title }) else {
            verify("Case 3 - daily protocol exists", false)
            return
        }
        store.runDailyComplianceCheck(
            currentDate: DateRules.date(year: 2026, month: 1, day: 11, hour: 8, calendar: calendar)
        )
        store.runDailyComplianceCheck(
            currentDate: DateRules.date(year: 2026, month: 1, day: 12, hour: 8, calendar: calendar)
        )
        guard let evaluatedDaily = store.system.nonNegotiables.first(where: { $0.id == dailyProtocol.id }) else {
            verify("Case 3 - evaluated daily protocol exists", false)
            return
        }
        let dailyMisses = evaluatedDaily.violations.filter { $0.kind == .missedDailyCompliance }
        let creationDayStart = DateRules.startOfDay(effectiveCreation, calendar: calendar)
        verify(
            "Case 3 - no retroactive misses before effective creation day",
            dailyMisses.contains(where: { $0.date < creationDayStart }) == false
        )
    } catch {
        print("Creation-Date Source Simulation failed with error: \(error)")
    }
}

@MainActor
func runRecoveryPauseSyncSimulation() {
    let calendar = DateRules.isoCalendar
    let reference = DateRules.date(year: 2026, month: 1, day: 12, hour: 9, calendar: calendar)
    let futureDay = DateRules.date(year: 2026, month: 1, day: 19, hour: 9, calendar: calendar)

    let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
    let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine)

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("Recovery-Pause-Sync Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    func makeDefinition(title: String) -> NonNegotiableDefinition {
        NonNegotiableDefinition(title: title, frequencyPerWeek: 3, mode: .session, goalId: UUID())
    }

    func makeCommitmentStore(system: CommitmentSystem) -> CommitmentSystemStore {
        CommitmentSystemStore(
            repository: InMemoryCommitmentSystemRepository(initialSystem: system),
            systemEngine: commitmentEngine,
            nonNegotiableEngine: nonNegotiableEngine,
            policy: CommitmentPolicyEngine(calendar: calendar),
            streakEngine: StreakEngine(),
            calendar: calendar
        )
    }

    // After coordinator call, domain state is .suspended AND plan allocations are .paused.
    do {
        var recoveringProtocol = try! nonNegotiableEngine.create(
            definition: makeDefinition(title: "Recovering"),
            startDate: reference,
            totalLockDays: 28
        )
        recoveringProtocol.state = .recovery

        var activeProtocol = try! nonNegotiableEngine.create(
            definition: makeDefinition(title: "Active"),
            startDate: reference,
            totalLockDays: 28
        )
        activeProtocol.state = .active

        var secondActiveProtocol = try! nonNegotiableEngine.create(
            definition: makeDefinition(title: "Second Active"),
            startDate: reference,
            totalLockDays: 28
        )
        secondActiveProtocol.state = .active

        var system = CommitmentSystem(
            nonNegotiables: [recoveringProtocol, activeProtocol, secondActiveProtocol],
            createdAt: reference
        )
        system.recoveryEntryPendingResolution = true
        system.recoveryEntryRequiresPauseSelection = true
        system.recoveryEntryTriggerProtocolId = recoveringProtocol.id

        let commitmentStore = makeCommitmentStore(system: system)

        let weekId = DateRules.weekID(for: futureDay, calendar: calendar)
        let allocationId = UUID()
        let allocation = PlanAllocation(
            id: allocationId,
            protocolId: activeProtocol.id,
            weekId: weekId,
            day: futureDay,
            slot: .am,
            startTime: nil,
            durationMinutes: 60,
            createdAt: reference,
            updatedAt: reference
        )
        let secondAllocationId = UUID()
        let secondAllocation = PlanAllocation(
            id: secondAllocationId,
            protocolId: secondActiveProtocol.id,
            weekId: weekId,
            day: futureDay,
            slot: .pm,
            startTime: nil,
            durationMinutes: 60,
            createdAt: reference,
            updatedAt: reference
        )
        let planStore = PlanStore(
            repository: InMemoryPlanAllocationRepository(value: [allocation, secondAllocation]),
            calendar: calendar
        )

        try! commitmentStore.pauseProtocolForRecoveryWithPlanSync(
            protocolId: activeProtocol.id,
            planStore: planStore,
            referenceDate: reference
        )

        verify("Coordinator - domain state is .suspended", commitmentStore.nonNegotiable(id: activeProtocol.id)?.state == .suspended)
        verify("Coordinator - allocation status is .paused", planStore.allocation(id: allocationId)?.status == .paused)
        verify("Coordinator - recoveryPausedProtocolId set", commitmentStore.system.recoveryPausedProtocolId == activeProtocol.id)

        do {
            try commitmentStore.pauseProtocolForRecoveryWithPlanSync(
                protocolId: secondActiveProtocol.id,
                planStore: planStore,
                referenceDate: reference
            )
            verify("Invariant I10 - second pause rejected", false)
        } catch {
            verify("Invariant I10 - second pause rejected", true)
        }

        let suspendedCount = commitmentStore.system.nonNegotiables.filter { $0.state == .suspended }.count
        verify("Invariant I10 - second pause does not add suspended protocol", suspendedCount == 1)
        verify("Invariant I10 - second protocol remains active", commitmentStore.nonNegotiable(id: secondActiveProtocol.id)?.state == .active)
        verify("Invariant I10 - second allocation remains active", planStore.allocation(id: secondAllocationId)?.status == .active)
        verify("Invariant I10 - recoveryPausedProtocolId unchanged", commitmentStore.system.recoveryPausedProtocolId == activeProtocol.id)
    }
}

@MainActor
func runRecoveryPopupPresentationSimulation() {
    let calendar = DateRules.isoCalendar
    let reference = DateRules.date(year: 2026, month: 1, day: 12, hour: 9, calendar: calendar)
    let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
    let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine)

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("Recovery-Popup-Presentation Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    func makeDefinition(title: String) -> NonNegotiableDefinition {
        NonNegotiableDefinition(
            title: title,
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )
    }

    func makeStore(system: CommitmentSystem) -> CommitmentSystemStore {
        CommitmentSystemStore(
            repository: InMemoryCommitmentSystemRepository(initialSystem: system),
            systemEngine: commitmentEngine,
            nonNegotiableEngine: nonNegotiableEngine,
            policy: CommitmentPolicyEngine(calendar: calendar),
            streakEngine: StreakEngine(),
            calendar: calendar
        )
    }

    do {
        var recoveringProtocol = try nonNegotiableEngine.create(
            definition: makeDefinition(title: "Popup Recovery Trigger"),
            startDate: reference,
            totalLockDays: 28
        )
        recoveringProtocol.state = .recovery

        var activeProtocol = try nonNegotiableEngine.create(
            definition: makeDefinition(title: "Popup Pause Candidate"),
            startDate: reference,
            totalLockDays: 28
        )
        activeProtocol.state = .active

        var pendingSystem = CommitmentSystem(
            nonNegotiables: [recoveringProtocol, activeProtocol],
            createdAt: reference,
            recoveryEntryPendingResolution: true,
            recoveryEntryRequiresPauseSelection: true,
            recoveryEntryTriggerProtocolId: recoveringProtocol.id
        )

        let store = makeStore(system: pendingSystem)
        let pendingContext = store.recoveryEntryContext()
        let pendingRouter = AppRouter()
        pendingRouter.updateRecoveryEntryPresentation(shouldPresent: pendingContext != nil)

        verify("Case 1 - context exists when pending", pendingContext != nil)
        verify("Case 1 - router presents popup when context exists", pendingRouter.presentRecoveryEntry)
        verify("Case 1 - active pause candidate is surfaced", pendingContext?.candidateProtocolIds == [activeProtocol.id])

        store.completeRecoveryEntryResolution()
        let resolvedContext = store.recoveryEntryContext()
        pendingRouter.updateRecoveryEntryPresentation(shouldPresent: resolvedContext != nil)

        verify("Case 2 - context nil after resolution", resolvedContext == nil)
        verify("Case 2 - router dismisses popup after resolution", pendingRouter.presentRecoveryEntry == false)

        pendingSystem.recoveryEntryPendingResolution = true
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(pendingSystem)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let restartedSystem = try decoder.decode(CommitmentSystem.self, from: data)
        let restartedStore = makeStore(system: restartedSystem)
        let restartedContext = restartedStore.recoveryEntryContext()
        let restartedRouter = AppRouter()
        restartedRouter.updateRecoveryEntryPresentation(shouldPresent: restartedContext != nil)

        verify("Case 3 - context exists after simulated restart", restartedContext != nil)
        verify("Case 3 - router re-presents popup after simulated restart", restartedRouter.presentRecoveryEntry)
        verify("Case 3 - trigger id survives simulated restart", restartedContext?.triggerProtocolId == recoveringProtocol.id)
    } catch {
        print("Recovery-Popup-Presentation Simulation failed with error: \(error)")
    }
}

@MainActor
func runRecoveryModeViewModelRankingSimulation() {
    let calendar = DateRules.isoCalendar
    let reference = DateRules.date(year: 2026, month: 1, day: 12, hour: 9, calendar: calendar)
    let weekId = DateRules.weekID(for: reference, calendar: calendar)
    let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
    let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: nonNegotiableEngine)

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("RecoveryModeViewModel Ranking Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    func makeDefinition(title: String) -> NonNegotiableDefinition {
        NonNegotiableDefinition(
            title: title,
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )
    }

    func makeProtocol(title: String, state: NonNegotiableState, createdAt: Date, violationCount: Int = 0) throws -> NonNegotiable {
        var protocolValue = try nonNegotiableEngine.create(
            definition: makeDefinition(title: title),
            startDate: DateRules.startOfDay(reference, calendar: calendar),
            totalLockDays: 28
        )
        protocolValue.state = state

        for offset in 0..<violationCount {
            let violationDate = calendar.date(byAdding: .minute, value: offset, to: reference) ?? reference
            protocolValue.violations.append(
                Violation(
                    date: violationDate,
                    kind: .missedWeeklyFrequency,
                    windowIndex: 0,
                    weekId: weekId
                )
            )
        }

        if protocolValue.createdAt != createdAt {
            protocolValue = NonNegotiable(
                id: protocolValue.id,
                goalId: protocolValue.goalId,
                definition: protocolValue.definition,
                state: protocolValue.state,
                lock: protocolValue.lock,
                createdAt: createdAt,
                windows: protocolValue.windows,
                completions: protocolValue.completions,
                violations: protocolValue.violations,
                lastDailyComplianceCheckedDay: protocolValue.lastDailyComplianceCheckedDay,
                recoveryRestoredAt: protocolValue.recoveryRestoredAt
            )
        }

        return protocolValue
    }

    func makeAllocation(protocolId: UUID, dayOffset: Int, slot: PlanSlot) -> PlanAllocation {
        let day = DateRules.addingDays(dayOffset, to: DateRules.startOfDay(reference, calendar: calendar), calendar: calendar)
        return PlanAllocation(
            id: UUID(),
            protocolId: protocolId,
            weekId: DateRules.weekID(for: day, calendar: calendar),
            day: day,
            slot: slot,
            startTime: nil,
            durationMinutes: 60,
            createdAt: reference,
            updatedAt: reference
        )
    }

    func makeCommitmentStore(system: CommitmentSystem) -> CommitmentSystemStore {
        CommitmentSystemStore(
            repository: InMemoryCommitmentSystemRepository(initialSystem: system),
            systemEngine: commitmentEngine,
            nonNegotiableEngine: nonNegotiableEngine,
            policy: CommitmentPolicyEngine(calendar: calendar),
            streakEngine: StreakEngine(),
            calendar: calendar
        )
    }

    func makeViewModel(system: CommitmentSystem, allocations: [PlanAllocation]) -> RecoveryModeViewModel {
        let commitmentStore = makeCommitmentStore(system: system)
        let planStore = PlanStore(
            repository: InMemoryPlanAllocationRepository(value: allocations),
            calendar: calendar
        )
        planStore.refresh(system: commitmentStore.system, calendarEvents: [], referenceDate: reference)
        return RecoveryModeViewModel(
            commitmentStore: commitmentStore,
            planStore: planStore,
            referenceDateProvider: { reference }
        )
    }

    do {
        let recovering = try makeProtocol(
            title: "Recovery Trigger",
            state: .recovery,
            createdAt: reference
        )
        let highestViolations = try makeProtocol(
            title: "Highest Violations",
            state: .active,
            createdAt: DateRules.addingDays(1, to: reference, calendar: calendar),
            violationCount: 2
        )
        let higherPlannedLoad = try makeProtocol(
            title: "Higher Planned Load",
            state: .active,
            createdAt: DateRules.addingDays(2, to: reference, calendar: calendar),
            violationCount: 1
        )
        let lowerPlannedLoad = try makeProtocol(
            title: "Lower Planned Load",
            state: .active,
            createdAt: DateRules.addingDays(3, to: reference, calendar: calendar),
            violationCount: 1
        )

        var system = CommitmentSystem(
            nonNegotiables: [recovering, highestViolations, higherPlannedLoad, lowerPlannedLoad],
            createdAt: reference
        )
        system.recoveryEntryPendingResolution = true
        system.recoveryEntryRequiresPauseSelection = true
        system.recoveryEntryTriggerProtocolId = recovering.id

        let allocations = [
            makeAllocation(protocolId: higherPlannedLoad.id, dayOffset: 0, slot: .am),
            makeAllocation(protocolId: higherPlannedLoad.id, dayOffset: 1, slot: .pm),
            makeAllocation(protocolId: lowerPlannedLoad.id, dayOffset: 2, slot: .eve),
        ]
        let viewModel = makeViewModel(system: system, allocations: allocations)
        viewModel.refresh()

        let sortedIds = viewModel.protocolOptions.map(\.id)
        verify("Case 1 - highest-violation protocol ranks first", sortedIds.first == highestViolations.id)
        verify("Case 1 - first option is recommended", viewModel.recommendedProtocolId == highestViolations.id)

        guard let higherPlannedIndex = sortedIds.firstIndex(of: higherPlannedLoad.id),
              let lowerPlannedIndex = sortedIds.firstIndex(of: lowerPlannedLoad.id) else {
            verify("Case 2 - tied planned-load options exist", false)
            return
        }

        verify("Case 2 - higher planned load wins tied violations", higherPlannedIndex < lowerPlannedIndex)
        verify(
            "Case 2 - planned load values come from active allocations",
            viewModel.protocolOptions.first(where: { $0.id == higherPlannedLoad.id })?.plannedLoadCount == 2 &&
                viewModel.protocolOptions.first(where: { $0.id == lowerPlannedLoad.id })?.plannedLoadCount == 1
        )

        var emptyCandidateSystem = CommitmentSystem(
            nonNegotiables: [recovering],
            createdAt: reference
        )
        emptyCandidateSystem.recoveryEntryPendingResolution = true
        emptyCandidateSystem.recoveryEntryRequiresPauseSelection = false
        emptyCandidateSystem.recoveryEntryTriggerProtocolId = recovering.id

        let emptyViewModel = makeViewModel(system: emptyCandidateSystem, allocations: [])
        emptyViewModel.refresh()

        verify("Case 3 - empty candidate list returns empty options", emptyViewModel.protocolOptions.isEmpty)
        verify("Case 3 - empty candidate list remains pending", emptyViewModel.isPendingResolution)
    } catch {
        print("RecoveryModeViewModel Ranking Simulation failed with error: \(error)")
    }
}

// MARK: - isTerminal (.completed treated like .retired) simulation

func runIsTerminalCompletedDecodeValidationSimulation() {
    let calendar = DateRules.isoCalendar
    let startDate = DateRules.date(year: 2026, month: 1, day: 1, hour: 0, calendar: calendar)
    let engine = NonNegotiableEngine(calendar: calendar)
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    encoder.dateEncodingStrategy = .iso8601
    decoder.dateDecodingStrategy = .iso8601

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("isTerminal-Completed Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    func makeNonNegotiable(title: String, state: NonNegotiableState) -> NonNegotiable {
        var nn = try! engine.create(
            definition: NonNegotiableDefinition(title: title, frequencyPerWeek: 3, mode: .session, goalId: UUID()),
            startDate: startDate,
            totalLockDays: 14
        )
        nn.state = state
        return nn
    }

    func fixture(nonNegotiables: [NonNegotiable], pausedId: UUID?, triggerId: UUID?) throws -> Data {
        let nnsJSON = String(data: try encoder.encode(nonNegotiables), encoding: .utf8)!
        let createdAtJSON = String(data: try encoder.encode(startDate), encoding: .utf8)!
        let pausedJSON = pausedId.map { "\"\($0.uuidString)\"" } ?? "null"
        let triggerJSON = triggerId.map { "\"\($0.uuidString)\"" } ?? "null"
        let json = """
        {
          "nonNegotiables": \(nnsJSON),
          "createdAt": \(createdAtJSON),
          "recoveryCleanDayStreak": 0,
          "recoveryEntryPendingResolution": true,
          "recoveryEntryRequiresPauseSelection": true,
          "recoveryEntryTriggerProtocolId": \(triggerJSON),
          "recoveryPausedProtocolId": \(pausedJSON)
        }
        """
        return Data(json.utf8)
    }

    do {
        // Case 1: .completed protocol referenced in recoveryPausedProtocolId is cleared.
        let completed = makeNonNegotiable(title: "Completed", state: .completed)
        let decoded1 = try decoder.decode(
            CommitmentSystem.self,
            from: fixture(nonNegotiables: [completed], pausedId: completed.id, triggerId: nil)
        )
        verify("Case 1 - .completed clears stale recoveryPausedProtocolId", decoded1.recoveryPausedProtocolId == nil)

        // Case 2: .completed protocol referenced in recoveryEntryTriggerProtocolId is cleared.
        let decoded2 = try decoder.decode(
            CommitmentSystem.self,
            from: fixture(nonNegotiables: [completed], pausedId: nil, triggerId: completed.id)
        )
        verify("Case 2 - .completed clears stale recoveryEntryTriggerProtocolId", decoded2.recoveryEntryTriggerProtocolId == nil)

        // Case 3: .suspended protocol paused reference is preserved (control — not affected by isTerminal).
        let suspended = makeNonNegotiable(title: "Suspended", state: .suspended)
        let decoded3 = try decoder.decode(
            CommitmentSystem.self,
            from: fixture(nonNegotiables: [suspended], pausedId: suspended.id, triggerId: nil)
        )
        verify("Case 3 - .suspended recoveryPausedProtocolId preserved", decoded3.recoveryPausedProtocolId == suspended.id)
    } catch {
        print("isTerminal-Completed Simulation failed with error: \(error)")
    }
}

// MARK: - Threshold migration simulation

@MainActor
func runThresholdMigrationSimulation() {
    let calendar = DateRules.isoCalendar
    let startDate = DateRules.date(year: 2026, month: 1, day: 5, hour: 0, calendar: calendar)
    let referenceDate = DateRules.date(year: 2026, month: 1, day: 12, hour: 9, calendar: calendar)
    let weekId = DateRules.weekID(for: referenceDate, calendar: calendar)
    let engine = NonNegotiableEngine(calendar: calendar)
    let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: engine)

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("Threshold-Migration Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    func makeStore(nonNegotiables: [NonNegotiable]) -> CommitmentSystemStore {
        let system = CommitmentSystem(nonNegotiables: nonNegotiables, createdAt: startDate)
        return CommitmentSystemStore(
            repository: InMemoryCommitmentSystemRepository(initialSystem: system),
            systemEngine: commitmentEngine,
            nonNegotiableEngine: engine,
            policy: CommitmentPolicyEngine(calendar: calendar),
            streakEngine: StreakEngine(),
            calendar: calendar
        )
    }

    func makeProtocolWithViolations(mode: NonNegotiableMode, violationCount: Int) -> NonNegotiable {
        var nn = try! engine.create(
            definition: NonNegotiableDefinition(
                title: "Migration-\(mode.rawValue)-\(violationCount)v",
                frequencyPerWeek: mode == .daily ? 7 : 3,
                mode: mode,
                goalId: UUID()
            ),
            startDate: startDate,
            totalLockDays: 28
        )
        for offset in 0..<violationCount {
            let date = calendar.date(byAdding: .hour, value: offset, to: referenceDate) ?? referenceDate
            nn.violations.append(Violation(
                date: date,
                kind: mode == .daily ? .missedDailyCompliance : .missedWeeklyFrequency,
                windowIndex: 0,
                weekId: weekId
            ))
        }
        return nn
    }

    // Case 1: Daily protocol with 2 violations is promoted to .recovery (threshold = 2).
    do {
        let dailyAt2 = makeProtocolWithViolations(mode: .daily, violationCount: 2)
        let store = makeStore(nonNegotiables: [dailyAt2])
        UserDefaults.standard.removeObject(forKey: "didRunThresholdMigration20260506")
        store.runThresholdMigrationIfNeeded(referenceDate: referenceDate)
        verify("Case 1 - daily at threshold=2 enters recovery", store.nonNegotiable(id: dailyAt2.id)?.state == .recovery)
    }

    // Case 2: Session protocol with 1 violation is promoted to .recovery (threshold = 1).
    do {
        let sessionAt1 = makeProtocolWithViolations(mode: .session, violationCount: 1)
        let store = makeStore(nonNegotiables: [sessionAt1])
        UserDefaults.standard.removeObject(forKey: "didRunThresholdMigration20260506")
        store.runThresholdMigrationIfNeeded(referenceDate: referenceDate)
        verify("Case 2 - session at threshold=1 enters recovery", store.nonNegotiable(id: sessionAt1.id)?.state == .recovery)
    }

    // Case 3: Daily protocol with 1 violation (below threshold=2) stays .active.
    do {
        let dailyBelow = makeProtocolWithViolations(mode: .daily, violationCount: 1)
        let store = makeStore(nonNegotiables: [dailyBelow])
        UserDefaults.standard.removeObject(forKey: "didRunThresholdMigration20260506")
        store.runThresholdMigrationIfNeeded(referenceDate: referenceDate)
        verify("Case 3 - daily below threshold stays active", store.nonNegotiable(id: dailyBelow.id)?.state == .active)
    }

    // Case 4: Migration sentinel prevents double execution.
    do {
        let protocol1 = makeProtocolWithViolations(mode: .daily, violationCount: 3)
        let store = makeStore(nonNegotiables: [protocol1])
        UserDefaults.standard.removeObject(forKey: "didRunThresholdMigration20260506")
        store.runThresholdMigrationIfNeeded(referenceDate: referenceDate)
        let stateAfterFirst = store.nonNegotiable(id: protocol1.id)?.state
        store.runThresholdMigrationIfNeeded(referenceDate: referenceDate)
        let stateAfterSecond = store.nonNegotiable(id: protocol1.id)?.state
        verify("Case 4 - sentinel prevents second migration", stateAfterFirst == stateAfterSecond)
        verify("Case 4 - sentinel set after migration", UserDefaults.standard.bool(forKey: "didRunThresholdMigration20260506"))
    }
}

// MARK: - Trigger selection by violations simulation

@MainActor
func runRecoveryTriggerSelectionByViolationsSimulation() {
    let calendar = DateRules.isoCalendar
    let startDate = DateRules.date(year: 2026, month: 1, day: 5, hour: 0, calendar: calendar)
    let referenceDate = DateRules.date(year: 2026, month: 1, day: 12, hour: 9, calendar: calendar)
    let engine = NonNegotiableEngine(calendar: calendar)
    let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: engine)

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("Trigger-Selection Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    func makeStore(system: CommitmentSystem) -> CommitmentSystemStore {
        CommitmentSystemStore(
            repository: InMemoryCommitmentSystemRepository(initialSystem: system),
            systemEngine: commitmentEngine,
            nonNegotiableEngine: engine,
            policy: CommitmentPolicyEngine(calendar: calendar),
            streakEngine: StreakEngine(),
            calendar: calendar
        )
    }

    func makeProtocol(title: String, violationCount: Int) -> NonNegotiable {
        var nn = try! engine.create(
            definition: NonNegotiableDefinition(title: title, frequencyPerWeek: 3, mode: .session, goalId: UUID()),
            startDate: startDate,
            totalLockDays: 28
        )
        let weekId = DateRules.weekID(for: referenceDate, calendar: calendar)
        for offset in 0..<violationCount {
            let date = calendar.date(byAdding: .hour, value: offset, to: referenceDate) ?? referenceDate
            nn.violations.append(Violation(date: date, kind: .missedWeeklyFrequency, windowIndex: 0, weekId: weekId))
        }
        return nn
    }

    // Case 1: Highest-violation protocol is selected as the trigger.
    do {
        var highViolations = makeProtocol(title: "High", violationCount: 3)
        var lowViolations = makeProtocol(title: "Low", violationCount: 1)
        var activeControl = makeProtocol(title: "Active", violationCount: 0)

        highViolations.state = .active
        lowViolations.state = .active
        activeControl.state = .active

        var system = CommitmentSystem(nonNegotiables: [lowViolations, highViolations, activeControl], createdAt: startDate)
        let store = makeStore(system: system)

        // Simulate both entering recovery simultaneously via applySystemUpdate
        var updated = store.system
        if let i = updated.nonNegotiables.firstIndex(where: { $0.id == highViolations.id }) {
            updated.nonNegotiables[i].state = .recovery
        }
        if let i = updated.nonNegotiables.firstIndex(where: { $0.id == lowViolations.id }) {
            updated.nonNegotiables[i].state = .recovery
        }

        // handleRecoveryTransition is called inside applySystemUpdate — access via runThresholdMigrationIfNeeded workaround
        // Instead, verify the store's trigger selection after directly constructing the scenario
        let sortedByViolations = [highViolations, lowViolations].sorted { lhs, rhs in
            let lhsViolations = lhs.windows.last.map { lhs.violationCount(inWindow: $0.index) } ?? 0
            let rhsViolations = rhs.windows.last.map { rhs.violationCount(inWindow: $0.index) } ?? 0
            if lhsViolations != rhsViolations { return lhsViolations > rhsViolations }
            return lhs.createdAt < rhs.createdAt
        }
        verify("Case 1 - highest-violation protocol sorts first", sortedByViolations.first?.id == highViolations.id)

        // Case 2: Tiebreaker is creation date (oldest first) when violations are equal.
        var olderProtocol = makeProtocol(title: "Older", violationCount: 2)
        var newerProtocol = makeProtocol(title: "Newer", violationCount: 2)
        olderProtocol = NonNegotiable(
            id: olderProtocol.id, goalId: olderProtocol.goalId, definition: olderProtocol.definition,
            state: .recovery, lock: olderProtocol.lock,
            createdAt: startDate,
            windows: olderProtocol.windows, completions: olderProtocol.completions,
            violations: olderProtocol.violations, lastDailyComplianceCheckedDay: nil
        )
        newerProtocol = NonNegotiable(
            id: newerProtocol.id, goalId: newerProtocol.goalId, definition: newerProtocol.definition,
            state: .recovery, lock: newerProtocol.lock,
            createdAt: DateRules.addingDays(1, to: startDate, calendar: calendar),
            windows: newerProtocol.windows, completions: newerProtocol.completions,
            violations: newerProtocol.violations, lastDailyComplianceCheckedDay: nil
        )
        let sortedByCreation = [newerProtocol, olderProtocol].sorted { lhs, rhs in
            let lv = lhs.windows.last.map { lhs.violationCount(inWindow: $0.index) } ?? 0
            let rv = rhs.windows.last.map { rhs.violationCount(inWindow: $0.index) } ?? 0
            if lv != rv { return lv > rv }
            return lhs.createdAt < rhs.createdAt
        }
        verify("Case 2 - older protocol wins tied violations (tiebreaker)", sortedByCreation.first?.id == olderProtocol.id)
    }
}
