import Foundation
@testable import LockedIn

final class RecordingPlanAllocationRepository: PlanAllocationRepository {
    private(set) var storedAllocations: [PlanAllocation]
    private(set) var saveCalls: [[PlanAllocation]] = []
    var failOnSave = false

    init(initialAllocations: [PlanAllocation] = []) {
        storedAllocations = initialAllocations
    }

    func load() throws -> [PlanAllocation] {
        storedAllocations
    }

    func save(_ allocations: [PlanAllocation]) throws {
        if failOnSave {
            throw NSError(domain: "RecordingPlanAllocationRepository", code: 1)
        }
        storedAllocations = allocations
        saveCalls.append(allocations)
    }
}

enum PlanStoreTestFixtures {
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

    static func makeSystem(
        protocols: [NonNegotiable],
        createdAt: Date = referenceDate
    ) -> CommitmentSystem {
        CommitmentSystem(nonNegotiables: protocols, createdAt: createdAt)
    }

    static func makeSessionProtocol(
        id: UUID = UUID(),
        title: String = "Deep Work",
        frequencyPerWeek: Int = 3,
        estimatedDurationMinutes: Int = 60,
        state: NonNegotiableState = .active,
        completions: [CompletionRecord] = []
    ) -> NonNegotiable {
        let createdAt = referenceDate
        let lockStart = DateRules.startOfDay(createdAt, calendar: calendar)
        let windowStart = DateRules.startOfDay(createdAt, calendar: calendar)
        let windowEnd = DateRules.addingDays(13, to: windowStart, calendar: calendar)

        return NonNegotiable(
            id: id,
            goalId: UUID(),
            definition: NonNegotiableDefinition(
                title: title,
                frequencyPerWeek: frequencyPerWeek,
                mode: .session,
                goalId: UUID(),
                preferredExecutionSlot: .none,
                estimatedDurationMinutes: estimatedDurationMinutes,
                iconSystemName: "bolt.fill"
            ),
            state: state,
            lock: LockConfiguration(startDate: lockStart, totalLockDays: 30),
            createdAt: createdAt,
            windows: [
                Window(index: 0, startDate: windowStart, endDate: windowEnd)
            ],
            completions: completions,
            violations: [],
            lastDailyComplianceCheckedDay: nil
        )
    }

    static func makeAllocation(
        id: UUID = UUID(),
        protocolId: UUID,
        day: Date,
        slot: PlanSlot,
        durationMinutes: Int = 60,
        status: PlanAllocationStatus = .active
    ) -> PlanAllocation {
        let dayStart = DateRules.startOfDay(day, calendar: calendar)
        return PlanAllocation(
            id: id,
            protocolId: protocolId,
            weekId: DateRules.weekID(for: dayStart, calendar: calendar),
            day: dayStart,
            slot: slot,
            startTime: nil,
            durationMinutes: durationMinutes,
            createdAt: referenceDate,
            updatedAt: referenceDate,
            status: status
        )
    }
}

enum PlanStoreTestRetainer {
    static var stores: [PlanStore] = []

    static func retain(_ store: PlanStore) {
        stores.append(store)
    }
}
