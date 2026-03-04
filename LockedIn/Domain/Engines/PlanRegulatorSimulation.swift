import Foundation

func runPlanRegulatorSimulation() {
    let calendar = DateRules.isoCalendar
    let weekStart = DateRules.date(year: 2026, month: 3, day: 2, hour: 0, calendar: calendar)
    let weekId = DateRules.weekID(for: weekStart, calendar: calendar)

    let protocols: [ProtocolPlanItem] = [
        ProtocolPlanItem(
            id: UUID(),
            title: "Deep Work",
            mode: .session,
            state: .active,
            frequencyPerWeek: 3,
            completionsThisWeek: 0,
            plannedThisWeek: 0,
            durationMinutes: 60,
            timePreference: .am
        ),
        ProtocolPlanItem(
            id: UUID(),
            title: "Neural Drill",
            mode: .session,
            state: .recovery,
            frequencyPerWeek: 2,
            completionsThisWeek: 0,
            plannedThisWeek: 0,
            durationMinutes: 60,
            timePreference: .none
        ),
        ProtocolPlanItem(
            id: UUID(),
            title: "Suspended",
            mode: .session,
            state: .suspended,
            frequencyPerWeek: 2,
            completionsThisWeek: 0,
            plannedThisWeek: 0,
            durationMinutes: 60,
            timePreference: .pm
        )
    ]

    let events: [RegulationCalendarEvent] = [
        RegulationCalendarEvent(
            id: UUID(),
            startDateTime: DateRules.date(year: 2026, month: 3, day: 2, hour: 8, calendar: calendar),
            endDateTime: DateRules.date(year: 2026, month: 3, day: 2, hour: 10, calendar: calendar),
            isAllDay: false
        )
    ]

    let input = PlanRegulationInput(
        weekId: weekId,
        weekStartDate: weekStart,
        protocols: protocols,
        calendarEvents: events,
        existingAllocations: [],
        rules: PlanRegulationRules()
    )

    let engine = PlanRegulatorEngine(calendar: calendar)
    let draft = engine.regulate(input: input)
    let warningCount = draft.suggestions.filter { $0.kind == .warning }.count

    print("PlanRegulator simulation draft allocations: \(draft.suggestedAllocations.count)")
    print("PlanRegulator simulation warnings: \(warningCount)")
}
