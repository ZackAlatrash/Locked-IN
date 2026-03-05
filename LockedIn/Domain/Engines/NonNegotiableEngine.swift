import Foundation

/*
 MVP scope for Non-Negotiables Engine:
 - Per-NN definition validation, completion recording, weekly evaluation, and 14-day window tracking.
 - Daily compliance checks for daily mode (idempotent, one missed-day violation at most once per day).
 - Recovery trigger when a single 14-day window accumulates 3 violations.

 Intentionally not implemented in this engine:
 - Persistence, scheduling/rescheduling, reliability score, upgrades, AI integration,
   global max-active-NN enforcement, or cross-NN orchestration.
 */

enum NonNegotiableDefinitionValidationReason {
    case titleEmpty
    case frequencyOutOfRange
    case invalidDailyFrequency
    case invalidLockDuration
    case durationOutOfRange
    case iconEmpty
}

enum NonNegotiableEngineError: Error {
    case invalidDefinition(reason: NonNegotiableDefinitionValidationReason)
    case outsideLockPeriod
    case alreadyRetiredOrCompleted
    case alreadyCompletedToday
    case extraAlreadyLoggedToday
}

struct CompletionDecision: Equatable {
    let kind: CompletionKind
}

struct NonNegotiableEngine {
    private let calendar: Calendar

    init(calendar: Calendar = DateRules.isoCalendar) {
        self.calendar = calendar
    }

    func create(definition: NonNegotiableDefinition, startDate: Date, totalLockDays: Int = 14) throws -> NonNegotiable {
        try validateDefinition(definition, totalLockDays: totalLockDays)

        let normalizedStart = DateRules.startOfDay(startDate, calendar: calendar)
        let lock = LockConfiguration(startDate: normalizedStart, totalLockDays: totalLockDays)
        let firstWindowEnd = DateRules.addingDays(lock.windowLengthDays, to: normalizedStart, calendar: calendar)

        return NonNegotiable(
            id: UUID(),
            goalId: definition.goalId,
            definition: definition,
            state: .active,
            lock: lock,
            createdAt: normalizedStart,
            windows: [Window(index: 0, startDate: normalizedStart, endDate: firstWindowEnd)],
            completions: [],
            violations: [],
            lastDailyComplianceCheckedDay: nil
        )
    }

    func recordCompletion(_ nn: inout NonNegotiable, at date: Date) throws -> CompletionDecision {
        guard nn.state != .retired, nn.state != .completed else {
            throw NonNegotiableEngineError.alreadyRetiredOrCompleted
        }

        try ensureWithinLock(nn, date: date)

        let weekId = DateRules.weekID(for: date, calendar: calendar)
        let completionKind = try determineCompletionKind(nn, date: date, weekId: weekId)
        nn.completions.append(CompletionRecord(date: date, weekId: weekId, kind: completionKind))
        return CompletionDecision(kind: completionKind)
    }

    func evaluateDailyComplianceIfNeeded(_ nn: inout NonNegotiable, at currentDate: Date) {
        guard nn.state != .retired, nn.state != .completed, nn.state != .suspended else { return }
        guard nn.definition.mode == .daily else { return }

        let today = DateRules.startOfDay(currentDate, calendar: calendar)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }

        if let lastChecked = nn.lastDailyComplianceCheckedDay,
           lastChecked >= yesterday {
            return
        }

        guard yesterday >= nn.lock.startDate else {
            nn.lastDailyComplianceCheckedDay = yesterday
            return
        }

        let lockEnd = lockEndDate(for: nn)
        guard yesterday < lockEnd else {
            nn.lastDailyComplianceCheckedDay = yesterday
            return
        }

        advanceWindowIfNeeded(&nn, currentDate: currentDate)
        guard let windowIndex = windowIndex(for: nn, date: yesterday) else {
            nn.lastDailyComplianceCheckedDay = yesterday
            return
        }

        let didCompleteYesterday = nn.completions.contains { completion in
            completion.kind == .counted && calendar.isDate(completion.date, inSameDayAs: yesterday)
        }

        if !didCompleteYesterday {
            nn.windows[windowIndex].weeklyViolationCount += 1
            nn.violations.append(
                Violation(
                    date: yesterday,
                    kind: .missedDailyCompliance,
                    windowIndex: windowIndex,
                    weekId: DateRules.weekID(for: yesterday, calendar: calendar)
                )
            )
            updateRecoveryState(&nn, windowIndex: windowIndex)
        }

        nn.lastDailyComplianceCheckedDay = yesterday
    }

    func evaluateWeekIfNeeded(_ nn: inout NonNegotiable, weekEnding date: Date) {
        guard nn.state != .retired, nn.state != .completed, nn.state != .suspended else { return }

        advanceWindowIfNeeded(&nn, currentDate: date)
        guard let windowIndex = windowIndex(for: nn, date: date) else { return }

        let weekId = DateRules.weekID(for: date, calendar: calendar)
        if nn.windows[windowIndex].weeksEvaluated.contains(weekId) {
            return
        }

        let weekInterval = DateRules.weekInterval(containing: date, calendar: calendar)
        let completionCount = countCompletions(
            in: nn,
            for: weekId,
            within: weekInterval,
            windowIndex: windowIndex
        )

        let expected = expectedCompletionsPerWeek(for: nn.definition)
        if completionCount < expected {
            nn.windows[windowIndex].weeklyViolationCount += 1
            nn.violations.append(
                Violation(
                    date: date,
                    kind: .missedWeeklyFrequency,
                    windowIndex: windowIndex,
                    weekId: weekId
                )
            )
        }

        nn.windows[windowIndex].weeksEvaluated.insert(weekId)
        updateRecoveryState(&nn, windowIndex: windowIndex)
    }

    func advanceWindowIfNeeded(_ nn: inout NonNegotiable, currentDate: Date) {
        guard nn.state != .retired, nn.state != .completed else { return }

        let lockEnd = lockEndDate(for: nn)
        if currentDate >= lockEnd {
            nn.state = .completed
            return
        }

        while currentDate >= (nn.windows.last?.endDate ?? lockEnd) {
            let nextIndex = nn.windows.count
            let start = nn.windows[nextIndex - 1].endDate
            let end = DateRules.addingDays(nn.lock.windowLengthDays, to: start, calendar: calendar)
            nn.windows.append(Window(index: nextIndex, startDate: start, endDate: end))
        }
    }

    func lockEndDate(for nn: NonNegotiable) -> Date {
        DateRules.addingDays(nn.lock.totalLockDays, to: nn.lock.startDate, calendar: calendar)
    }

    func validateDefinition(_ definition: NonNegotiableDefinition, totalLockDays: Int) throws {
        try validate(definition: definition, totalLockDays: totalLockDays)
    }

    private func validate(definition: NonNegotiableDefinition, totalLockDays: Int) throws {
        if definition.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw NonNegotiableEngineError.invalidDefinition(reason: .titleEmpty)
        }
        if totalLockDays != 14 && totalLockDays != 28 {
            throw NonNegotiableEngineError.invalidDefinition(reason: .invalidLockDuration)
        }
        if NonNegotiableDefinition.isValidEstimatedDuration(definition.estimatedDurationMinutes) == false {
            throw NonNegotiableEngineError.invalidDefinition(reason: .durationOutOfRange)
        }
        if NonNegotiableDefinition.isValidIconSystemName(definition.iconSystemName) == false {
            throw NonNegotiableEngineError.invalidDefinition(reason: .iconEmpty)
        }

        let normalizedFrequency = NonNegotiableDefinition.normalizedFrequency(
            definition.frequencyPerWeek,
            mode: definition.mode
        )

        switch definition.mode {
        case .session:
            if !(1...7).contains(normalizedFrequency) {
                throw NonNegotiableEngineError.invalidDefinition(reason: .frequencyOutOfRange)
            }
        case .daily:
            if normalizedFrequency != 7 {
                throw NonNegotiableEngineError.invalidDefinition(reason: .invalidDailyFrequency)
            }
        }
    }

    private func ensureWithinLock(_ nn: NonNegotiable, date: Date) throws {
        let lockEnd = lockEndDate(for: nn)
        if date < nn.lock.startDate || date >= lockEnd {
            throw NonNegotiableEngineError.outsideLockPeriod
        }
    }

    private func expectedCompletionsPerWeek(for definition: NonNegotiableDefinition) -> Int {
        NonNegotiableDefinition.normalizedFrequency(definition.frequencyPerWeek, mode: definition.mode)
    }

    private func windowIndex(for nn: NonNegotiable, date: Date) -> Int? {
        nn.windows.lastIndex {
            date >= $0.startDate && date < $0.endDate
        }
    }

    private func countCompletions(
        in nn: NonNegotiable,
        for weekId: WeekID,
        within weekInterval: DateInterval,
        windowIndex: Int
    ) -> Int {
        let window = nn.windows[windowIndex]
        let lockEnd = lockEndDate(for: nn)

        return nn.completions.filter { record in
            record.weekId == weekId
            && record.kind == .counted
            && record.date >= weekInterval.start
            && record.date < weekInterval.end
            && record.date >= window.startDate
            && record.date < window.endDate
            && record.date >= nn.lock.startDate
            && record.date < lockEnd
        }.count
    }

    private func determineCompletionKind(_ nn: NonNegotiable, date: Date, weekId: WeekID) throws -> CompletionKind {
        let hasCountedToday = nn.completions.contains {
            $0.kind == .counted && calendar.isDate($0.date, inSameDayAs: date)
        }
        let hasExtraToday = nn.completions.contains {
            $0.kind == .extra && calendar.isDate($0.date, inSameDayAs: date)
        }
        let countedThisWeek = nn.completions.reduce(into: 0) { partial, completion in
            if completion.weekId == weekId && completion.kind == .counted {
                partial += 1
            }
        }
        let weeklyTarget = NonNegotiableDefinition.normalizedFrequency(
            nn.definition.frequencyPerWeek,
            mode: nn.definition.mode
        )

        switch nn.definition.mode {
        case .daily:
            if countedThisWeek < weeklyTarget {
                if hasCountedToday {
                    throw NonNegotiableEngineError.alreadyCompletedToday
                }
                return .counted
            }

            if hasCountedToday {
                throw NonNegotiableEngineError.alreadyCompletedToday
            }
            if hasExtraToday {
                throw NonNegotiableEngineError.extraAlreadyLoggedToday
            }
            return .extra
        case .session:
            if countedThisWeek < weeklyTarget {
                if hasCountedToday {
                    throw NonNegotiableEngineError.alreadyCompletedToday
                }
                return .counted
            }

            if hasCountedToday {
                throw NonNegotiableEngineError.alreadyCompletedToday
            }
            if hasExtraToday {
                throw NonNegotiableEngineError.extraAlreadyLoggedToday
            }
            return .extra
        }
    }

    private func updateRecoveryState(_ nn: inout NonNegotiable, windowIndex: Int) {
        if nn.windows[windowIndex].weeklyViolationCount >= 3 {
            nn.state = .recovery
        }
    }
}
