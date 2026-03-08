import Foundation

enum CommitmentSystemError: Error {
    case capacityExceeded
    case nonNegotiableNotFound
    case cannotRemoveDuringLock
    case systemUnstable
}

struct CompletionWriteOutcome: Equatable {
    let protocolId: UUID
    let date: Date
    let kind: CompletionKind
}

final class CommitmentSystemEngine {
    private let nonNegotiableEngine: NonNegotiableEngine
    private let requireCompletionForCleanDay: Bool

    init(
        nonNegotiableEngine: NonNegotiableEngine,
        requireCompletionForCleanDay: Bool = true
    ) {
        self.nonNegotiableEngine = nonNegotiableEngine
        self.requireCompletionForCleanDay = requireCompletionForCleanDay
    }

    func add(_ nn: NonNegotiable, to system: inout CommitmentSystem) throws {
        guard canCreateNewNonNegotiable(system) else {
            throw CommitmentSystemError.capacityExceeded
        }

        system.nonNegotiables.append(nn)
        enforceCapacityIfNeeded(in: &system)
    }

    func remove(_ id: UUID, from system: inout CommitmentSystem) throws {
        guard let index = system.nonNegotiables.firstIndex(where: { $0.id == id }) else {
            throw CommitmentSystemError.nonNegotiableNotFound
        }

        let target = system.nonNegotiables[index]
        switch target.state {
        case .completed, .retired:
            system.nonNegotiables.remove(at: index)
        case .draft, .active, .recovery, .suspended:
            throw CommitmentSystemError.cannotRemoveDuringLock
        }
    }

    func recordCompletion(nnId: UUID, date: Date, in system: inout CommitmentSystem) throws -> CompletionWriteOutcome {
        guard let index = system.nonNegotiables.firstIndex(where: { $0.id == nnId }) else {
            throw CommitmentSystemError.nonNegotiableNotFound
        }

        if system.nonNegotiables[index].state == .suspended {
            throw CommitmentSystemError.systemUnstable
        }

        var nn = system.nonNegotiables[index]
        let decision = try nonNegotiableEngine.recordCompletion(&nn, at: date)
        system.nonNegotiables[index] = nn

        enforceCapacityIfNeeded(in: &system)
        return CompletionWriteOutcome(protocolId: nnId, date: date, kind: decision.kind)
    }

    func evaluateWeek(for date: Date, in system: inout CommitmentSystem) {
        for index in system.nonNegotiables.indices {
            let state = system.nonNegotiables[index].state
            if state != .active && state != .recovery {
                continue
            }

            var nn = system.nonNegotiables[index]
            nonNegotiableEngine.evaluateWeekIfNeeded(&nn, weekEnding: date)
            system.nonNegotiables[index] = nn
        }

        enforceCapacityIfNeeded(in: &system)
    }

    func evaluateWeekCatchUp(
        referenceDate: Date,
        in system: inout CommitmentSystem,
        calendar: Calendar = DateRules.isoCalendar
    ) {
        guard !system.nonNegotiables.isEmpty else { return }

        let startOfToday = DateRules.startOfDay(referenceDate, calendar: calendar)
        guard let earliestStart = system.nonNegotiables
            .map({ DateRules.startOfDay($0.lock.startDate, calendar: calendar) })
            .min() else {
            return
        }

        var weekStart = DateRules.weekInterval(containing: earliestStart, calendar: calendar).start
        while let weekEndExclusive = calendar.date(byAdding: .day, value: 7, to: weekStart),
              weekEndExclusive <= startOfToday {
            let weekEnding = calendar.date(byAdding: .second, value: -1, to: weekEndExclusive) ?? weekEndExclusive
            evaluateWeek(for: weekEnding, in: &system)
            weekStart = weekEndExclusive
        }
    }

    func evaluateRecoveryDay(
        referenceDate: Date,
        in system: inout CommitmentSystem,
        calendar: Calendar = DateRules.isoCalendar
    ) {
        let evaluationDay = DateRules.startOfDay(referenceDate, calendar: calendar)

        if let last = system.lastRecoveryEvaluationDay,
           calendar.isDate(last, inSameDayAs: evaluationDay) {
            return
        }

        guard isSystemInRecovery(system) else {
            system.recoveryCleanDayStreak = 0
            system.lastRecoveryEvaluationDay = evaluationDay
            return
        }

        if isCleanRecoveryDay(evaluationDay, in: system, calendar: calendar) {
            system.recoveryCleanDayStreak += 1
        } else {
            system.recoveryCleanDayStreak = 0
        }

        if system.recoveryCleanDayStreak >= 7 {
            for index in system.nonNegotiables.indices where system.nonNegotiables[index].state == .recovery {
                system.nonNegotiables[index].state = .active
            }

            resumeSuspendedIfCapacityAllows(in: &system)
            system.recoveryCleanDayStreak = 0
        }

        system.lastRecoveryEvaluationDay = evaluationDay
    }

    func evaluateDailyCompliance(currentDate: Date, in system: inout CommitmentSystem) {
        for index in system.nonNegotiables.indices {
            let state = system.nonNegotiables[index].state
            if state != .active && state != .recovery {
                continue
            }

            var nn = system.nonNegotiables[index]
            nonNegotiableEngine.evaluateDailyComplianceIfNeeded(&nn, at: currentDate)
            system.nonNegotiables[index] = nn
        }

        enforceCapacityIfNeeded(in: &system)
    }

    func advanceWindows(currentDate: Date, in system: inout CommitmentSystem) {
        for index in system.nonNegotiables.indices {
            let state = system.nonNegotiables[index].state
            if state != .active && state != .recovery {
                continue
            }

            var nn = system.nonNegotiables[index]
            nonNegotiableEngine.advanceWindowIfNeeded(&nn, currentDate: currentDate)
            system.nonNegotiables[index] = nn
        }
    }

    func isSystemStable(_ system: CommitmentSystem) -> Bool {
        if system.nonNegotiables.contains(where: { $0.state == .recovery }) {
            return false
        }

        for nn in system.nonNegotiables {
            guard let currentWindow = nn.windows.last else { continue }
            if currentWindow.weeklyViolationCount >= 3 {
                return false
            }
        }

        return true
    }

    func canCreateNewNonNegotiable(_ system: CommitmentSystem) -> Bool {
        let activeCount = system.activeNonNegotiables.count
        guard activeCount < system.allowedCapacity else { return false }
        return isSystemStable(system)
    }

    // Capacity is reduced to 2 when any NN is recovering.
    // If active count exceeds this reduced capacity, suspend the most recently created active NN.
    private func enforceCapacityIfNeeded(in system: inout CommitmentSystem) {
        if system.nonNegotiables.contains(where: { $0.state == .recovery }) &&
            system.recoveryEntryPendingResolution == false &&
            system.recoveryPausedProtocolId == nil {
            return
        }

        if system.recoveryEntryPendingResolution {
            return
        }

        let allowed = system.allowedCapacity

        while constrainedCount(system) > allowed {
            guard let indexToSuspend = system.nonNegotiables
                .enumerated()
                .filter({ $0.element.state == .active })
                .max(by: { lhs, rhs in
                    lhs.element.createdAt < rhs.element.createdAt
                })?
                .offset else {
                break
            }

            system.nonNegotiables[indexToSuspend].state = .suspended
        }
    }

    private func constrainedCount(_ system: CommitmentSystem) -> Int {
        system.nonNegotiables.filter { nn in
            nn.state == .active || nn.state == .recovery
        }.count
    }

    private func isSystemInRecovery(_ system: CommitmentSystem) -> Bool {
        system.nonNegotiables.contains(where: { $0.state == .recovery })
    }

    private func isCleanRecoveryDay(
        _ day: Date,
        in system: CommitmentSystem,
        calendar: Calendar
    ) -> Bool {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
            return false
        }

        let hasViolationToday = system.nonNegotiables
            .flatMap(\.violations)
            .contains { $0.date >= day && $0.date < nextDay }
        if hasViolationToday {
            return false
        }

        if !requireCompletionForCleanDay {
            return true
        }

        if hasCountedCompletion(on: day, in: system, calendar: calendar) {
            return true
        }

        return requiresCountedCompletionForRecovery(on: day, in: system, calendar: calendar) == false
    }

    private func hasCountedCompletion(
        on day: Date,
        in system: CommitmentSystem,
        calendar: Calendar
    ) -> Bool {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
            return false
        }

        return system.nonNegotiables
            .filter { $0.state == .active || $0.state == .recovery }
            .flatMap(\.completions)
            .contains { $0.kind == .counted && $0.date >= day && $0.date < nextDay }
    }

    private func requiresCountedCompletionForRecovery(
        on day: Date,
        in system: CommitmentSystem,
        calendar: Calendar
    ) -> Bool {
        let dayStart = DateRules.startOfDay(day, calendar: calendar)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return false
        }
        let week = DateRules.weekInterval(containing: dayStart, calendar: calendar)
        let weekId = DateRules.weekID(for: dayStart, calendar: calendar)

        return system.nonNegotiables.contains { nonNegotiable in
            guard nonNegotiable.state == .active || nonNegotiable.state == .recovery else {
                return false
            }
            guard isWithinLockInterval(day: dayStart, lock: nonNegotiable.lock, calendar: calendar) else {
                return false
            }

            switch nonNegotiable.definition.mode {
            case .daily:
                let hasCountedToday = nonNegotiable.completions.contains { completion in
                    completion.kind == .counted &&
                    completion.date >= dayStart &&
                    completion.date < dayEnd
                }
                return hasCountedToday == false

            case .session:
                let weeklyTarget = NonNegotiableDefinition.normalizedFrequency(
                    nonNegotiable.definition.frequencyPerWeek,
                    mode: nonNegotiable.definition.mode
                )
                guard weeklyTarget > 0 else { return false }

                let countedSoFarWeek = nonNegotiable.completions.reduce(into: 0) { partial, completion in
                    guard completion.kind == .counted else { return }
                    guard completion.weekId == weekId else { return }
                    guard completion.date >= week.start && completion.date < dayEnd else { return }
                    guard isWithinLockInterval(moment: completion.date, lock: nonNegotiable.lock, calendar: calendar) else { return }
                    partial += 1
                }

                let remainingNeeded = max(0, weeklyTarget - countedSoFarWeek)
                guard remainingNeeded > 0 else { return false }

                let feasibleFutureDays = feasibleCompletionDays(
                    for: nonNegotiable.lock,
                    after: dayStart,
                    withinWeek: week,
                    calendar: calendar
                )
                return remainingNeeded > feasibleFutureDays
            }
        }
    }

    private func feasibleCompletionDays(
        for lock: LockConfiguration,
        after day: Date,
        withinWeek week: DateInterval,
        calendar: Calendar
    ) -> Int {
        guard let firstCandidate = calendar.date(byAdding: .day, value: 1, to: day) else {
            return 0
        }

        var cursor = DateRules.startOfDay(firstCandidate, calendar: calendar)
        var count = 0
        while cursor < week.end {
            if isWithinLockInterval(day: cursor, lock: lock, calendar: calendar) {
                count += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = next
        }
        return count
    }

    private func isWithinLockInterval(
        day: Date,
        lock: LockConfiguration,
        calendar: Calendar
    ) -> Bool {
        let lockStart = DateRules.startOfDay(lock.startDate, calendar: calendar)
        let lockEnd = DateRules.addingDays(lock.totalLockDays, to: lockStart, calendar: calendar)
        let normalizedDay = DateRules.startOfDay(day, calendar: calendar)
        return normalizedDay >= lockStart && normalizedDay < lockEnd
    }

    private func isWithinLockInterval(
        moment: Date,
        lock: LockConfiguration,
        calendar: Calendar
    ) -> Bool {
        let lockStart = DateRules.startOfDay(lock.startDate, calendar: calendar)
        let lockEnd = DateRules.addingDays(lock.totalLockDays, to: lockStart, calendar: calendar)
        return moment >= lockStart && moment < lockEnd
    }

    private func resumeSuspendedIfCapacityAllows(in system: inout CommitmentSystem) {
        let suspendedByCreatedAt = system.nonNegotiables
            .enumerated()
            .filter { $0.element.state == .suspended }
            .sorted { $0.element.createdAt < $1.element.createdAt }
            .map(\.offset)

        for index in suspendedByCreatedAt {
            guard constrainedCount(system) < system.allowedCapacity else {
                break
            }
            system.nonNegotiables[index].state = .active
        }
    }
}
