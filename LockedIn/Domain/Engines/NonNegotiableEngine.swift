import Foundation

/*
 MVP scope for Non-Negotiables Engine:
 - Per-NN definition validation, completion recording, weekly evaluation, and 14-day window tracking.
 - Daily compliance checks for daily mode (idempotent, one missed-day violation at most once per day).
 - Recovery trigger when the current 14-day window reaches mode-specific violation threshold.

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
    private static let allowedLockDurations: Set<Int> = [14, 28, 60, 90]

    private struct InitialPartialWeeklyGraceEvaluation {
        let shouldSuppressShortfall: Bool
        let creationWeekId: WeekID
    }

    private struct RecoveryUpdateDebugContext {
        let source: String
        let tickDate: Date
        let evaluatedWeekId: WeekID?
        let evaluatedDay: Date?
        let completionCount: Int?
        let expected: Int?
        let missedWeeklyAppended: Bool
        let missedDailyAppended: Bool
        let weeklyViolationCountBefore: Int
        let stateBefore: NonNegotiableState
    }

    private let calendar: Calendar
    private let graceDebugDateFormatter: ISO8601DateFormatter

    init(calendar: Calendar = DateRules.isoCalendar) {
        self.calendar = calendar
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = calendar.timeZone
        self.graceDebugDateFormatter = formatter
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

        let lockStart = DateRules.startOfDay(nn.lock.startDate, calendar: calendar)
        let lockEnd = lockEndDate(for: nn)
        guard let lastLockDay = calendar.date(byAdding: .day, value: -1, to: lockEnd) else {
            nn.lastDailyComplianceCheckedDay = yesterday
            return
        }

        let rawStart = (nn.lastDailyComplianceCheckedDay
            .flatMap { calendar.date(byAdding: .day, value: 1, to: $0) })
            ?? lockStart
        let evaluationStart = max(DateRules.startOfDay(rawStart, calendar: calendar), lockStart)
        let evaluationEnd = min(yesterday, lastLockDay)

        guard evaluationStart <= evaluationEnd else {
            nn.lastDailyComplianceCheckedDay = yesterday
            return
        }

        var dayCursor = evaluationStart
        while dayCursor <= evaluationEnd {
            advanceWindowIfNeeded(&nn, currentDate: dayCursor)
            if let windowIndex = windowIndex(for: nn, date: dayCursor) {
                if isDailyCreationGraceDay(dayCursor, for: nn) {
                    guard let next = calendar.date(byAdding: .day, value: 1, to: dayCursor) else {
                        break
                    }
                    dayCursor = next
                    continue
                }

                let didCompleteOnDay = nn.completions.contains { completion in
                    completion.kind == .counted && calendar.isDate(completion.date, inSameDayAs: dayCursor)
                }

                if !didCompleteOnDay {
                    let stateBefore = nn.state
                    let weeklyViolationCountBefore = nn.windows[windowIndex].weeklyViolationCount
                    nn.windows[windowIndex].weeklyViolationCount += 1
                    nn.violations.append(
                        Violation(
                            date: dayCursor,
                            kind: .missedDailyCompliance,
                            windowIndex: windowIndex,
                            weekId: DateRules.weekID(for: dayCursor, calendar: calendar)
                        )
                    )
                    updateRecoveryState(
                        &nn,
                        windowIndex: windowIndex,
                        debugContext: RecoveryUpdateDebugContext(
                            source: "evaluateDailyComplianceIfNeeded",
                            tickDate: currentDate,
                            evaluatedWeekId: DateRules.weekID(for: dayCursor, calendar: calendar),
                            evaluatedDay: dayCursor,
                            completionCount: didCompleteOnDay ? 1 : 0,
                            expected: expectedCompletionsPerWeek(for: nn.definition),
                            missedWeeklyAppended: false,
                            missedDailyAppended: true,
                            weeklyViolationCountBefore: weeklyViolationCountBefore,
                            stateBefore: stateBefore
                        )
                    )
                }
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: dayCursor) else {
                break
            }
            dayCursor = next
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
        let graceEvaluation = evaluateInitialPartialWeeklyGrace(
            for: nn,
            weekId: weekId,
            weekInterval: weekInterval
        )
        let shouldSuppressShortfall = graceEvaluation.shouldSuppressShortfall
        let shouldSuppressDailyCreationWeekShortfall = shouldSuppressDailyCreationWeekShortfall(
            for: nn,
            weekId: weekId
        )
        let stateBefore = nn.state
        let weeklyViolationCountBefore = nn.windows[windowIndex].weeklyViolationCount
        let shouldAppendMissedWeekly = completionCount < expected &&
            shouldSuppressShortfall == false &&
            shouldSuppressDailyCreationWeekShortfall == false

        if shouldAppendMissedWeekly {
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
        updateRecoveryState(
            &nn,
            windowIndex: windowIndex,
            debugContext: RecoveryUpdateDebugContext(
                source: "evaluateWeekIfNeeded",
                tickDate: date,
                evaluatedWeekId: weekId,
                evaluatedDay: nil,
                completionCount: completionCount,
                expected: expected,
                missedWeeklyAppended: shouldAppendMissedWeekly,
                missedDailyAppended: false,
                weeklyViolationCountBefore: weeklyViolationCountBefore,
                stateBefore: stateBefore
            )
        )

        if shouldEmitGraceWeeklyDebugLog(
            for: nn,
            evaluatedWeekId: weekId,
            creationWeekId: graceEvaluation.creationWeekId,
            missedWeeklyAppended: shouldAppendMissedWeekly
        ) {
            emitGraceWeeklyDebugLog(
                nonNegotiable: nn,
                evaluatedDate: date,
                weekId: weekId,
                weekInterval: weekInterval,
                creationWeekId: graceEvaluation.creationWeekId,
                completionCount: completionCount,
                expected: expected,
                shouldSuppressShortfall: shouldSuppressShortfall,
                missedWeeklyAppended: shouldAppendMissedWeekly,
                weeklyViolationCountBefore: weeklyViolationCountBefore,
                weeklyViolationCountAfter: nn.windows[windowIndex].weeklyViolationCount,
                stateBefore: stateBefore,
                stateAfter: nn.state
            )
        }
    }

    func advanceWindowIfNeeded(_ nn: inout NonNegotiable, currentDate: Date) {
        guard nn.state != .retired, nn.state != .completed else { return }

        let lockEnd = lockEndDate(for: nn)
        if currentDate >= lockEnd {
            // Recovery must persist once entered; auto-completion would hide recovery state.
            if nn.state != .recovery {
                nn.state = .completed
            }
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
        if Self.allowedLockDurations.contains(totalLockDays) == false {
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

    private func shouldSuppressInitialPartialWeeklyShortfall(
        for nn: NonNegotiable,
        weekId: WeekID,
        weekInterval: DateInterval
    ) -> Bool {
        evaluateInitialPartialWeeklyGrace(
            for: nn,
            weekId: weekId,
            weekInterval: weekInterval
        ).shouldSuppressShortfall
    }

    private func evaluateInitialPartialWeeklyGrace(
        for nn: NonNegotiable,
        weekId: WeekID,
        weekInterval: DateInterval
    ) -> InitialPartialWeeklyGraceEvaluation {
        let creationWeekId = DateRules.weekID(for: nn.createdAt, calendar: calendar)
        guard isQuotaWeekBased(nn.definition.mode) else {
            return InitialPartialWeeklyGraceEvaluation(
                shouldSuppressShortfall: false,
                creationWeekId: creationWeekId
            )
        }
        guard weekId == creationWeekId else {
            return InitialPartialWeeklyGraceEvaluation(
                shouldSuppressShortfall: false,
                creationWeekId: creationWeekId
            )
        }

        // Increment 3/4 uses current normalized createdAt semantics.
        return InitialPartialWeeklyGraceEvaluation(
            shouldSuppressShortfall: nn.createdAt > weekInterval.start,
            creationWeekId: creationWeekId
        )
    }

    private func isQuotaWeekBased(_ mode: NonNegotiableMode) -> Bool {
        mode == .session
    }

    private func isDailyCreationGraceDay(_ day: Date, for nn: NonNegotiable) -> Bool {
        guard nn.definition.mode == .daily else { return false }
        let creationDay = DateRules.startOfDay(nn.createdAt, calendar: calendar)
        let targetDay = DateRules.startOfDay(day, calendar: calendar)
        return creationDay == targetDay
    }

    private func shouldSuppressDailyCreationWeekShortfall(
        for nn: NonNegotiable,
        weekId: WeekID
    ) -> Bool {
        guard nn.definition.mode == .daily else { return false }
        let creationWeekId = DateRules.weekID(for: nn.createdAt, calendar: calendar)
        return creationWeekId == weekId
    }

    private func shouldEmitGraceWeeklyDebugLog(
        for nn: NonNegotiable,
        evaluatedWeekId: WeekID,
        creationWeekId: WeekID,
        missedWeeklyAppended: Bool
    ) -> Bool {
        guard nn.definition.mode == .session else { return false }
        return evaluatedWeekId == creationWeekId || missedWeeklyAppended
    }

    private func emitGraceWeeklyDebugLog(
        nonNegotiable: NonNegotiable,
        evaluatedDate: Date,
        weekId: WeekID,
        weekInterval: DateInterval,
        creationWeekId: WeekID,
        completionCount: Int,
        expected: Int,
        shouldSuppressShortfall: Bool,
        missedWeeklyAppended: Bool,
        weeklyViolationCountBefore: Int,
        weeklyViolationCountAfter: Int,
        stateBefore: NonNegotiableState,
        stateAfter: NonNegotiableState
    ) {
        let title = nonNegotiable.definition.title.replacingOccurrences(of: "\"", with: "'")
        print(
            "[GraceWeeklyDebug] " +
            "protocolId=\(nonNegotiable.id.uuidString) " +
            "title=\"\(title)\" " +
            "mode=\(nonNegotiable.definition.mode.rawValue) " +
            "createdAt=\(graceDebugDateFormatter.string(from: nonNegotiable.createdAt)) " +
            "tickDate=\(graceDebugDateFormatter.string(from: evaluatedDate)) " +
            "evaluatedWeekId=\(weekId.description) " +
            "weekStart=\(graceDebugDateFormatter.string(from: weekInterval.start)) " +
            "weekEnd=\(graceDebugDateFormatter.string(from: weekInterval.end)) " +
            "creationWeekId=\(creationWeekId.description) " +
            "completionCount=\(completionCount) " +
            "expected=\(expected) " +
            "shouldSuppressShortfall=\(shouldSuppressShortfall) " +
            "missedWeeklyAppended=\(missedWeeklyAppended) " +
            "weeklyViolationCountBefore=\(weeklyViolationCountBefore) " +
            "weeklyViolationCountAfter=\(weeklyViolationCountAfter) " +
            "stateBefore=\(stateBefore.rawValue) " +
            "stateAfter=\(stateAfter.rawValue)"
        )
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

    private func updateRecoveryState(
        _ nn: inout NonNegotiable,
        windowIndex: Int,
        debugContext: RecoveryUpdateDebugContext? = nil
    ) {
        let stateBefore = debugContext?.stateBefore ?? nn.state
        let weeklyViolationCountBefore = debugContext?.weeklyViolationCountBefore ?? nn.windows[windowIndex].weeklyViolationCount
        let threshold = recoveryViolationThreshold(for: nn.definition.mode)
        let weeklyViolationCountAfter = nn.windows[windowIndex].weeklyViolationCount
        let thresholdReached = weeklyViolationCountAfter >= threshold

        if nn.state != .recovery && thresholdReached {
            nn.state = .recovery
        }

        let stateAfter = nn.state
        let recoveryEntered = stateBefore != .recovery && stateAfter == .recovery
        let reason: String
        if recoveryEntered {
            reason = "enteredRecovery:thresholdReached"
        } else if stateBefore == .recovery {
            reason = "alreadyInRecovery"
        } else if thresholdReached == false {
            reason = "noRecovery:belowThreshold"
        } else {
            reason = "noRecovery:stateUnchanged"
        }

        if shouldEmitRecoveryTriggerDebugLog(
            for: nn,
            missedWeeklyAppended: debugContext?.missedWeeklyAppended ?? false,
            missedDailyAppended: debugContext?.missedDailyAppended ?? false,
            recoveryEntered: recoveryEntered
        ) {
            emitRecoveryTriggerDebugLog(
                nonNegotiable: nn,
                source: debugContext?.source ?? "updateRecoveryState",
                tickDate: debugContext?.tickDate,
                evaluatedWeekId: debugContext?.evaluatedWeekId,
                evaluatedDay: debugContext?.evaluatedDay,
                completionCount: debugContext?.completionCount,
                expected: debugContext?.expected,
                missedWeeklyAppended: debugContext?.missedWeeklyAppended ?? false,
                missedDailyAppended: debugContext?.missedDailyAppended ?? false,
                weeklyViolationCountBefore: weeklyViolationCountBefore,
                weeklyViolationCountAfter: weeklyViolationCountAfter,
                threshold: threshold,
                stateBefore: stateBefore,
                stateAfter: stateAfter,
                recoveryEntered: recoveryEntered,
                reason: reason
            )
        }
    }

    private func recoveryViolationThreshold(for mode: NonNegotiableMode) -> Int {
        switch mode {
        case .daily:
            return 3
        case .session:
            return 2
        }
    }

    private func shouldEmitRecoveryTriggerDebugLog(
        for nn: NonNegotiable,
        missedWeeklyAppended: Bool,
        missedDailyAppended: Bool,
        recoveryEntered: Bool
    ) -> Bool {
        nn.definition.mode == .session || missedWeeklyAppended || missedDailyAppended || recoveryEntered
    }

    private func emitRecoveryTriggerDebugLog(
        nonNegotiable: NonNegotiable,
        source: String,
        tickDate: Date?,
        evaluatedWeekId: WeekID?,
        evaluatedDay: Date?,
        completionCount: Int?,
        expected: Int?,
        missedWeeklyAppended: Bool,
        missedDailyAppended: Bool,
        weeklyViolationCountBefore: Int,
        weeklyViolationCountAfter: Int,
        threshold: Int,
        stateBefore: NonNegotiableState,
        stateAfter: NonNegotiableState,
        recoveryEntered: Bool,
        reason: String
    ) {
        let title = nonNegotiable.definition.title.replacingOccurrences(of: "\"", with: "'")
        let tickDateString = tickDate.map { graceDebugDateFormatter.string(from: $0) } ?? "n/a"
        let evaluatedDayString = evaluatedDay.map { graceDebugDateFormatter.string(from: $0) } ?? "n/a"
        print(
            "[RecoveryTriggerDebug] " +
            "source=\(source) " +
            "protocolId=\(nonNegotiable.id.uuidString) " +
            "title=\"\(title)\" " +
            "mode=\(nonNegotiable.definition.mode.rawValue) " +
            "createdAt=\(graceDebugDateFormatter.string(from: nonNegotiable.createdAt)) " +
            "tickDate=\(tickDateString) " +
            "evaluatedWeekId=\(evaluatedWeekId?.description ?? "n/a") " +
            "evaluatedDay=\(evaluatedDayString) " +
            "completionCount=\(completionCount.map(String.init) ?? "n/a") " +
            "expected=\(expected.map(String.init) ?? "n/a") " +
            "missedWeeklyAppended=\(missedWeeklyAppended) " +
            "missedDailyAppended=\(missedDailyAppended) " +
            "weeklyViolationCountBefore=\(weeklyViolationCountBefore) " +
            "weeklyViolationCountAfter=\(weeklyViolationCountAfter) " +
            "recoveryThreshold=\(threshold) " +
            "stateBefore=\(stateBefore.rawValue) " +
            "stateAfter=\(stateAfter.rawValue) " +
            "recoveryEntered=\(recoveryEntered) " +
            "reason=\(reason)"
        )
    }
}
