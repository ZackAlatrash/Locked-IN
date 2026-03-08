import Foundation

func runCommitmentPolicyEngineSimulation() {
    let calendar = DateRules.isoCalendar
    let policy = CommitmentPolicyEngine(calendar: calendar)
    let engine = NonNegotiableEngine(calendar: calendar)

    let start = DateRules.date(year: 2026, month: 3, day: 2, hour: 8, calendar: calendar)
    let nowDuringLock = DateRules.date(year: 2026, month: 3, day: 5, hour: 9, calendar: calendar)
    let dayAfterLock = DateRules.date(year: 2026, month: 4, day: 5, hour: 9, calendar: calendar)

    do {
        let definition = NonNegotiableDefinition(
            title: "Deep Work",
            frequencyPerWeek: 4,
            mode: .session,
            goalId: UUID()
        )
        let nn = try engine.create(definition: definition, startDate: start, totalLockDays: 28)

        let allowedDuringLock = policy.allowedEditableFields(for: nn, at: nowDuringLock)
        print("edit-lock allow title/icon/preferred/duration: \(allowedDuringLock.contains(.title) && allowedDuringLock.contains(.icon) && allowedDuringLock.contains(.preferredTime) && allowedDuringLock.contains(.estimatedDuration)) (expected true)")
        print("edit-lock deny mode/frequency/lockDuration: \(!allowedDuringLock.contains(.mode) && !allowedDuringLock.contains(.frequency) && !allowedDuringLock.contains(.lockDuration)) (expected true)")

        let lockedEdit = policy.canEdit(
            nn: nn,
            patch: NonNegotiablePatch(
                newTitle: nil,
                newIconName: nil,
                newPreferredTime: nil,
                newEstimatedDurationMinutes: nil,
                newMode: .daily,
                newFrequencyPerWeek: nil,
                newLockDays: nil
            ),
            at: nowDuringLock
        )
        let lockedEditDenied: Bool
        if case .cannotEditFieldDuringLock(field: .mode, _, _) = lockedEdit.reason {
            lockedEditDenied = true
        } else {
            lockedEditDenied = false
        }
        print("edit-lock mode change denied: \(lockedEditDenied) (expected true)")

        let unlockedEdit = policy.canEdit(
            nn: nn,
            patch: NonNegotiablePatch(
                newTitle: nil,
                newIconName: nil,
                newPreferredTime: nil,
                newEstimatedDurationMinutes: nil,
                newMode: .daily,
                newFrequencyPerWeek: nil,
                newLockDays: nil
            ),
            at: dayAfterLock
        )
        print("edit-post-lock mode change allowed: \(unlockedEdit.allowed) (expected true)")

        let retireLocked = policy.canRetire(nn: nn, at: nowDuringLock)
        print("retire during lock denied: \(retireLocked.allowed == false) (expected true)")

        let activeSystem = CommitmentSystem(nonNegotiables: [nn], createdAt: start)
        let removeActive = policy.canRemove(nn: nn)
        print("remove active denied: \(removeActive.allowed == false) (expected true)")

        var recoveryNN = nn
        recoveryNN.state = .recovery
        let recoverySystem = CommitmentSystem(nonNegotiables: [recoveryNN], createdAt: start, recoveryCleanDayStreak: 2)
        let createDecision = policy.canCreate(definition: definition, in: recoverySystem, at: nowDuringLock)
        print("create during recovery denied: \(createDecision.reason?.copy().title == "Recovery Active") (expected true)")

        let placePast = policy.canPlaceAllocation(
            nn: nn,
            day: DateRules.date(year: 2026, month: 3, day: 1, hour: 10, calendar: calendar),
            requiredMinutes: 60,
            availableMinutes: 120,
            at: nowDuringLock,
            alreadyScheduledThatDay: false,
            context: .manual
        )
        print("plan in past denied: \(placePast.reason == .cannotPlanIntoPast) (expected true)")

        let dailyDef = NonNegotiableDefinition(
            title: "Hydration",
            frequencyPerWeek: 7,
            mode: .daily,
            goalId: UUID()
        )
        let dailyNN = try engine.create(definition: dailyDef, startDate: start, totalLockDays: 28)
        let farDay = DateRules.addingDays(3, to: DateRules.startOfDay(nowDuringLock, calendar: calendar), calendar: calendar)
        let dailyLimit = policy.canPlaceAllocation(
            nn: dailyNN,
            day: farDay,
            requiredMinutes: 15,
            availableMinutes: 200,
            at: nowDuringLock,
            alreadyScheduledThatDay: false,
            context: .manual
        )
        print("daily manual week planning allowed: \(dailyLimit.allowed) (expected true)")

        _ = activeSystem
    } catch {
        print("CommitmentPolicyEngineSimulation failed: \(error)")
    }
}
