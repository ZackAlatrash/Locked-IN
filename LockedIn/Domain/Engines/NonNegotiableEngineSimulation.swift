import Foundation

func runNonNegotiableEngineSimulation() {
    var calendar = Calendar(identifier: .iso8601)
    calendar.timeZone = .current

    let mondayStart = DateRules.date(year: 2026, month: 1, day: 5, hour: 0, calendar: calendar)
    let engine = NonNegotiableEngine(calendar: calendar)
    let streakEngine = StreakEngine(calendar: calendar)
    let commitmentEngine = CommitmentSystemEngine(nonNegotiableEngine: engine)

    @discardableResult
    func verify(_ label: String, _ condition: @autoclosure () -> Bool) -> Bool {
        let passed = condition()
        print("NonNegotiable Simulation - \(label): \(passed ? "PASS" : "FAIL")")
        return passed
    }

    do {
        let sessionDefinition = NonNegotiableDefinition(
            title: "Gym",
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )

        var sessionNN = try engine.create(definition: sessionDefinition, startDate: mondayStart, totalLockDays: 28)

        let firstSession = try engine.recordCompletion(
            &sessionNN,
            at: DateRules.date(year: 2026, month: 1, day: 5, hour: 8, calendar: calendar)
        )
        do {
            _ = try engine.recordCompletion(
                &sessionNN,
                at: DateRules.date(year: 2026, month: 1, day: 5, hour: 20, calendar: calendar)
            )
            print("Session duplicate same-day before weekly cap unexpectedly succeeded")
        } catch NonNegotiableEngineError.alreadyCompletedToday {
            print("Session duplicate same-day before weekly cap blocked: true (expected true)")
        } catch {
            print("Session duplicate same-day before weekly cap blocked with unexpected error: \(error)")
        }
        _ = try engine.recordCompletion(&sessionNN, at: DateRules.date(year: 2026, month: 1, day: 6, hour: 8, calendar: calendar))
        _ = try engine.recordCompletion(&sessionNN, at: DateRules.date(year: 2026, month: 1, day: 7, hour: 8, calendar: calendar))
        let overCapSession = try engine.recordCompletion(
            &sessionNN,
            at: DateRules.date(year: 2026, month: 1, day: 8, hour: 8, calendar: calendar)
        )
        do {
            _ = try engine.recordCompletion(
                &sessionNN,
                at: DateRules.date(year: 2026, month: 1, day: 8, hour: 21, calendar: calendar)
            )
            print("Session second extra same-day unexpectedly succeeded")
        } catch NonNegotiableEngineError.extraAlreadyLoggedToday {
            print("Session second extra same-day blocked: true (expected true)")
        } catch {
            print("Session second extra same-day blocked with unexpected error: \(error)")
        }
        print("Session first completion kind: \(firstSession.kind.rawValue) (expected counted)")
        print("Session over-cap kind: \(overCapSession.kind.rawValue) (expected extra)")

        engine.evaluateWeekIfNeeded(&sessionNN, weekEnding: DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar))
        print("Session Week 1 violations: \(sessionNN.windows[0].weeklyViolationCount) (expected 0)")

        // Week 2 intentionally under-completed for weekly violation.
        _ = try engine.recordCompletion(&sessionNN, at: DateRules.date(year: 2026, month: 1, day: 12, hour: 8, calendar: calendar))
        _ = try engine.recordCompletion(&sessionNN, at: DateRules.date(year: 2026, month: 1, day: 13, hour: 8, calendar: calendar))
        engine.evaluateWeekIfNeeded(&sessionNN, weekEnding: DateRules.date(year: 2026, month: 1, day: 18, hour: 23, minute: 59, calendar: calendar))
        print("Session Week 2 violations: \(sessionNN.violations.filter { $0.kind == .missedWeeklyFrequency }.count) (expected 1)")

        let dailyDefinition = NonNegotiableDefinition(
            title: "Sleep Protocol",
            frequencyPerWeek: 2,
            mode: .daily,
            goalId: UUID()
        )
        var dailyNN = try engine.create(definition: dailyDefinition, startDate: mondayStart, totalLockDays: 28)
        print("Daily mode normalized frequency: \(dailyNN.definition.frequencyPerWeek) (expected 7)")

        // Complete Jan 5, skip Jan 6; check on Jan 7 should add exactly one daily violation.
        let dailyFirst = try engine.recordCompletion(
            &dailyNN,
            at: DateRules.date(year: 2026, month: 1, day: 5, hour: 21, calendar: calendar)
        )
        do {
            _ = try engine.recordCompletion(
                &dailyNN,
                at: DateRules.date(year: 2026, month: 1, day: 5, hour: 22, calendar: calendar)
            )
            print("Daily second same-day before weekly cap unexpectedly succeeded")
        } catch NonNegotiableEngineError.alreadyCompletedToday {
            print("Daily second same-day before weekly cap blocked: true (expected true)")
        } catch {
            print("Daily second same-day before weekly cap blocked with unexpected error: \(error)")
        }
        print("Daily first completion kind: \(dailyFirst.kind.rawValue) (expected counted)")
        engine.evaluateDailyComplianceIfNeeded(&dailyNN, at: DateRules.date(year: 2026, month: 1, day: 7, hour: 8, calendar: calendar))
        let firstDailyViolations = dailyNN.violations.filter { $0.kind == .missedDailyCompliance }.count
        print("Daily violations after first check: \(firstDailyViolations) (expected 1)")

        // Idempotency: re-running for same reference day should not duplicate violation.
        engine.evaluateDailyComplianceIfNeeded(&dailyNN, at: DateRules.date(year: 2026, month: 1, day: 7, hour: 12, calendar: calendar))
        let secondDailyViolations = dailyNN.violations.filter { $0.kind == .missedDailyCompliance }.count
        print("Daily violations after second check: \(secondDailyViolations) (expected 1)")

        let streakCompletions = [
            CompletionRecord(
                date: DateRules.date(year: 2026, month: 1, day: 10, hour: 7, calendar: calendar),
                weekId: DateRules.weekID(for: DateRules.date(year: 2026, month: 1, day: 10, hour: 7, calendar: calendar), calendar: calendar),
                kind: .counted
            ),
            CompletionRecord(
                date: DateRules.date(year: 2026, month: 1, day: 11, hour: 7, calendar: calendar),
                weekId: DateRules.weekID(for: DateRules.date(year: 2026, month: 1, day: 11, hour: 7, calendar: calendar), calendar: calendar),
                kind: .counted
            ),
            CompletionRecord(
                date: DateRules.date(year: 2026, month: 1, day: 12, hour: 7, calendar: calendar),
                weekId: DateRules.weekID(for: DateRules.date(year: 2026, month: 1, day: 12, hour: 7, calendar: calendar), calendar: calendar),
                kind: .extra
            )
        ]
        let streak = streakEngine.currentStreakDays(
            from: streakCompletions,
            referenceDate: DateRules.date(year: 2026, month: 1, day: 12, hour: 21, calendar: calendar)
        )
        print("Current streak days with extra-only day: \(streak) (expected 0)")

        // Recovery trigger formalization checks.
        let dailyRecoveryDefinition = NonNegotiableDefinition(
            title: "Daily Recovery",
            frequencyPerWeek: 7,
            mode: .daily,
            goalId: UUID()
        )
        var dailyRecoveryNN = try engine.create(
            definition: dailyRecoveryDefinition,
            startDate: mondayStart,
            totalLockDays: 28
        )
        engine.evaluateDailyComplianceIfNeeded(
            &dailyRecoveryNN,
            at: DateRules.date(year: 2026, month: 1, day: 8, hour: 8, calendar: calendar)
        )
        print("Daily recovery state: \(dailyRecoveryNN.state.rawValue) (expected recovery at 3)")

        let sessionRecoveryDefinition = NonNegotiableDefinition(
            title: "Session Recovery",
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )
        var sessionRecoveryNN = try engine.create(
            definition: sessionRecoveryDefinition,
            startDate: mondayStart,
            totalLockDays: 28
        )
        engine.evaluateWeekIfNeeded(
            &sessionRecoveryNN,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar)
        )
        engine.evaluateWeekIfNeeded(
            &sessionRecoveryNN,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 18, hour: 23, minute: 59, calendar: calendar)
        )
        print("Session recovery state: \(sessionRecoveryNN.state.rawValue) (expected recovery at 2)")

        let sessionBelowThresholdDefinition = NonNegotiableDefinition(
            title: "Session Below Threshold",
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )
        var sessionBelowThresholdNN = try engine.create(
            definition: sessionBelowThresholdDefinition,
            startDate: mondayStart,
            totalLockDays: 28
        )
        engine.evaluateWeekIfNeeded(
            &sessionBelowThresholdNN,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar)
        )
        print("Session below threshold state: \(sessionBelowThresholdNN.state.rawValue) (expected active at 1)")

        // Old-window isolation: one violation in window 0 and one in window 1 should not trigger recovery.
        let oldWindowDefinition = NonNegotiableDefinition(
            title: "Old Window Isolation",
            frequencyPerWeek: 1,
            mode: .session,
            goalId: UUID()
        )
        var oldWindowNN = try engine.create(
            definition: oldWindowDefinition,
            startDate: mondayStart,
            totalLockDays: 28
        )
        // Week 1 miss -> violation in first window.
        engine.evaluateWeekIfNeeded(
            &oldWindowNN,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar)
        )
        // Week 2 satisfied to avoid second violation in first window.
        _ = try engine.recordCompletion(
            &oldWindowNN,
            at: DateRules.date(year: 2026, month: 1, day: 12, hour: 9, calendar: calendar)
        )
        engine.evaluateWeekIfNeeded(
            &oldWindowNN,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 18, hour: 23, minute: 59, calendar: calendar)
        )
        // Week 3 miss -> violation in second window.
        engine.evaluateWeekIfNeeded(
            &oldWindowNN,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 25, hour: 23, minute: 59, calendar: calendar)
        )
        print("Old-window-only violations recovery: \(oldWindowNN.state == .recovery) (expected false)")

        let recoveryStateBefore = sessionRecoveryNN.state
        let recoveryViolationCountBefore = sessionRecoveryNN.violations.count
        engine.evaluateWeekIfNeeded(
            &sessionRecoveryNN,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 18, hour: 23, minute: 59, calendar: calendar)
        )
        let recoveryStateAfter = sessionRecoveryNN.state
        let recoveryViolationCountAfter = sessionRecoveryNN.violations.count
        let idempotentRecovery = recoveryStateBefore == .recovery
            && recoveryStateAfter == .recovery
            && recoveryViolationCountBefore == recoveryViolationCountAfter
        print("Idempotent recovery transition: \(idempotentRecovery) (expected true)")

        // Recovery should not be overwritten to completed at lock end.
        var lockEndRecoveryNN = try engine.create(
            definition: sessionRecoveryDefinition,
            startDate: mondayStart,
            totalLockDays: 14
        )
        engine.evaluateWeekIfNeeded(
            &lockEndRecoveryNN,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar)
        )
        engine.evaluateWeekIfNeeded(
            &lockEndRecoveryNN,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 18, hour: 23, minute: 59, calendar: calendar)
        )
        engine.advanceWindowIfNeeded(
            &lockEndRecoveryNN,
            currentDate: DateRules.date(year: 2026, month: 1, day: 19, hour: 0, minute: 0, calendar: calendar)
        )
        print("Recovery persists at lock end: \(lockEndRecoveryNN.state == .recovery) (expected true)")

        // Initial grace window checks.
        let graceDefinition = NonNegotiableDefinition(
            title: "Grace Weekly",
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )

        // Case 1: Created on last day of week with no completion -> grace suppression applies.
        var case1 = try engine.create(
            definition: graceDefinition,
            startDate: DateRules.date(year: 2026, month: 1, day: 11, hour: 10, calendar: calendar),
            totalLockDays: 28
        )
        let case1WeekEnd = DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar)
        engine.evaluateWeekIfNeeded(&case1, weekEnding: case1WeekEnd)
        let case1WeekId = DateRules.weekID(for: case1WeekEnd, calendar: calendar)
        verify(
            "Grace Case 1 - no initial partial-week shortfall",
            case1.violations.contains(where: { $0.kind == .missedWeeklyFrequency }) == false
        )
        verify(
            "Grace Case 1 - grace week recorded",
            case1.windows[0].weeksEvaluated.contains(case1WeekId)
        )

        // Case 2: Created mid-week with some completions -> completions count and shortfall suppressed.
        var case2 = try engine.create(
            definition: graceDefinition,
            startDate: DateRules.date(year: 2026, month: 1, day: 7, hour: 11, calendar: calendar),
            totalLockDays: 28
        )
        let case2CompletionDate = DateRules.date(year: 2026, month: 1, day: 8, hour: 9, calendar: calendar)
        _ = try engine.recordCompletion(&case2, at: case2CompletionDate)
        let case2WeekEnd = DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar)
        engine.evaluateWeekIfNeeded(&case2, weekEnding: case2WeekEnd)
        let case2WeekId = DateRules.weekID(for: case2WeekEnd, calendar: calendar)
        let case2CountedInGraceWeek = case2.completions.filter { completion in
            completion.kind == .counted && completion.weekId == case2WeekId
        }.count
        verify(
            "Grace Case 2 - completions still counted",
            case2CountedInGraceWeek == 1
        )
        verify(
            "Grace Case 2 - no initial partial-week shortfall",
            case2.violations.contains(where: { $0.kind == .missedWeeklyFrequency }) == false
        )

        // Case 3: Created at canonical week start -> normal enforcement applies.
        var case3 = try engine.create(
            definition: graceDefinition,
            startDate: DateRules.date(year: 2026, month: 1, day: 12, hour: 0, calendar: calendar),
            totalLockDays: 28
        )
        engine.evaluateWeekIfNeeded(
            &case3,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 18, hour: 23, minute: 59, calendar: calendar)
        )
        verify(
            "Grace Case 3 - boundary-start week enforces shortfall",
            case3.violations.filter { $0.kind == .missedWeeklyFrequency }.count == 1
        )

        // Case 4: Retired before first full week -> no weekly shortfall violations.
        var case4 = try engine.create(
            definition: graceDefinition,
            startDate: DateRules.date(year: 2026, month: 1, day: 7, hour: 10, calendar: calendar),
            totalLockDays: 28
        )
        case4.state = .retired
        engine.evaluateWeekIfNeeded(
            &case4,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar)
        )
        engine.evaluateWeekIfNeeded(
            &case4,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 18, hour: 23, minute: 59, calendar: calendar)
        )
        verify(
            "Grace Case 4 - retired protocol emits no shortfall",
            case4.violations.contains(where: { $0.kind == .missedWeeklyFrequency }) == false
        )

        // Case 5: Older weekly protocol behavior unchanged.
        var case5 = try engine.create(
            definition: graceDefinition,
            startDate: DateRules.date(year: 2026, month: 1, day: 5, hour: 0, calendar: calendar),
            totalLockDays: 28
        )
        engine.evaluateWeekIfNeeded(
            &case5,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar)
        )
        engine.evaluateWeekIfNeeded(
            &case5,
            weekEnding: DateRules.date(year: 2026, month: 1, day: 18, hour: 23, minute: 59, calendar: calendar)
        )
        verify(
            "Grace Case 5 - older protocol still gets weekly shortfalls",
            case5.violations.filter { $0.kind == .missedWeeklyFrequency }.count == 2
        )

        // Case 6: Catch-up evaluation does not backfill the grace-suppressed week later.
        let case6Protocol = try engine.create(
            definition: graceDefinition,
            startDate: DateRules.date(year: 2026, month: 1, day: 7, hour: 13, calendar: calendar),
            totalLockDays: 28
        )
        var case6System = CommitmentSystem(
            nonNegotiables: [case6Protocol],
            createdAt: DateRules.date(year: 2026, month: 1, day: 7, hour: 13, calendar: calendar)
        )
        commitmentEngine.evaluateWeekCatchUp(
            referenceDate: DateRules.date(year: 2026, month: 1, day: 20, hour: 9, calendar: calendar),
            in: &case6System,
            calendar: calendar
        )
        let case6Evaluated = case6System.nonNegotiables[0]
        let case6MissedWeeklyCount = case6Evaluated.violations.filter { $0.kind == .missedWeeklyFrequency }.count
        let graceWeekId = DateRules.weekID(
            for: DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar),
            calendar: calendar
        )
        let firstFullWeekId = DateRules.weekID(
            for: DateRules.date(year: 2026, month: 1, day: 18, hour: 23, minute: 59, calendar: calendar),
            calendar: calendar
        )
        verify(
            "Grace Case 6 - catch-up records grace week as evaluated",
            case6Evaluated.windows[0].weeksEvaluated.contains(graceWeekId)
        )
        verify(
            "Grace Case 6 - catch-up evaluates first full week",
            case6Evaluated.windows[0].weeksEvaluated.contains(firstFullWeekId)
        )
        verify(
            "Grace Case 6 - catch-up emits only post-grace shortfall",
            case6MissedWeeklyCount == 1
        )

        let legacyJSON = """
        {
          "title":"Legacy NN",
          "minimumMinutes":45,
          "frequencyPerWeek":3,
          "timeWindowStartHour":18,
          "timeWindowEndHour":22,
          "goalId":"A6B8F6E8-8DA8-4DE0-B712-13BF8A4C6611"
        }
        """
        let decodedLegacy = try JSONDecoder().decode(
            NonNegotiableDefinition.self,
            from: Data(legacyJSON.utf8)
        )
        print("Legacy decode mode: \(decodedLegacy.mode.rawValue) (expected session)")
    } catch {
        print("Simulation failed with error: \(error)")
    }
}
