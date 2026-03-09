import Foundation
@testable import LockedIn

final class RecordingCommitmentSystemRepository: CommitmentSystemRepository {
    private(set) var storedSystem: CommitmentSystem
    private(set) var saveCalls: [CommitmentSystem] = []
    var failOnSave = false

    init(initialSystem: CommitmentSystem = CommitmentSystem(nonNegotiables: [], createdAt: Date())) {
        storedSystem = initialSystem
    }

    func load() throws -> CommitmentSystem {
        storedSystem
    }

    func save(_ system: CommitmentSystem) throws {
        if failOnSave {
            throw NSError(domain: "RecordingCommitmentSystemRepository", code: 1)
        }
        storedSystem = system
        saveCalls.append(system)
    }
}

enum CommitmentSystemStoreTestFixtures {
    static var calendar: Calendar { TestCalendarSupport.utcISO8601 }

    static var referenceDate: Date {
        DateRules.date(year: 2026, month: 1, day: 5, hour: 9, calendar: calendar)
    }

    static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 9,
        minute: Int = 0
    ) -> Date {
        DateRules.date(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            calendar: calendar
        )
    }

    static func makeCompletion(
        date: Date,
        kind: CompletionKind = .counted
    ) -> CompletionRecord {
        CompletionRecord(
            date: date,
            weekId: DateRules.weekID(for: date, calendar: calendar),
            kind: kind
        )
    }

    static func makeProtocol(
        id: UUID = UUID(),
        title: String = "Protocol",
        mode: NonNegotiableMode = .session,
        frequencyPerWeek: Int = 3,
        estimatedDurationMinutes: Int = 60,
        state: NonNegotiableState = .active,
        startDate: Date = referenceDate,
        totalLockDays: Int = 30,
        createdAt: Date? = nil,
        completions: [CompletionRecord] = [],
        violations: [Violation] = [],
        lastDailyComplianceCheckedDay: Date? = nil
    ) -> NonNegotiable {
        let lockStart = DateRules.startOfDay(startDate, calendar: calendar)
        let lock = LockConfiguration(startDate: lockStart, totalLockDays: totalLockDays)
        let windowEnd = DateRules.addingDays(lock.windowLengthDays, to: lockStart, calendar: calendar)

        return NonNegotiable(
            id: id,
            goalId: UUID(),
            definition: NonNegotiableDefinition(
                title: title,
                frequencyPerWeek: frequencyPerWeek,
                mode: mode,
                goalId: UUID(),
                preferredExecutionSlot: .none,
                estimatedDurationMinutes: estimatedDurationMinutes,
                iconSystemName: "bolt.fill"
            ),
            state: state,
            lock: lock,
            createdAt: createdAt ?? lockStart,
            windows: [
                Window(index: 0, startDate: lockStart, endDate: windowEnd)
            ],
            completions: completions,
            violations: violations,
            lastDailyComplianceCheckedDay: lastDailyComplianceCheckedDay
        )
    }

    static func makeSystem(
        nonNegotiables: [NonNegotiable],
        createdAt: Date = referenceDate,
        recoveryCleanDayStreak: Int = 0,
        lastRecoveryEvaluationDay: Date? = nil,
        recoveryEntryPendingResolution: Bool = false,
        recoveryEntryRequiresPauseSelection: Bool = false,
        recoveryEntryTriggerProtocolId: UUID? = nil,
        recoveryPausedProtocolId: UUID? = nil
    ) -> CommitmentSystem {
        CommitmentSystem(
            nonNegotiables: nonNegotiables,
            createdAt: createdAt,
            recoveryCleanDayStreak: recoveryCleanDayStreak,
            lastRecoveryEvaluationDay: lastRecoveryEvaluationDay,
            recoveryEntryPendingResolution: recoveryEntryPendingResolution,
            recoveryEntryRequiresPauseSelection: recoveryEntryRequiresPauseSelection,
            recoveryEntryTriggerProtocolId: recoveryEntryTriggerProtocolId,
            recoveryPausedProtocolId: recoveryPausedProtocolId
        )
    }
}

enum CommitmentSystemStoreTestRetainer {
    static var stores: [CommitmentSystemStore] = []

    static func retain(_ store: CommitmentSystemStore) {
        stores.append(store)
    }
}
