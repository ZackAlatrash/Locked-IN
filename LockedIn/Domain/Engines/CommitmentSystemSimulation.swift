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

    // Case 1: Paused protocol retires during recovery.
    do {
        let recovering = makeNonNegotiable(title: "Recovering", state: .recovery, createdAtOffset: 0, engine: engine)
        let active = makeNonNegotiable(title: "Active", state: .active, createdAtOffset: 1, engine: engine)
        let paused = makeNonNegotiable(title: "Paused", state: .suspended, createdAtOffset: 2, engine: engine)

        var system = CommitmentSystem(nonNegotiables: [recovering, active, paused], createdAt: startDate)
        system.recoveryPausedProtocolId = paused.id
        let store = makeStore(system: system)

        try store.retireNonNegotiable(id: paused.id, referenceDate: retirementDate)

        verify("Case 1 - paused protocol retired", store.nonNegotiable(id: paused.id)?.state == .retired)
        verify("Case 1 - stale paused id cleared", store.system.recoveryPausedProtocolId == nil)
        verify("Case 1 - recovery continues when eligible set is still >= 2", store.system.nonNegotiables.contains(where: { $0.state == .recovery }))
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
        let context = store.recoveryEntryContext(referenceDate: retirementDate)

        verify("Case 1 - pending still open", context != nil)
        verify("Case 1 - retired candidate removed", context?.candidateProtocolIds.contains(activeB.id) == false)
        verify("Case 1 - selectable set refreshed", Set(context?.candidateProtocolIds ?? []) == Set([recovering.id, activeA.id]))
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

        verify("Case 2 - pending flow closed", store.recoveryEntryContext(referenceDate: retirementDate) == nil)
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
        let context = store.recoveryEntryContext(referenceDate: retirementDate)

        verify("Case 3 - pending still needs decision", context?.requiresPauseSelection == true)
        verify("Case 3 - candidate set changed and valid", Set(context?.candidateProtocolIds ?? []) == Set([recovering.id, activeB.id]))
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
        let context = store.recoveryEntryContext(referenceDate: retirementDate)

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
