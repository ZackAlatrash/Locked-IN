import Foundation

@MainActor
func runPlanCompletionReconciliationSimulation() {
    var calendar = DateRules.isoCalendar
    calendar.timeZone = .current

    let reference = DateRules.date(year: 2026, month: 1, day: 7, hour: 10, calendar: calendar)
    let weekId = DateRules.weekID(for: reference, calendar: calendar)

    do {
        let definition = NonNegotiableDefinition(
            title: "Deep Work",
            frequencyPerWeek: 3,
            mode: .session,
            goalId: UUID()
        )
        let nonNegotiableEngine = NonNegotiableEngine(calendar: calendar)
        let protocolModel = try nonNegotiableEngine.create(
            definition: definition,
            startDate: DateRules.startOfDay(reference, calendar: calendar),
            totalLockDays: 28
        )

        let thursday = DateRules.date(year: 2026, month: 1, day: 8, hour: 0, calendar: calendar)
        let friday = DateRules.date(year: 2026, month: 1, day: 9, hour: 0, calendar: calendar)

        let initialAllocations = [
            PlanAllocation(
                id: UUID(),
                protocolId: protocolModel.id,
                weekId: weekId,
                day: thursday,
                slot: .pm,
                startTime: nil,
                durationMinutes: 90,
                createdAt: reference,
                updatedAt: reference
            ),
            PlanAllocation(
                id: UUID(),
                protocolId: protocolModel.id,
                weekId: weekId,
                day: friday,
                slot: .am,
                startTime: nil,
                durationMinutes: 90,
                createdAt: reference,
                updatedAt: reference
            )
        ]

        let repository = InMemoryPlanAllocationRepository(value: initialAllocations)
        let planStore = PlanStore(repository: repository, calendar: calendar)
        let system = CommitmentSystem(nonNegotiables: [protocolModel], createdAt: reference)
        planStore.refresh(system: system, calendarEvents: [], referenceDate: reference)

        let firstOutcome = planStore.reconcileAfterCompletion(
            protocolId: protocolModel.id,
            mode: .session,
            completionDate: reference,
            completionKind: .counted
        )
        switch firstOutcome {
        case .released(let info):
            print("Reconciliation release day: \(info.day) slot: \(info.slot.title) (expected THU PM)")
        case .none:
            print("Reconciliation did not release allocation (unexpected)")
        }

        let afterFirst = planStore.currentWeekSnapshot().currentWeekAllocations.count
        print("Allocations after first reconcile: \(afterFirst) (expected 1)")

        let secondOutcome = planStore.reconcileAfterCompletion(
            protocolId: protocolModel.id,
            mode: .session,
            completionDate: DateRules.date(year: 2026, month: 1, day: 9, hour: 23, minute: 30, calendar: calendar),
            completionKind: .counted
        )
        print("No future allocation outcome: \(secondOutcome) (expected none)")

        let thirdOutcome = planStore.reconcileAfterCompletion(
            protocolId: protocolModel.id,
            mode: .session,
            completionDate: reference,
            completionKind: .extra
        )
        print("Extra completion outcome: \(thirdOutcome) (expected none)")
    } catch {
        print("Plan reconciliation simulation failed with error: \(error)")
    }
}
