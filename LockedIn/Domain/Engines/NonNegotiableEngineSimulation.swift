import Foundation

func runNonNegotiableEngineSimulation() {
    var calendar = Calendar(identifier: .iso8601)
    calendar.timeZone = .current

    let mondayStart = DateRules.date(year: 2026, month: 1, day: 5, hour: 0, calendar: calendar)
    let engine = NonNegotiableEngine(calendar: calendar)
    let streakEngine = StreakEngine(calendar: calendar)

    do {
        let sessionDefinition = NonNegotiableDefinition(
            title: "Gym",
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )

        var sessionNN = try engine.create(definition: sessionDefinition, startDate: mondayStart, totalLockDays: 28)

        try engine.recordCompletion(&sessionNN, at: DateRules.date(year: 2026, month: 1, day: 5, hour: 8, calendar: calendar))
        do {
            try engine.recordCompletion(&sessionNN, at: DateRules.date(year: 2026, month: 1, day: 5, hour: 20, calendar: calendar))
            print("Duplicate-day completion accepted (unexpected)")
        } catch NonNegotiableEngineError.alreadyCompletedToday {
            print("Duplicate-day completion blocked with alreadyCompletedToday (expected)")
        } catch {
            print("Duplicate-day completion failed with unexpected error: \(error)")
        }
        try engine.recordCompletion(&sessionNN, at: DateRules.date(year: 2026, month: 1, day: 6, hour: 8, calendar: calendar))
        try engine.recordCompletion(&sessionNN, at: DateRules.date(year: 2026, month: 1, day: 7, hour: 8, calendar: calendar))

        engine.evaluateWeekIfNeeded(&sessionNN, weekEnding: DateRules.date(year: 2026, month: 1, day: 11, hour: 23, minute: 59, calendar: calendar))
        print("Session Week 1 violations: \(sessionNN.windows[0].weeklyViolationCount) (expected 0)")

        // Week 2 intentionally under-completed for weekly violation.
        try engine.recordCompletion(&sessionNN, at: DateRules.date(year: 2026, month: 1, day: 12, hour: 8, calendar: calendar))
        try engine.recordCompletion(&sessionNN, at: DateRules.date(year: 2026, month: 1, day: 13, hour: 8, calendar: calendar))
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
        try engine.recordCompletion(&dailyNN, at: DateRules.date(year: 2026, month: 1, day: 5, hour: 21, calendar: calendar))
        engine.evaluateDailyComplianceIfNeeded(&dailyNN, at: DateRules.date(year: 2026, month: 1, day: 7, hour: 8, calendar: calendar))
        let firstDailyViolations = dailyNN.violations.filter { $0.kind == .missedDailyCompliance }.count
        print("Daily violations after first check: \(firstDailyViolations) (expected 1)")

        // Idempotency: re-running for same reference day should not duplicate violation.
        engine.evaluateDailyComplianceIfNeeded(&dailyNN, at: DateRules.date(year: 2026, month: 1, day: 7, hour: 12, calendar: calendar))
        let secondDailyViolations = dailyNN.violations.filter { $0.kind == .missedDailyCompliance }.count
        print("Daily violations after second check: \(secondDailyViolations) (expected 1)")

        let streakCompletions = [
            CompletionRecord(date: DateRules.date(year: 2026, month: 1, day: 10, hour: 7, calendar: calendar), weekId: DateRules.weekID(for: DateRules.date(year: 2026, month: 1, day: 10, hour: 7, calendar: calendar), calendar: calendar)),
            CompletionRecord(date: DateRules.date(year: 2026, month: 1, day: 11, hour: 7, calendar: calendar), weekId: DateRules.weekID(for: DateRules.date(year: 2026, month: 1, day: 11, hour: 7, calendar: calendar), calendar: calendar)),
            CompletionRecord(date: DateRules.date(year: 2026, month: 1, day: 12, hour: 7, calendar: calendar), weekId: DateRules.weekID(for: DateRules.date(year: 2026, month: 1, day: 12, hour: 7, calendar: calendar), calendar: calendar))
        ]
        let streak = streakEngine.currentStreakDays(
            from: streakCompletions,
            referenceDate: DateRules.date(year: 2026, month: 1, day: 12, hour: 21, calendar: calendar)
        )
        print("Current streak days: \(streak) (expected 3)")

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
