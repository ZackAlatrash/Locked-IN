import Foundation

struct PlanRegulatorEngine {
    private let calendar: Calendar

    init(calendar: Calendar = DateRules.isoCalendar) {
        self.calendar = calendar
    }

    func regulate(input: PlanRegulationInput) -> PlanDraft {
        let weekStart = DateRules.startOfDay(input.weekStartDate, calendar: calendar)
        let days: [Date] = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart).map { DateRules.startOfDay($0, calendar: calendar) }
        }
        let todayStart = DateRules.startOfDay(Date(), calendar: calendar)
        let dayDeltaFromWeekStart = calendar.dateComponents([.day], from: weekStart, to: todayStart).day ?? 0
        let firstEligibleDayIndex: Int
        if dayDeltaFromWeekStart <= 0 {
            firstEligibleDayIndex = 0
        } else if dayDeltaFromWeekStart >= days.count {
            firstEligibleDayIndex = days.count
        } else {
            firstEligibleDayIndex = dayDeltaFromWeekStart
        }

        var suggestions: [PlanSuggestion] = []
        var draftAllocations: [PlanAllocationDraft] = []

        let hasRecovery = input.protocols.contains(where: { $0.state == .recovery })
        let maxPerDay = hasRecovery ? min(input.rules.maxProtocolsPerDay, 1) : input.rules.maxProtocolsPerDay
        let maxPerSlot = input.rules.maxProtocolsPerSlot

        var slotBusyByCalendar: Set<String> = []
        for dayIndex in 0..<days.count {
            let day = days[dayIndex]
            for slot in RegulationSlot.allCases {
                if slotHasCalendarConflict(day: day, slot: slot, events: input.calendarEvents) {
                    slotBusyByCalendar.insert(slotKey(dayIndex: dayIndex, slot: slot))
                }
            }
        }

        var dayProtocolCounts: [Int: Int] = [:]
        var daySlotCounts: [String: Int] = [:]
        var protocolDaySet: Set<String> = []

        for allocation in input.existingAllocations {
            guard let dayIndex = dayIndex(for: allocation.day, weekStart: weekStart) else { continue }
            dayProtocolCounts[dayIndex, default: 0] += 1
            daySlotCounts[slotKey(dayIndex: dayIndex, slot: allocation.slot), default: 0] += 1
            protocolDaySet.insert(protocolDayKey(protocolId: allocation.protocolId, dayIndex: dayIndex))
        }

        let sortedProtocols = input.protocols.sorted { lhs, rhs in
            let lhsRemaining = remainingSessions(for: lhs)
            let rhsRemaining = remainingSessions(for: rhs)
            if lhsRemaining != rhsRemaining { return lhsRemaining > rhsRemaining }
            return lhs.id.uuidString < rhs.id.uuidString
        }

        var placementFailed = false
        for protocolItem in sortedProtocols {
            let remaining = remainingSessions(for: protocolItem)
            guard remaining > 0 else { continue }

            if protocolItem.state == .suspended {
                suggestions.append(
                    PlanSuggestion(
                        id: UUID(),
                        protocolId: protocolItem.id,
                        dayIndex: 0,
                        slot: .am,
                        startTimeMinutesFromMidnight: nil,
                        durationMinutes: protocolItem.durationMinutes,
                        confidence: 0.10,
                        reason: "\(protocolItem.title) is suspended and cannot be placed.",
                        kind: .warning
                    )
                )
                continue
            }

            var sessionsLeft = remaining
            while sessionsLeft > 0 {
                let candidates = buildCandidates(
                    protocolItem: protocolItem,
                    days: days,
                    firstEligibleDayIndex: firstEligibleDayIndex,
                    slotBusyByCalendar: slotBusyByCalendar,
                    dayProtocolCounts: dayProtocolCounts,
                    daySlotCounts: daySlotCounts,
                    protocolDaySet: protocolDaySet,
                    maxPerDay: maxPerDay,
                    maxPerSlot: maxPerSlot,
                    rules: input.rules
                )

                guard let selected = candidates.first else {
                    placementFailed = true
                    suggestions.append(
                        PlanSuggestion(
                            id: UUID(),
                            protocolId: protocolItem.id,
                            dayIndex: 0,
                            slot: .am,
                            startTimeMinutesFromMidnight: nil,
                            durationMinutes: protocolItem.durationMinutes,
                            confidence: 0.15,
                            reason: "No gaps available - free a slot or reduce load.",
                            kind: .warning
                        )
                    )
                    break
                }

                let day = days[selected.dayIndex]
                let slotId = slotKey(dayIndex: selected.dayIndex, slot: selected.slot)
                dayProtocolCounts[selected.dayIndex, default: 0] += 1
                daySlotCounts[slotId, default: 0] += 1
                protocolDaySet.insert(protocolDayKey(protocolId: protocolItem.id, dayIndex: selected.dayIndex))

                draftAllocations.append(
                    PlanAllocationDraft(
                        protocolId: protocolItem.id,
                        weekId: input.weekId,
                        day: day,
                        slot: selected.slot,
                        durationMinutes: protocolItem.durationMinutes
                    )
                )

                suggestions.append(
                    PlanSuggestion(
                        id: UUID(),
                        protocolId: protocolItem.id,
                        dayIndex: selected.dayIndex,
                        slot: selected.slot,
                        startTimeMinutesFromMidnight: nil,
                        durationMinutes: protocolItem.durationMinutes,
                        confidence: normalizeConfidence(selected.score),
                        reason: selected.reason,
                        kind: .draftCandidate
                    )
                )

                sessionsLeft -= 1
            }
        }

        if draftAllocations.isEmpty && placementFailed {
            suggestions.append(
                PlanSuggestion(
                    id: UUID(),
                    protocolId: UUID(),
                    dayIndex: 0,
                    slot: .am,
                    startTimeMinutesFromMidnight: nil,
                    durationMinutes: 0,
                    confidence: 0.10,
                    reason: "No gaps available - free a slot or reduce load.",
                    kind: .warning
                )
            )
        }

        return PlanDraft(
            suggestedAllocations: draftAllocations,
            suggestions: suggestions
        )
    }
}

private extension PlanRegulatorEngine {
    struct Candidate {
        let dayIndex: Int
        let slot: RegulationSlot
        let score: Double
        let reason: String
    }

    func buildCandidates(
        protocolItem: ProtocolPlanItem,
        days: [Date],
        firstEligibleDayIndex: Int,
        slotBusyByCalendar: Set<String>,
        dayProtocolCounts: [Int: Int],
        daySlotCounts: [String: Int],
        protocolDaySet: Set<String>,
        maxPerDay: Int,
        maxPerSlot: Int,
        rules: PlanRegulationRules
    ) -> [Candidate] {
        var candidates: [Candidate] = []

        guard firstEligibleDayIndex < days.count else { return [] }

        for dayIndex in firstEligibleDayIndex..<days.count {
            let dayLoad = dayProtocolCounts[dayIndex, default: 0]
            if dayLoad >= maxPerDay { continue }
            if protocolDaySet.contains(protocolDayKey(protocolId: protocolItem.id, dayIndex: dayIndex)) { continue }

            for slot in RegulationSlot.allCases {
                let slotId = slotKey(dayIndex: dayIndex, slot: slot)
                if slotBusyByCalendar.contains(slotId) { continue }
                if daySlotCounts[slotId, default: 0] >= maxPerSlot { continue }

                let preferenceScore: Double
                if protocolItem.timePreference == .none {
                    preferenceScore = 0.5
                } else {
                    preferenceScore = protocolItem.timePreference.matches(slot: slot) ? 1.0 : 0.0
                }

                let urgencyScore = Double(dayIndex) / 6.0
                let clumpPenalty = Double(dayLoad)

                let totalScore =
                    (rules.preferenceWeight * preferenceScore) +
                    (rules.urgencyWeight * urgencyScore) -
                    (rules.avoidClumpingWeight * clumpPenalty)

                let reason = "Best fit: \(slot.title), day load \(dayLoad), urgency +\(String(format: "%.2f", urgencyScore))."
                candidates.append(
                    Candidate(
                        dayIndex: dayIndex,
                        slot: slot,
                        score: totalScore,
                        reason: reason
                    )
                )
            }
        }

        return candidates.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            if lhs.dayIndex != rhs.dayIndex { return lhs.dayIndex < rhs.dayIndex }
            return slotSortOrder(lhs.slot) < slotSortOrder(rhs.slot)
        }
    }

    func remainingSessions(for item: ProtocolPlanItem) -> Int {
        switch item.mode {
        case .session:
            return max(0, item.frequencyPerWeek - item.completionsThisWeek - item.plannedThisWeek)
        case .daily:
            return max(0, 7 - item.completionsThisWeek - item.plannedThisWeek)
        }
    }

    func slotHasCalendarConflict(day: Date, slot: RegulationSlot, events: [RegulationCalendarEvent]) -> Bool {
        guard let slotInterval = slot.interval(on: day, calendar: calendar) else { return false }

        return events.contains { event in
            guard event.isAllDay == false else { return true }
            let eventInterval = DateInterval(start: event.startDateTime, end: event.endDateTime)
            return eventInterval.intersects(slotInterval)
        }
    }

    func dayIndex(for date: Date, weekStart: Date) -> Int? {
        let start = DateRules.startOfDay(date, calendar: calendar)
        let delta = calendar.dateComponents([.day], from: weekStart, to: start).day ?? 0
        guard (0...6).contains(delta) else { return nil }
        return delta
    }

    func slotSortOrder(_ slot: RegulationSlot) -> Int {
        switch slot {
        case .am: return 0
        case .pm: return 1
        case .eve: return 2
        }
    }

    func slotKey(dayIndex: Int, slot: RegulationSlot) -> String {
        "\(dayIndex)|\(slot.rawValue)"
    }

    func protocolDayKey(protocolId: UUID, dayIndex: Int) -> String {
        "\(protocolId.uuidString)|\(dayIndex)"
    }

    func normalizeConfidence(_ rawScore: Double) -> Double {
        let minScore = -2.5
        let maxScore = 3.0
        if maxScore <= minScore { return 0.5 }
        let normalized = (rawScore - minScore) / (maxScore - minScore)
        return max(0.05, min(0.99, normalized))
    }
}
