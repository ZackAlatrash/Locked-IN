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

    func recordCompletion(
        for id: UUID,
        at date: Date
    ) throws {
        var updated = system
        try systemEngine.recordCompletion(nnId: id, date: date, in: &updated)

        system = updated
        persistSystem()
    }

    func removeNonNegotiable(id: UUID) throws {
        var updated = system
        try systemEngine.remove(id, from: &updated)

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

    var violationLog: [Violation] {
        system.nonNegotiables
            .flatMap(\.violations)
            .sorted { $0.date > $1.date }
    }

    var lastCompletionDate: Date? {
        completionLog.first?.date
    }

    var todayCompleted: Bool {
        streakEngine.completedOnDay(Date(), completions: completionLog)
    }

    var currentStreakDays: Int {
        streakEngine.currentStreakDays(from: completionLog, referenceDate: Date())
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
}
