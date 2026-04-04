import Foundation
import Combine

enum CommitmentStoreError: Error {
    case policyDenied(PolicyReason)
    case domain(Error)
}

@MainActor
final class CommitmentSystemStore: ObservableObject {
    struct RecoveryEntryContext: Equatable {
        let triggerProtocolId: UUID?
        let pausedProtocolId: UUID?
        let requiresPauseSelection: Bool
        let candidateProtocolIds: [UUID]
    }

    struct DailyLogGroup: Equatable {
        let day: Date
        let completions: [CompletionRecord]
        let violations: [Violation]
    }

    struct LogsCalendarDaySignal: Equatable {
        let day: Date
        let completionCount: Int
        let extraCount: Int
        let violationCount: Int
        let unproductive: Bool
        let noWorkRequiredSatisfied: Bool
        let inevitableWeeklyMiss: Bool
        let isToday: Bool
    }

    @Published private(set) var system: CommitmentSystem

    private let repository: CommitmentSystemRepository
    private let systemEngine: CommitmentSystemEngine
    private let nonNegotiableEngine: NonNegotiableEngine
    private let streakEngine: StreakEngine
    private let policy: CommitmentPolicyEngine
    private let calendar: Calendar

    init(
        repository: CommitmentSystemRepository,
        systemEngine: CommitmentSystemEngine,
        nonNegotiableEngine: NonNegotiableEngine,
        policy: CommitmentPolicyEngine? = nil,
        streakEngine: StreakEngine? = nil,
        calendar: Calendar? = nil
    ) {
        self.repository = repository
        self.systemEngine = systemEngine
        self.nonNegotiableEngine = nonNegotiableEngine
        self.policy = policy ?? CommitmentPolicyEngine()
        self.streakEngine = streakEngine ?? StreakEngine()
        self.calendar = calendar ?? DateRules.isoCalendar

        do {
            self.system = try repository.load()
            print("CommitmentSystemStore load succeeded")
        } catch {
            self.system = CommitmentSystem(nonNegotiables: [], createdAt: Date())
            print("CommitmentSystemStore load failed: \(error)")
        }
    }

    func createNonNegotiable(
        definition: NonNegotiableDefinition,
        totalLockDays: Int,
        referenceDate: Date = Date()
    ) throws {
        let decision = policy.canCreate(definition: definition, in: system, at: referenceDate)
        guard decision.allowed else {
            throw CommitmentStoreError.policyDenied(decision.reason ?? .generic(message: "Create action blocked."))
        }

        var updated = system

        do {
            let nonNegotiable = try nonNegotiableEngine.create(
                definition: definition,
                startDate: referenceDate,
                totalLockDays: totalLockDays
            )
            try systemEngine.add(nonNegotiable, to: &updated)
        } catch {
            throw CommitmentStoreError.domain(error)
        }

        system = updated
        persistSystem()
    }

    @discardableResult
    func recordCompletionDetailed(
        for id: UUID,
        at date: Date
    ) throws -> CompletionWriteOutcome {
        guard let target = system.nonNegotiables.first(where: { $0.id == id }) else {
            throw CommitmentStoreError.domain(CommitmentSystemError.nonNegotiableNotFound)
        }

        let policyDecision = policy.canRecordCompletion(nn: target, in: system, at: date)
        guard policyDecision.allowed else {
            throw CommitmentStoreError.policyDenied(policyDecision.reason ?? .generic(message: "Completion blocked."))
        }

        var updated = system
        let outcome: CompletionWriteOutcome
        do {
            outcome = try systemEngine.recordCompletion(nnId: id, date: date, in: &updated)
        } catch NonNegotiableEngineError.alreadyCompletedToday {
            throw CommitmentStoreError.policyDenied(.alreadyCompletedToday)
        } catch NonNegotiableEngineError.extraAlreadyLoggedToday {
            throw CommitmentStoreError.policyDenied(.extraAlreadyLoggedToday)
        } catch {
            throw CommitmentStoreError.domain(error)
        }

        system = updated
        persistSystem()
        return outcome
    }

    func recordCompletion(
        for id: UUID,
        at date: Date
    ) throws {
        do {
            _ = try recordCompletionDetailed(for: id, at: date)
        } catch let error as CommitmentStoreError {
            switch error {
            case .policyDenied:
                throw error
            case .domain(let domainError):
                throw domainError
            }
        }
    }

    @discardableResult
    func undoLatestCompletionToday(
        for id: UUID,
        at date: Date = Date()
    ) throws -> CompletionRecord {
        guard let nonNegotiableIndex = system.nonNegotiables.firstIndex(where: { $0.id == id }) else {
            throw CommitmentStoreError.domain(CommitmentSystemError.nonNegotiableNotFound)
        }

        let dayStart = DateRules.startOfDay(date, calendar: calendar)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            throw CommitmentStoreError.policyDenied(.generic(message: "Unable to undo completion right now."))
        }

        var updated = system
        let completions = updated.nonNegotiables[nonNegotiableIndex].completions
        let todaysCompletionIndices = completions.indices.filter { index in
            let completion = completions[index]
            return completion.date >= dayStart && completion.date < nextDay
        }
        guard let completionIndex = todaysCompletionIndices.max(by: { lhs, rhs in
            completions[lhs].date < completions[rhs].date
        }) else {
            throw CommitmentStoreError.policyDenied(.generic(message: "No completion to undo today."))
        }

        let removed = updated.nonNegotiables[nonNegotiableIndex].completions.remove(at: completionIndex)

        systemEngine.evaluateWeekCatchUp(referenceDate: date, in: &updated, calendar: calendar)
        systemEngine.evaluateRecoveryDay(referenceDate: date, in: &updated, calendar: calendar)
        systemEngine.advanceWindows(currentDate: date, in: &updated)
        applySystemUpdate(updated, referenceDate: date)
        return removed
    }

    func retireNonNegotiable(id: UUID, referenceDate: Date = Date()) throws {
        guard let index = system.nonNegotiables.firstIndex(where: { $0.id == id }) else {
            throw CommitmentStoreError.domain(CommitmentSystemError.nonNegotiableNotFound)
        }

        let target = system.nonNegotiables[index]
        let decision = policy.canRetire(nn: target, at: referenceDate)
        guard decision.allowed else {
            throw CommitmentStoreError.policyDenied(decision.reason ?? .generic(message: "Retire action blocked."))
        }

        var updated = system
        updated.nonNegotiables[index].state = .retired
        applyPostMutationRecoveryNormalization(updated, referenceDate: referenceDate)
    }

    func removeNonNegotiable(id: UUID) throws {
        guard let target = system.nonNegotiables.first(where: { $0.id == id }) else {
            throw CommitmentStoreError.domain(CommitmentSystemError.nonNegotiableNotFound)
        }

        let decision = policy.canRemove(nn: target)
        guard decision.allowed else {
            throw CommitmentStoreError.policyDenied(decision.reason ?? .generic(message: "Remove action blocked."))
        }

        var updated = system
        do {
            try systemEngine.remove(id, from: &updated)
        } catch {
            throw CommitmentStoreError.domain(error)
        }

        system = updated
        persistSystem()
    }

    func editNonNegotiable(
        id: UUID,
        patch: NonNegotiablePatch,
        referenceDate: Date = Date()
    ) throws {
        guard let index = system.nonNegotiables.firstIndex(where: { $0.id == id }) else {
            throw CommitmentStoreError.domain(CommitmentSystemError.nonNegotiableNotFound)
        }

        let current = system.nonNegotiables[index]
        let decision = policy.canEdit(nn: current, patch: patch, at: referenceDate)
        guard decision.allowed else {
            throw CommitmentStoreError.policyDenied(decision.reason ?? .generic(message: "Edit action blocked."))
        }

        let allowedFields = policy.allowedEditableFields(for: current, at: referenceDate)

        var nextTitle = current.definition.title
        if let newTitle = patch.newTitle, allowedFields.contains(.title) {
            let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty == false {
                nextTitle = trimmed
            }
        }

        var nextMode = current.definition.mode
        if let newMode = patch.newMode, allowedFields.contains(.mode) {
            nextMode = newMode
        }

        var nextFrequency = current.definition.frequencyPerWeek
        if let newFrequency = patch.newFrequencyPerWeek, allowedFields.contains(.frequency) {
            nextFrequency = newFrequency
        }

        var nextPreferred = current.definition.preferredExecutionSlot
        if let newPreferred = patch.newPreferredTime, allowedFields.contains(.preferredTime) {
            nextPreferred = newPreferred
        }

        var nextDuration = current.definition.estimatedDurationMinutes
        if let newDuration = patch.newEstimatedDurationMinutes, allowedFields.contains(.estimatedDuration) {
            nextDuration = newDuration
        }

        var nextIcon = current.definition.iconSystemName
        if let newIcon = patch.newIconName, allowedFields.contains(.icon) {
            nextIcon = newIcon
        }

        var nextLock = current.lock
        if let newLockDays = patch.newLockDays, allowedFields.contains(.lockDuration) {
            nextLock = LockConfiguration(
                startDate: current.lock.startDate,
                totalLockDays: newLockDays,
                windowLengthDays: current.lock.windowLengthDays
            )
        }

        let updatedDefinition = NonNegotiableDefinition(
            title: nextTitle,
            frequencyPerWeek: nextFrequency,
            mode: nextMode,
            goalId: current.definition.goalId,
            preferredExecutionSlot: nextPreferred,
            estimatedDurationMinutes: nextDuration,
            iconSystemName: nextIcon
        )
        do {
            try nonNegotiableEngine.validateDefinition(updatedDefinition, totalLockDays: nextLock.totalLockDays)
        } catch {
            throw CommitmentStoreError.domain(error)
        }

        var updated = system

        updated.nonNegotiables[index] = NonNegotiable(
            id: current.id,
            goalId: current.goalId,
            definition: updatedDefinition,
            state: current.state,
            lock: nextLock,
            createdAt: current.createdAt,
            windows: current.windows,
            completions: current.completions,
            violations: current.violations,
            lastDailyComplianceCheckedDay: current.lastDailyComplianceCheckedDay
        )

        system = updated
        persistSystem()
    }

    func updateNonNegotiableScheduling(
        id: UUID,
        preferredSlot: PreferredExecutionSlot,
        durationMinutes: Int,
        iconSystemName: String,
        title: String?
    ) throws {
        do {
            try editNonNegotiable(
                id: id,
                patch: NonNegotiablePatch(
                    newTitle: title,
                    newIconName: iconSystemName,
                    newPreferredTime: preferredSlot,
                    newEstimatedDurationMinutes: durationMinutes,
                    newMode: nil,
                    newFrequencyPerWeek: nil,
                    newLockDays: nil
                )
            )
        } catch let error as CommitmentStoreError {
            switch error {
            case .policyDenied:
                throw error
            case .domain(let domainError):
                throw domainError
            }
        }
    }

    func evaluateWeek(at date: Date) {
        var updated = system
        systemEngine.evaluateWeek(for: date, in: &updated)
        applySystemUpdate(updated, referenceDate: date)
    }

    func advanceWindows(at date: Date) {
        var updated = system
        systemEngine.advanceWindows(currentDate: date, in: &updated)
        applySystemUpdate(updated, referenceDate: date)
    }

    func runSystemIntegrityCheck(currentDate: Date) {
        var updated = system

        systemEngine.evaluateDailyCompliance(currentDate: currentDate, in: &updated)
        systemEngine.evaluateWeekCatchUp(referenceDate: currentDate, in: &updated, calendar: calendar)
        systemEngine.advanceWindows(currentDate: currentDate, in: &updated)
        applySystemUpdate(updated, referenceDate: currentDate)
    }

    func runDailyIntegrityTick(referenceDate: Date) {
        var updated = system
        let hadSessionProtocol = updated.nonNegotiables.contains(where: { $0.definition.mode == .session })
        let recoveryIdsBefore = Set(updated.nonNegotiables.filter { $0.state == .recovery }.map(\.id.uuidString)).sorted()
        if hadSessionProtocol || recoveryIdsBefore.isEmpty == false {
            print(
                "[RecoveryTriggerDebug] " +
                "source=runDailyIntegrityTick:start " +
                "tickDate=\(referenceDate.ISO8601Format()) " +
                "recoveryIdsBefore=\(recoveryIdsBefore.joined(separator: ","))"
            )
        }

        systemEngine.evaluateDailyCompliance(currentDate: referenceDate, in: &updated)
        systemEngine.evaluateWeekCatchUp(referenceDate: referenceDate, in: &updated, calendar: calendar)
        systemEngine.advanceWindows(currentDate: referenceDate, in: &updated)
        systemEngine.evaluateRecoveryDay(referenceDate: referenceDate, in: &updated, calendar: calendar)

        let recoveryIdsAfter = Set(updated.nonNegotiables.filter { $0.state == .recovery }.map(\.id.uuidString)).sorted()
        if hadSessionProtocol || recoveryIdsAfter.isEmpty == false || recoveryIdsBefore != recoveryIdsAfter {
            print(
                "[RecoveryTriggerDebug] " +
                "source=runDailyIntegrityTick:end " +
                "tickDate=\(referenceDate.ISO8601Format()) " +
                "recoveryIdsAfter=\(recoveryIdsAfter.joined(separator: ",")) " +
                "recoveryChanged=\(recoveryIdsBefore != recoveryIdsAfter)"
            )
        }

        applySystemUpdate(updated, referenceDate: referenceDate)
    }

    func runDailyComplianceCheck(currentDate: Date) {
        var updated = system

        systemEngine.evaluateDailyCompliance(currentDate: currentDate, in: &updated)
        applySystemUpdate(updated, referenceDate: currentDate)
    }

    func recoveryEntryContext(referenceDate: Date = Date()) -> RecoveryEntryContext? {
        _ = referenceDate
        guard system.recoveryEntryPendingResolution else { return nil }
        guard system.nonNegotiables.contains(where: { $0.state == .recovery }) else { return nil }

        let candidateIds = system.nonNegotiables
            .filter { $0.state == .active || $0.state == .recovery }
            .sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
            .map(\.id)

        return RecoveryEntryContext(
            triggerProtocolId: system.recoveryEntryTriggerProtocolId,
            pausedProtocolId: system.recoveryPausedProtocolId,
            requiresPauseSelection: system.recoveryEntryRequiresPauseSelection,
            candidateProtocolIds: candidateIds
        )
    }

    func pauseProtocolForRecovery(protocolId: UUID, referenceDate: Date = Date()) throws {
        _ = referenceDate
        guard system.recoveryEntryPendingResolution else { return }
        guard let index = system.nonNegotiables.firstIndex(where: { $0.id == protocolId }) else {
            throw CommitmentStoreError.domain(CommitmentSystemError.nonNegotiableNotFound)
        }

        let currentState = system.nonNegotiables[index].state
        guard currentState == .active || currentState == .recovery else {
            throw CommitmentStoreError.policyDenied(.protocolSuspended)
        }

        var updated = system
        updated.nonNegotiables[index].state = .suspended
        updated.recoveryPausedProtocolId = protocolId
        updated.recoveryEntryRequiresPauseSelection = false

        system = updated
        persistSystem()
    }

    func completeRecoveryEntryResolution() {
        guard system.recoveryEntryPendingResolution else { return }
        var updated = system
        updated.recoveryEntryPendingResolution = false
        updated.recoveryEntryRequiresPauseSelection = false
        updated.recoveryEntryTriggerProtocolId = nil
        system = updated
        persistSystem()
    }

    var activeNonNegotiables: [NonNegotiable] {
        system.activeNonNegotiables
    }

    var allowedCapacity: Int {
        system.allowedCapacity
    }

    var isSystemStable: Bool {
        systemEngine.isSystemStable(system)
    }

    var completionLog: [CompletionRecord] {
        system.nonNegotiables
            .flatMap(\.completions)
            .sorted { $0.date > $1.date }
    }

    var countedCompletionLog: [CompletionRecord] {
        completionLog.filter { $0.kind == .counted }
    }

    var extraCompletionLog: [CompletionRecord] {
        completionLog.filter { $0.kind == .extra }
    }

    var violationLog: [Violation] {
        system.nonNegotiables
            .flatMap(\.violations)
            .sorted { $0.date > $1.date }
    }

    var lastCompletionDate: Date? {
        completionLog.first?.date
    }

    var todayCompleted: Bool {
        todayCompleted(referenceDate: Date())
    }

    var currentStreakDays: Int {
        currentStreakDays(referenceDate: Date())
    }

    func todayCompleted(referenceDate: Date) -> Bool {
        streakEngine.completedOnDay(referenceDate, completions: countedCompletionLog)
    }

    func currentStreakDays(referenceDate: Date) -> Int {
        let completionsUpToNow = countedCompletionLog.filter { $0.date <= referenceDate }
        let violationsUpToNow = violationLog.filter { $0.date <= referenceDate }
        return streakEngine.currentStreakDays(
            from: completionsUpToNow,
            violations: violationsUpToNow,
            referenceDate: referenceDate,
            trackingStartDate: streakTrackingStartDate(referenceDate: referenceDate)
        )
    }

    func countedCompletions(for nnId: UUID, weekId: WeekID) -> Int {
        guard let nonNegotiable = system.nonNegotiables.first(where: { $0.id == nnId }) else {
            return 0
        }
        return nonNegotiable.completions.reduce(into: 0) { partial, completion in
            if completion.weekId == weekId && completion.kind == .counted {
                partial += 1
            }
        }
    }

    func countedCompletedToday(for nnId: UUID, date: Date) -> Bool {
        completionExists(for: nnId, date: date, kind: .counted)
    }

    func extraCompletedToday(for nnId: UUID, date: Date) -> Bool {
        completionExists(for: nnId, date: date, kind: .extra)
    }

    func logsGroupedByDay() -> [DailyLogGroup] {
        let completionByDay = Dictionary(grouping: completionLog) { record in
            DateRules.startOfDay(record.date, calendar: calendar)
        }
        let violationByDay = Dictionary(grouping: violationLog) { violation in
            DateRules.startOfDay(violation.date, calendar: calendar)
        }

        let days = Set(completionByDay.keys).union(violationByDay.keys).sorted(by: >)
        return days.map { day in
            DailyLogGroup(
                day: day,
                completions: completionByDay[day] ?? [],
                violations: violationByDay[day] ?? []
            )
        }
    }

    func streakTrackingStartDate(referenceDate: Date) -> Date? {
        let completionStarts = countedCompletionLog
            .filter { $0.date <= referenceDate }
            .map { DateRules.startOfDay($0.date, calendar: calendar) }
        let violationStarts = violationLog
            .filter { $0.date <= referenceDate }
            .map { DateRules.startOfDay($0.date, calendar: calendar) }
        return (completionStarts + violationStarts).min()
    }

    func logsCalendarSignals(lastDays: Int, referenceDate: Date) -> [LogsCalendarDaySignal] {
        guard lastDays > 0 else { return [] }

        let today = DateRules.startOfDay(referenceDate, calendar: calendar)
        guard let startDay = calendar.date(byAdding: .day, value: -(lastDays - 1), to: today) else {
            return []
        }

        let countedCompletions = countedCompletionLog.filter { $0.date <= referenceDate }
        let extras = extraCompletionLog.filter { $0.date <= referenceDate }
        let violations = violationLog.filter { $0.date <= referenceDate }

        return (0..<lastDays).compactMap { offset in
            guard let rawDay = calendar.date(byAdding: .day, value: offset, to: startDay) else {
                return nil
            }
            let day = DateRules.startOfDay(rawDay, calendar: calendar)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                return nil
            }

            let completionCount = countedCompletions.reduce(into: 0) { partial, completion in
                if completion.date >= day && completion.date < nextDay {
                    partial += 1
                }
            }
            let extraCount = extras.reduce(into: 0) { partial, completion in
                if completion.date >= day && completion.date < nextDay {
                    partial += 1
                }
            }
            let violationCount = violations.reduce(into: 0) { partial, violation in
                if violation.date >= day && violation.date < nextDay {
                    partial += 1
                }
            }

            let isClosedDay = day < today
            let hasRelevantProtocol = isClosedDay && hasRelevantProtocol(on: day)
            let requiresCountedCompletion = hasRelevantProtocol && requiresCountedCompletion(on: day)
            let unproductive = hasRelevantProtocol && requiresCountedCompletion && completionCount == 0
            let noWorkRequiredSatisfied = hasRelevantProtocol &&
                requiresCountedCompletion == false &&
                completionCount == 0 &&
                violationCount == 0
            let inevitableWeeklyMiss = isClosedDay && hasInevitableWeeklyMiss(on: day)

            return LogsCalendarDaySignal(
                day: day,
                completionCount: completionCount,
                extraCount: extraCount,
                violationCount: violationCount,
                unproductive: unproductive,
                noWorkRequiredSatisfied: noWorkRequiredSatisfied,
                inevitableWeeklyMiss: inevitableWeeklyMiss,
                isToday: day == today
            )
        }
    }

    func clearAllNonNegotiables() {
        system = CommitmentSystem(nonNegotiables: [], createdAt: Date())
        persistSystem()
    }

    func nonNegotiable(id: UUID) -> NonNegotiable? {
        system.nonNegotiables.first(where: { $0.id == id })
    }

    func allowedEditableFields(for id: UUID, referenceDate: Date = Date()) -> Set<ProtocolField> {
        guard let nonNegotiable = nonNegotiable(id: id) else {
            return []
        }
        return policy.allowedEditableFields(for: nonNegotiable, at: referenceDate)
    }

    func lawReasons(for id: UUID, referenceDate: Date = Date()) -> [PolicyReason] {
        guard let nonNegotiable = nonNegotiable(id: id) else { return [] }
        var reasons: [PolicyReason] = []

        if nonNegotiable.state == .suspended {
            reasons.append(.protocolSuspended)
        }

        if nonNegotiable.state == .recovery {
            let cleanDaysRemaining = max(0, 7 - max(system.recoveryCleanDayStreak, 0))
            reasons.append(
                .recoveryActive(
                    maxProtocols: system.allowedCapacity,
                    cleanDaysRemaining: cleanDaysRemaining
                )
            )
        }

        let lockEnd = DateRules.addingDays(
            nonNegotiable.lock.totalLockDays,
            to: DateRules.startOfDay(nonNegotiable.lock.startDate, calendar: calendar),
            calendar: calendar
        )
        let dayNow = DateRules.startOfDay(referenceDate, calendar: calendar)
        if dayNow < lockEnd {
            let daysRemaining = max(0, calendar.dateComponents([.day], from: dayNow, to: lockEnd).day ?? 0)
            reasons.append(.locked(daysRemaining: daysRemaining, endsOn: lockEnd))
        }

        return reasons
    }

    func policyCopy(for error: Error) -> PolicyCopy? {
        if let storeError = error as? CommitmentStoreError {
            switch storeError {
            case .policyDenied(let reason):
                return reason.copy()
            case .domain(let domainError):
                return policyCopy(for: domainError)
            }
        }

        if let systemError = error as? CommitmentSystemError {
            switch systemError {
            case .capacityExceeded:
                let activeCount = system.nonNegotiables.filter {
                    $0.state == .active || $0.state == .recovery
                }.count
                return PolicyReason.capacityExceeded(active: activeCount, allowed: system.allowedCapacity).copy()
            case .systemUnstable:
                return PolicyReason.systemUnstable.copy()
            case .cannotRemoveDuringLock:
                return PolicyReason.cannotRemoveUnlessCompletedOrRetired.copy()
            case .nonNegotiableNotFound:
                return PolicyReason.generic(message: "Protocol is no longer available.").copy()
            }
        }

        if let engineError = error as? NonNegotiableEngineError {
            switch engineError {
            case .alreadyCompletedToday:
                return PolicyReason.alreadyCompletedToday.copy()
            case .extraAlreadyLoggedToday:
                return PolicyReason.extraAlreadyLoggedToday.copy()
            case .alreadyRetiredOrCompleted:
                return PolicyReason.protocolCompletedOrRetired.copy()
            case .outsideLockPeriod:
                return PolicyReason.generic(message: "Completion is available only during the lock period.").copy()
            case .invalidDefinition:
                return nil
            }
        }

        return nil
    }

    private func persistSystem() {
        do {
            try repository.save(system)
            print("CommitmentSystemStore save succeeded")
        } catch {
            print("CommitmentSystemStore save failed: \(error)")
        }
    }

    private func completionExists(for nnId: UUID, date: Date, kind: CompletionKind) -> Bool {
        guard let nonNegotiable = system.nonNegotiables.first(where: { $0.id == nnId }) else {
            return false
        }
        let day = DateRules.startOfDay(date, calendar: calendar)
        return nonNegotiable.completions.contains {
            $0.kind == kind && DateRules.startOfDay($0.date, calendar: calendar) == day
        }
    }

    private func applySystemUpdate(_ updatedSystem: CommitmentSystem, referenceDate: Date) {
        var next = updatedSystem
        handleRecoveryTransition(from: system, to: &next, referenceDate: referenceDate)

        guard next != system else { return }
        system = next
        persistSystem()
    }

    private func applyPostMutationRecoveryNormalization(
        _ updatedSystem: CommitmentSystem,
        referenceDate: Date
    ) {
        var normalized = updatedSystem
        _ = systemEngine.normalizeRecoveryDomain(in: &normalized)
        applySystemUpdate(normalized, referenceDate: referenceDate)
    }

    private func handleRecoveryTransition(
        from previous: CommitmentSystem,
        to updated: inout CommitmentSystem,
        referenceDate: Date
    ) {
        let wasInRecovery = previous.nonNegotiables.contains(where: { $0.state == .recovery })
        let isInRecovery = updated.nonNegotiables.contains(where: { $0.state == .recovery })

        if wasInRecovery == false && isInRecovery {
            let previousRecoveryIds = Set(previous.nonNegotiables.filter { $0.state == .recovery }.map(\.id))
            let enteredRecovery = updated.nonNegotiables
                .filter { $0.state == .recovery && previousRecoveryIds.contains($0.id) == false }
                .sorted { lhs, rhs in
                    if lhs.createdAt != rhs.createdAt {
                        return lhs.createdAt < rhs.createdAt
                    }
                    return lhs.id.uuidString < rhs.id.uuidString
                }

            let activeOrRecoveryCount = updated.nonNegotiables.filter {
                $0.state == .active || $0.state == .recovery
            }.count

            updated.recoveryEntryPendingResolution = true
            updated.recoveryEntryRequiresPauseSelection = activeOrRecoveryCount > 1
            updated.recoveryEntryTriggerProtocolId = enteredRecovery.first?.id
            updated.recoveryPausedProtocolId = nil
            updated.recoveryCleanDayStreak = 0
            let entryDay = DateRules.startOfDay(referenceDate, calendar: calendar)
            updated.lastRecoveryEvaluationDay = calendar.date(byAdding: .day, value: -1, to: entryDay) ?? entryDay
            return
        }

        if wasInRecovery && isInRecovery == false {
            updated.recoveryEntryPendingResolution = false
            updated.recoveryEntryRequiresPauseSelection = false
            updated.recoveryEntryTriggerProtocolId = nil
            updated.recoveryPausedProtocolId = nil
        }
    }

    private func hasRelevantProtocol(on day: Date) -> Bool {
        system.nonNegotiables.contains { nonNegotiable in
            switch nonNegotiable.state {
            case .retired, .completed:
                return false
            case .draft, .active, .recovery, .suspended:
                return isWithinLockInterval(day: day, lock: nonNegotiable.lock)
            }
        }
    }

    private func hasInevitableWeeklyMiss(on day: Date) -> Bool {
        let week = DateRules.weekInterval(containing: day, calendar: calendar)
        let weekId = DateRules.weekID(for: day, calendar: calendar)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: day) else {
            return false
        }

        return system.nonNegotiables.contains { nonNegotiable in
            guard nonNegotiable.definition.mode == .session else { return false }
            switch nonNegotiable.state {
            case .retired, .completed, .suspended:
                return false
            case .draft, .active, .recovery:
                break
            }

            guard isWithinLockInterval(day: day, lock: nonNegotiable.lock) else { return false }
            guard lockIntervalIntersectsWeek(nonNegotiable.lock, week: week) else { return false }

            let weeklyTarget = effectiveWeeklyTarget(for: nonNegotiable, in: week)
            guard weeklyTarget > 0 else { return false }

            let countedSoFar = nonNegotiable.completions.reduce(into: 0) { partial, completion in
                guard completion.kind == .counted else { return }
                guard completion.weekId == weekId else { return }
                guard completion.date >= week.start && completion.date < dayEnd else { return }
                if isWithinLockInterval(moment: completion.date, lock: nonNegotiable.lock) {
                    partial += 1
                }
            }

            let remainingNeeded = max(0, weeklyTarget - countedSoFar)
            guard remainingNeeded > 0 else { return false }

            let feasibleFutureDays = feasibleCompletionDays(
                for: nonNegotiable.lock,
                after: day,
                withinWeek: week
            )

            return remainingNeeded > feasibleFutureDays
        }
    }

    private func requiresCountedCompletion(on day: Date) -> Bool {
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
            guard isWithinLockInterval(day: dayStart, lock: nonNegotiable.lock) else {
                return false
            }

            switch nonNegotiable.definition.mode {
            case .daily:
                if isDailyCreationGraceDay(for: nonNegotiable, day: dayStart) {
                    return false
                }
                let hasCountedToday = nonNegotiable.completions.contains { completion in
                    completion.kind == .counted &&
                    completion.date >= dayStart &&
                    completion.date < dayEnd
                }
                return hasCountedToday == false

            case .session:
                let weeklyTarget = effectiveWeeklyTarget(for: nonNegotiable, in: week)
                guard weeklyTarget > 0 else { return false }

                let countedSoFarWeek = nonNegotiable.completions.reduce(into: 0) { partial, completion in
                    guard completion.kind == .counted else { return }
                    guard completion.weekId == weekId else { return }
                    guard completion.date >= week.start && completion.date < dayEnd else { return }
                    guard isWithinLockInterval(moment: completion.date, lock: nonNegotiable.lock) else { return }
                    partial += 1
                }

                let remainingNeeded = max(0, weeklyTarget - countedSoFarWeek)
                guard remainingNeeded > 0 else { return false }

                let feasibleFutureDays = feasibleCompletionDays(
                    for: nonNegotiable.lock,
                    after: dayStart,
                    withinWeek: week
                )
                return remainingNeeded > feasibleFutureDays
            }
        }
    }

    private func effectiveWeeklyTarget(for nonNegotiable: NonNegotiable, in week: DateInterval) -> Int {
        let normalizedTarget = NonNegotiableDefinition.normalizedFrequency(
            nonNegotiable.definition.frequencyPerWeek,
            mode: nonNegotiable.definition.mode
        )
        guard normalizedTarget > 0 else { return 0 }
        guard isInitialPartialGraceWeek(for: nonNegotiable, in: week) == false else {
            return 0
        }
        return normalizedTarget
    }

    private func isInitialPartialGraceWeek(for nonNegotiable: NonNegotiable, in week: DateInterval) -> Bool {
        guard nonNegotiable.definition.mode == .session else { return false }

        let creationWeekId = DateRules.weekID(for: nonNegotiable.createdAt, calendar: calendar)
        let weekId = DateRules.weekID(for: week.start, calendar: calendar)
        guard creationWeekId == weekId else { return false }

        // Increment 4 keeps current normalized createdAt semantics.
        return nonNegotiable.createdAt > week.start
    }

    private func isDailyCreationGraceDay(for nonNegotiable: NonNegotiable, day: Date) -> Bool {
        guard nonNegotiable.definition.mode == .daily else { return false }
        let creationDay = DateRules.startOfDay(nonNegotiable.createdAt, calendar: calendar)
        let targetDay = DateRules.startOfDay(day, calendar: calendar)
        return creationDay == targetDay
    }

    private func feasibleCompletionDays(
        for lock: LockConfiguration,
        after day: Date,
        withinWeek week: DateInterval
    ) -> Int {
        guard let firstCandidate = calendar.date(byAdding: .day, value: 1, to: day) else {
            return 0
        }

        var cursor = DateRules.startOfDay(firstCandidate, calendar: calendar)
        var count = 0
        while cursor < week.end {
            if isWithinLockInterval(day: cursor, lock: lock) {
                count += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = next
        }
        return count
    }

    private func lockIntervalIntersectsWeek(_ lock: LockConfiguration, week: DateInterval) -> Bool {
        let lockStart = DateRules.startOfDay(lock.startDate, calendar: calendar)
        let lockEnd = DateRules.addingDays(lock.totalLockDays, to: lockStart, calendar: calendar)
        return lockStart < week.end && lockEnd > week.start
    }

    private func isWithinLockInterval(day: Date, lock: LockConfiguration) -> Bool {
        let lockStart = DateRules.startOfDay(lock.startDate, calendar: calendar)
        let lockEnd = DateRules.addingDays(lock.totalLockDays, to: lockStart, calendar: calendar)
        let normalizedDay = DateRules.startOfDay(day, calendar: calendar)
        return normalizedDay >= lockStart && normalizedDay < lockEnd
    }

    private func isWithinLockInterval(moment: Date, lock: LockConfiguration) -> Bool {
        let lockStart = DateRules.startOfDay(lock.startDate, calendar: calendar)
        let lockEnd = DateRules.addingDays(lock.totalLockDays, to: lockStart, calendar: calendar)
        return moment >= lockStart && moment < lockEnd
    }
}
