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
                try nonNegotiableEngine.recordCompletion(&nnA, at: DateRules.date(
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
                try nonNegotiableEngine.recordCompletion(&nnB, at: DateRules.date(
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
