import Foundation

struct PlanRegulatorEngine {
    private let calendar: Calendar

    init(calendar: Calendar = DateRules.isoCalendar) {
        self.calendar = calendar
    }

    func regulate(input: PlanRegulationInput) -> PlanDraft {
        let weekStart = DateRules.startOfDay(input.weekStartDate, calendar: calendar)
        let days: [Date] = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
                .map { DateRules.startOfDay($0, calendar: calendar) }
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

        // Pre-compute calendar-blocked slots
        var slotBusyByCalendar: Set<String> = []
        for dayIndex in 0..<days.count {
            for slot in RegulationSlot.allCases {
                if slotHasCalendarConflict(day: days[dayIndex], slot: slot, events: input.calendarEvents) {
                    slotBusyByCalendar.insert(slotKey(dayIndex: dayIndex, slot: slot))
                }
            }
        }

        // Seed tracking state from existing allocations
        var dayProtocolCounts: [Int: Int] = [:]
        var daySlotCounts: [String: Int] = [:]
        var protocolDaySet: Set<String> = []

        for allocation in input.existingAllocations {
            guard let idx = dayIndex(for: allocation.day, weekStart: weekStart) else { continue }
            dayProtocolCounts[idx, default: 0] += 1
            daySlotCounts[slotKey(dayIndex: idx, slot: allocation.slot), default: 0] += 1
            protocolDaySet.insert(protocolDayKey(protocolId: allocation.protocolId, dayIndex: idx))
        }

        // Sort: recovery protocols first (most constrained by isolation penalty),
        // then by remaining sessions descending so high-need protocols don't lose slots.
        let sortedProtocols = input.protocols.sorted { lhs, rhs in
            let lhsRecovery = lhs.state == .recovery ? 1 : 0
            let rhsRecovery = rhs.state == .recovery ? 1 : 0
            if lhsRecovery != rhsRecovery { return lhsRecovery > rhsRecovery }
            let lhsRemaining = remainingSessions(for: lhs)
            let rhsRemaining = remainingSessions(for: rhs)
            if lhsRemaining != rhsRemaining { return lhsRemaining > rhsRemaining }
            return lhs.id.uuidString < rhs.id.uuidString
        }

        let protocolMap: [UUID: ProtocolPlanItem] = Dictionary(
            uniqueKeysWithValues: input.protocols.map { ($0.id, $0) }
        )

        var suggestions: [PlanSuggestion] = []
        var draftAllocations: [PlanAllocationDraft] = []

        // Suspended protocols: warning only, no placement attempt
        for item in sortedProtocols where item.state == .suspended {
            guard remainingSessions(for: item) > 0 else { continue }
            suggestions.append(PlanSuggestion(
                id: UUID(), protocolId: item.id,
                dayIndex: 0, slot: .am,
                startTimeMinutesFromMidnight: nil,
                durationMinutes: item.durationMinutes,
                confidence: 0.10,
                reason: "\(item.title) is suspended and was left unscheduled this week.",
                kind: .warning
            ))
        }

        // Round-robin placement: one session per protocol per pass.
        // This prevents high-session-count protocols from claiming all the best slots
        // before lower-count protocols get a turn.
        struct Pending {
            let item: ProtocolPlanItem
            var remaining: Int
        }

        var pending: [Pending] = sortedProtocols
            .filter { $0.state != .suspended && remainingSessions(for: $0) > 0 }
            .map { Pending(item: $0, remaining: remainingSessions(for: $0)) }

        var madeProgress = true
        while !pending.isEmpty && madeProgress {
            madeProgress = false
            var nextPending: [Pending] = []

            for var entry in pending {
                let candidates = buildCandidates(
                    protocolItem: entry.item,
                    days: days,
                    firstEligibleDayIndex: firstEligibleDayIndex,
                    slotBusyByCalendar: slotBusyByCalendar,
                    dayProtocolCounts: dayProtocolCounts,
                    daySlotCounts: daySlotCounts,
                    protocolDaySet: protocolDaySet,
                    maxPerSlot: input.rules.maxProtocolsPerSlot,
                    rules: input.rules
                )

                if let best = candidates.first {
                    let day = days[best.dayIndex]
                    let slotId = slotKey(dayIndex: best.dayIndex, slot: best.slot)
                    dayProtocolCounts[best.dayIndex, default: 0] += 1
                    daySlotCounts[slotId, default: 0] += 1
                    protocolDaySet.insert(protocolDayKey(protocolId: entry.item.id, dayIndex: best.dayIndex))

                    draftAllocations.append(PlanAllocationDraft(
                        protocolId: entry.item.id,
                        weekId: input.weekId,
                        day: day,
                        slot: best.slot,
                        durationMinutes: entry.item.durationMinutes
                    ))
                    suggestions.append(PlanSuggestion(
                        id: UUID(),
                        protocolId: entry.item.id,
                        dayIndex: best.dayIndex,
                        slot: best.slot,
                        startTimeMinutesFromMidnight: nil,
                        durationMinutes: entry.item.durationMinutes,
                        confidence: normalizeConfidence(best.score),
                        reason: best.reason,
                        kind: .draftCandidate
                    ))

                    madeProgress = true
                    entry.remaining -= 1
                } else {
                    // No slot found for this session this pass — report it
                    suggestions.append(PlanSuggestion(
                        id: UUID(),
                        protocolId: entry.item.id,
                        dayIndex: 0, slot: .am,
                        startTimeMinutesFromMidnight: nil,
                        durationMinutes: entry.item.durationMinutes,
                        confidence: 0.15,
                        reason: "Could not place 1 session — no valid slot remained this week.",
                        kind: .warning
                    ))
                }

                if entry.remaining > 0 {
                    nextPending.append(entry)
                }
            }

            pending = nextPending
        }

        // Sessions still pending after a full pass with no progress are genuinely unplaceable
        for entry in pending {
            let noun = entry.remaining == 1 ? "session" : "sessions"
            suggestions.append(PlanSuggestion(
                id: UUID(),
                protocolId: entry.item.id,
                dayIndex: 0, slot: .am,
                startTimeMinutesFromMidnight: nil,
                durationMinutes: entry.item.durationMinutes,
                confidence: 0.15,
                reason: "Could not place \(entry.remaining) remaining \(noun) — no valid slots remain this week.",
                kind: .warning
            ))
        }

        // Second pass: pairwise swap optimisation to improve the greedy arrangement
        optimizeWithSwaps(
            drafts: &draftAllocations,
            suggestions: &suggestions,
            protocolMap: protocolMap,
            days: days,
            slotBusyByCalendar: slotBusyByCalendar,
            dayProtocolCounts: &dayProtocolCounts,
            daySlotCounts: &daySlotCounts,
            protocolDaySet: &protocolDaySet,
            maxPerSlot: input.rules.maxProtocolsPerSlot,
            rules: input.rules
        )

        return PlanDraft(suggestedAllocations: draftAllocations, suggestions: suggestions)
    }
}

private extension PlanRegulatorEngine {

    struct Candidate {
        let dayIndex: Int
        let slot: RegulationSlot
        let score: Double
        let reason: String
    }

    // MARK: - Scoring

    /// Scores a (protocol, day, slot) triple. Higher is better. No hard constraints here —
    /// only preference alignment and load signals expressed as continuous values.
    func candidateScore(
        protocolItem: ProtocolPlanItem,
        dayIndex: Int,
        slot: RegulationSlot,
        dayProtocolCounts: [Int: Int],
        rules: PlanRegulationRules
    ) -> Double {
        // Preference: 1.0 if matches, 0.5 if no preference, 0.0 if mismatch
        let preferenceScore: Double
        switch protocolItem.timePreference {
        case .none: preferenceScore = 0.5
        default: preferenceScore = protocolItem.timePreference.matches(slot: slot) ? 1.0 : 0.0
        }

        // Urgency: slight preference for earlier days in the week
        let urgencyScore = 1.0 - Double(dayIndex) / 6.0

        // Spread: strongly prefer days with fewer sessions already — normalised against
        // a threshold of 3 (a day with 3+ sessions is considered full for spreading purposes)
        let dayCount = Double(dayProtocolCounts[dayIndex, default: 0])
        let spreadScore = max(0.0, 1.0 - dayCount / 3.0)

        // Recovery isolation: strongly discourage placing a recovery protocol on a day
        // that already has other sessions. Scoped only to the recovery protocol itself —
        // active protocols are unaffected.
        let recoveryPenalty: Double = (protocolItem.state == .recovery && dayProtocolCounts[dayIndex, default: 0] > 0)
            ? 3.0 : 0.0

        return (rules.preferenceWeight * preferenceScore)
             + (rules.avoidClumpingWeight * spreadScore)
             + (rules.urgencyWeight * urgencyScore)
             - recoveryPenalty
    }

    // MARK: - Candidate Generation

    func buildCandidates(
        protocolItem: ProtocolPlanItem,
        days: [Date],
        firstEligibleDayIndex: Int,
        slotBusyByCalendar: Set<String>,
        dayProtocolCounts: [Int: Int],
        daySlotCounts: [String: Int],
        protocolDaySet: Set<String>,
        maxPerSlot: Int,
        rules: PlanRegulationRules
    ) -> [Candidate] {
        guard firstEligibleDayIndex < days.count else { return [] }

        var candidates: [Candidate] = []

        for dayIndex in firstEligibleDayIndex..<days.count {
            // Hard: same protocol cannot appear twice on the same day
            if protocolDaySet.contains(protocolDayKey(protocolId: protocolItem.id, dayIndex: dayIndex)) { continue }

            for slot in RegulationSlot.allCases {
                let slotId = slotKey(dayIndex: dayIndex, slot: slot)
                // Hard: slot has a calendar conflict
                if slotBusyByCalendar.contains(slotId) { continue }
                // Hard: slot is already at capacity
                if daySlotCounts[slotId, default: 0] >= maxPerSlot { continue }

                let score = candidateScore(
                    protocolItem: protocolItem,
                    dayIndex: dayIndex,
                    slot: slot,
                    dayProtocolCounts: dayProtocolCounts,
                    rules: rules
                )

                candidates.append(Candidate(
                    dayIndex: dayIndex,
                    slot: slot,
                    score: score,
                    reason: buildReason(
                        protocolItem: protocolItem,
                        dayIndex: dayIndex,
                        slot: slot,
                        firstEligibleDayIndex: firstEligibleDayIndex,
                        dayProtocolCounts: dayProtocolCounts
                    )
                ))
            }
        }

        return candidates.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            if lhs.dayIndex != rhs.dayIndex { return lhs.dayIndex < rhs.dayIndex }
            return slotSortOrder(lhs.slot) < slotSortOrder(rhs.slot)
        }
    }

    func buildReason(
        protocolItem: ProtocolPlanItem,
        dayIndex: Int,
        slot: RegulationSlot,
        firstEligibleDayIndex: Int,
        dayProtocolCounts: [Int: Int]
    ) -> String {
        if protocolItem.state == .recovery {
            return "Placed on a lighter day to respect recovery — kept separate from other sessions."
        }
        if protocolItem.timePreference != .none && protocolItem.timePreference.matches(slot: slot) {
            return "Matched your preferred \(slot.title) window."
        }
        if dayProtocolCounts[dayIndex, default: 0] == 0 {
            return "Spread onto a free day to keep the week balanced."
        }
        if dayIndex > firstEligibleDayIndex {
            return "Placed later in the week to avoid front-loading."
        }
        return "Placed in the best available slot to keep the week balanced."
    }

    // MARK: - Swap Optimisation Pass

    @discardableResult
    func optimizeWithSwaps(
        drafts: inout [PlanAllocationDraft],
        suggestions: inout [PlanSuggestion],
        protocolMap: [UUID: ProtocolPlanItem],
        days: [Date],
        slotBusyByCalendar: Set<String>,
        dayProtocolCounts: inout [Int: Int],
        daySlotCounts: inout [String: Int],
        protocolDaySet: inout Set<String>,
        maxPerSlot: Int,
        rules: PlanRegulationRules
    ) -> Bool {
        guard drafts.count >= 2, let weekStart = days.first else { return false }

        var anySwapped = false
        var draftDayIndices: [Int] = drafts.map { dayIndex(for: $0.day, weekStart: weekStart) ?? 0 }

        for i in 0..<drafts.count {
            for j in (i + 1)..<drafts.count {
                let draftA = drafts[i], draftB = drafts[j]
                let dayA = draftDayIndices[i], dayB = draftDayIndices[j]
                let slotA = draftA.slot, slotB = draftB.slot

                if dayA == dayB && slotA == slotB { continue }

                guard let protocolA = protocolMap[draftA.protocolId],
                      let protocolB = protocolMap[draftB.protocolId] else { continue }

                let currentScore =
                    candidateScore(protocolItem: protocolA, dayIndex: dayA, slot: slotA, dayProtocolCounts: dayProtocolCounts, rules: rules) +
                    candidateScore(protocolItem: protocolB, dayIndex: dayB, slot: slotB, dayProtocolCounts: dayProtocolCounts, rules: rules)

                // Temporarily unregister both allocations
                dayProtocolCounts[dayA, default: 1] -= 1
                dayProtocolCounts[dayB, default: 1] -= 1
                daySlotCounts[slotKey(dayIndex: dayA, slot: slotA), default: 1] -= 1
                daySlotCounts[slotKey(dayIndex: dayB, slot: slotB), default: 1] -= 1
                protocolDaySet.remove(protocolDayKey(protocolId: protocolA.id, dayIndex: dayA))
                protocolDaySet.remove(protocolDayKey(protocolId: protocolB.id, dayIndex: dayB))

                let slotAKey = slotKey(dayIndex: dayA, slot: slotA)
                let slotBKey = slotKey(dayIndex: dayB, slot: slotB)

                let aAtBValid = !slotBusyByCalendar.contains(slotBKey)
                    && daySlotCounts[slotBKey, default: 0] < maxPerSlot
                    && !protocolDaySet.contains(protocolDayKey(protocolId: protocolA.id, dayIndex: dayB))

                let bAtAValid = !slotBusyByCalendar.contains(slotAKey)
                    && daySlotCounts[slotAKey, default: 0] < maxPerSlot
                    && !protocolDaySet.contains(protocolDayKey(protocolId: protocolB.id, dayIndex: dayA))

                let shouldSwap: Bool
                if aAtBValid && bAtAValid {
                    let swappedScore =
                        candidateScore(protocolItem: protocolA, dayIndex: dayB, slot: slotB, dayProtocolCounts: dayProtocolCounts, rules: rules) +
                        candidateScore(protocolItem: protocolB, dayIndex: dayA, slot: slotA, dayProtocolCounts: dayProtocolCounts, rules: rules)
                    shouldSwap = swappedScore > currentScore
                } else {
                    shouldSwap = false
                }

                if shouldSwap {
                    dayProtocolCounts[dayB, default: 0] += 1
                    dayProtocolCounts[dayA, default: 0] += 1
                    daySlotCounts[slotBKey, default: 0] += 1
                    daySlotCounts[slotAKey, default: 0] += 1
                    protocolDaySet.insert(protocolDayKey(protocolId: protocolA.id, dayIndex: dayB))
                    protocolDaySet.insert(protocolDayKey(protocolId: protocolB.id, dayIndex: dayA))

                    drafts[i] = PlanAllocationDraft(protocolId: draftA.protocolId, weekId: draftA.weekId, day: days[dayB], slot: slotB, durationMinutes: draftA.durationMinutes)
                    drafts[j] = PlanAllocationDraft(protocolId: draftB.protocolId, weekId: draftB.weekId, day: days[dayA], slot: slotA, durationMinutes: draftB.durationMinutes)
                    draftDayIndices[i] = dayB
                    draftDayIndices[j] = dayA

                    updateSwappedSuggestion(&suggestions, protocolId: protocolA.id, oldDayIndex: dayA, oldSlot: slotA, newDayIndex: dayB, newSlot: slotB, protocolItem: protocolA, dayProtocolCounts: dayProtocolCounts, rules: rules)
                    updateSwappedSuggestion(&suggestions, protocolId: protocolB.id, oldDayIndex: dayB, oldSlot: slotB, newDayIndex: dayA, newSlot: slotA, protocolItem: protocolB, dayProtocolCounts: dayProtocolCounts, rules: rules)

                    anySwapped = true
                } else {
                    // Restore original positions
                    dayProtocolCounts[dayA, default: 0] += 1
                    dayProtocolCounts[dayB, default: 0] += 1
                    daySlotCounts[slotAKey, default: 0] += 1
                    daySlotCounts[slotBKey, default: 0] += 1
                    protocolDaySet.insert(protocolDayKey(protocolId: protocolA.id, dayIndex: dayA))
                    protocolDaySet.insert(protocolDayKey(protocolId: protocolB.id, dayIndex: dayB))
                }
            }
        }

        return anySwapped
    }

    func updateSwappedSuggestion(
        _ suggestions: inout [PlanSuggestion],
        protocolId: UUID,
        oldDayIndex: Int,
        oldSlot: RegulationSlot,
        newDayIndex: Int,
        newSlot: RegulationSlot,
        protocolItem: ProtocolPlanItem,
        dayProtocolCounts: [Int: Int],
        rules: PlanRegulationRules
    ) {
        guard let idx = suggestions.firstIndex(where: {
            $0.protocolId == protocolId && $0.dayIndex == oldDayIndex && $0.slot == oldSlot && $0.kind == .draftCandidate
        }) else { return }

        let newScore = candidateScore(
            protocolItem: protocolItem, dayIndex: newDayIndex, slot: newSlot,
            dayProtocolCounts: dayProtocolCounts, rules: rules
        )
        let reason = (protocolItem.timePreference != .none && protocolItem.timePreference.matches(slot: newSlot))
            ? "Moved to \(newSlot.title) to better match your time preference after optimising the full week."
            : "Repositioned to reduce daily load imbalance after optimising the full week arrangement."

        let existing = suggestions[idx]
        suggestions[idx] = PlanSuggestion(
            id: existing.id, protocolId: existing.protocolId,
            dayIndex: newDayIndex, slot: newSlot,
            startTimeMinutesFromMidnight: existing.startTimeMinutesFromMidnight,
            durationMinutes: existing.durationMinutes,
            confidence: normalizeConfidence(newScore),
            reason: reason, kind: .draftCandidate
        )
    }

    // MARK: - Helpers

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
            guard !event.isAllDay else { return false }
            return DateInterval(start: event.startDateTime, end: event.endDateTime).intersects(slotInterval)
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

    func slotKey(dayIndex: Int, slot: RegulationSlot) -> String { "\(dayIndex)|\(slot.rawValue)" }
    func protocolDayKey(protocolId: UUID, dayIndex: Int) -> String { "\(protocolId.uuidString)|\(dayIndex)" }

    func normalizeConfidence(_ rawScore: Double) -> Double {
        // Score range: -3.0 (recovery penalty, worst) to 2.8 (all preferences matched, free day, early week)
        let normalized = (rawScore - (-3.0)) / (2.8 - (-3.0))
        return max(0.05, min(0.99, normalized))
    }
}
