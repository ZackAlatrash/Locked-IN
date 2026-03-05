import Foundation
import Combine

@MainActor
final class CommitmentSystemStore: ObservableObject {
    struct DailyLogGroup: Equatable {
        let day: Date
        let completions: [CompletionRecord]
        let violations: [Violation]
    }

    @Published private(set) var system: CommitmentSystem

    private let repository: CommitmentSystemRepository
    private let systemEngine: CommitmentSystemEngine
    private let nonNegotiableEngine: NonNegotiableEngine
    private let streakEngine: StreakEngine
    private let calendar: Calendar

    init(
        repository: CommitmentSystemRepository,
        systemEngine: CommitmentSystemEngine,
        nonNegotiableEngine: NonNegotiableEngine,
        streakEngine: StreakEngine = StreakEngine(),
        calendar: Calendar = DateRules.isoCalendar
    ) {
        self.repository = repository
        self.systemEngine = systemEngine
        self.nonNegotiableEngine = nonNegotiableEngine
        self.streakEngine = streakEngine
        self.calendar = calendar

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
        totalLockDays: Int
    ) throws {
        var updated = system

        let nonNegotiable = try nonNegotiableEngine.create(
            definition: definition,
            startDate: Date(),
            totalLockDays: totalLockDays
        )
        try systemEngine.add(nonNegotiable, to: &updated)

        system = updated
        persistSystem()
    }

    @discardableResult
    func recordCompletionDetailed(
        for id: UUID,
        at date: Date
    ) throws -> CompletionWriteOutcome {
        var updated = system
        let outcome = try systemEngine.recordCompletion(nnId: id, date: date, in: &updated)

        system = updated
        persistSystem()
        return outcome
    }

    func recordCompletion(
        for id: UUID,
        at date: Date
    ) throws {
        _ = try recordCompletionDetailed(for: id, at: date)
    }

    func removeNonNegotiable(id: UUID) throws {
        var updated = system
        try systemEngine.remove(id, from: &updated)

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
        guard let index = system.nonNegotiables.firstIndex(where: { $0.id == id }) else {
            throw CommitmentSystemError.nonNegotiableNotFound
        }

        var updated = system
        let current = updated.nonNegotiables[index]
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextTitle = (trimmedTitle?.isEmpty == false ? trimmedTitle : current.definition.title) ?? current.definition.title

        let updatedDefinition = NonNegotiableDefinition(
            title: nextTitle,
            frequencyPerWeek: current.definition.frequencyPerWeek,
            mode: current.definition.mode,
            goalId: current.definition.goalId,
            preferredExecutionSlot: preferredSlot,
            estimatedDurationMinutes: durationMinutes,
            iconSystemName: iconSystemName
        )
        try nonNegotiableEngine.validateDefinition(updatedDefinition, totalLockDays: current.lock.totalLockDays)

        updated.nonNegotiables[index] = NonNegotiable(
            id: current.id,
            goalId: current.goalId,
            definition: updatedDefinition,
            state: current.state,
            lock: current.lock,
            createdAt: current.createdAt,
            windows: current.windows,
            completions: current.completions,
            violations: current.violations,
            lastDailyComplianceCheckedDay: current.lastDailyComplianceCheckedDay
        )

        system = updated
        persistSystem()
    }

    func evaluateWeek(at date: Date) {
        let previous = system
        var updated = system
        systemEngine.evaluateWeek(for: date, in: &updated)

        guard updated != previous else { return }
        system = updated
        persistSystem()
    }

    func advanceWindows(at date: Date) {
        let previous = system
        var updated = system
        systemEngine.advanceWindows(currentDate: date, in: &updated)

        guard updated != previous else { return }
        system = updated
        persistSystem()
    }

    func runSystemIntegrityCheck(currentDate: Date) {
        let previous = system
        var updated = system

        systemEngine.evaluateDailyCompliance(currentDate: currentDate, in: &updated)
        systemEngine.evaluateWeekCatchUp(referenceDate: currentDate, in: &updated, calendar: calendar)
        systemEngine.advanceWindows(currentDate: currentDate, in: &updated)

        guard updated != previous else { return }
        system = updated
        persistSystem()
    }

    func runDailyIntegrityTick(referenceDate: Date) {
        runSystemIntegrityCheck(currentDate: referenceDate)

        let previous = system
        var updated = system
        systemEngine.evaluateRecoveryDay(referenceDate: referenceDate, in: &updated, calendar: calendar)

        guard updated != previous else { return }
        system = updated
        persistSystem()
    }

    func runDailyComplianceCheck(currentDate: Date) {
        let previous = system
        var updated = system

        systemEngine.evaluateDailyCompliance(currentDate: currentDate, in: &updated)

        guard updated != previous else { return }
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
        streakEngine.currentStreakDays(from: countedCompletionLog, referenceDate: referenceDate)
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

    func clearAllNonNegotiables() {
        system = CommitmentSystem(nonNegotiables: [], createdAt: Date())
        persistSystem()
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
}
