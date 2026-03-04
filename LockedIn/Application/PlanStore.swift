import Foundation
import Combine

struct PlanWeekSnapshot {
    let weekId: WeekID
    let weekStartDate: Date
    let weekInterval: DateInterval
    let currentWeekAllocations: [PlanAllocation]
    let calendarEvents: [PlanCalendarEvent]
}

enum PlanValidationContext {
    case manual
    case regulator
}

enum PlanDraftApplyError: Error, LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let message):
            return message
        }
    }
}

@MainActor
final class PlanStore: ObservableObject {
    @Published private(set) var currentWeekDays: [PlanDayModel] = []
    @Published private(set) var queueItems: [PlanQueueItem] = []
    @Published private(set) var selectedQueueProtocolId: UUID?
    @Published private(set) var todaySummary: PlanTodaySummary = .empty
    @Published private(set) var structureStatus: PlanStructureStatus = .unstructured
    @Published private(set) var structureMessage: String = "No plan allocations for this week."
    @Published private(set) var warningMessage: String?
    @Published private(set) var hasTrackableProtocols = false
    @Published private(set) var planSignal: PlanStructureStatus = .unstructured
    @Published private(set) var planSignalMessage: String = "No plan allocations for this week."

    private let repository: PlanAllocationRepository
    private let calendar: Calendar

    private var allAllocations: [PlanAllocation] = []
    private var weekAllocations: [PlanAllocation] = []
    private var sourceCalendarEvents: [PlanCalendarEvent] = []
    private var calendarEvents: [PlanCalendarEvent] = []
    private var protocolsById: [UUID: PlanProtocolDescriptor] = [:]
    private var weekInterval: DateInterval = DateRules.weekInterval(containing: Date())
    private var weekId: WeekID = DateRules.weekID(for: Date())
    private var lastReferenceDate: Date = Date()
    private var lastSystem: CommitmentSystem?

    init(
        repository: PlanAllocationRepository = JSONFilePlanAllocationRepository(),
        calendar: Calendar = DateRules.isoCalendar
    ) {
        self.repository = repository
        self.calendar = calendar

        do {
            self.allAllocations = try repository.load()
        } catch {
            self.allAllocations = []
        }
    }

    var weekSubtitle: String {
        "CYCLE 04 • \(weekId.description)"
    }

    func protocolTitle(for id: UUID) -> String {
        protocolsById[id]?.title ?? "Protocol"
    }

    func allocation(id: UUID) -> PlanAllocation? {
        allAllocations.first(where: { $0.id == id })
    }

    func currentWeekSnapshot() -> PlanWeekSnapshot {
        PlanWeekSnapshot(
            weekId: weekId,
            weekStartDate: DateRules.startOfDay(weekInterval.start, calendar: calendar),
            weekInterval: weekInterval,
            currentWeekAllocations: weekAllocations,
            calendarEvents: calendarEvents
        )
    }

    func validateProtocolPlacement(
        protocolId: UUID,
        day: Date,
        slot: PlanSlot,
        context: PlanValidationContext = .manual
    ) -> PlanPlacementValidation {
        guard let descriptor = protocolsById[protocolId] else {
            return .blocked(message: "Protocol is no longer available.")
        }

        return validatePlacement(
            descriptor: descriptor,
            protocolId: protocolId,
            day: day,
            slot: slot,
            requiredMinutes: descriptor.estimatedDurationMinutes,
            excludingAllocationId: nil,
            requiresQueueAvailability: true,
            context: context,
            candidateAllocations: weekAllocations
        )
    }

    func validateMove(allocationId: UUID, day: Date, slot: PlanSlot) -> PlanPlacementValidation {
        guard let allocation = allAllocations.first(where: { $0.id == allocationId }) else {
            return .blocked(message: "Allocation no longer exists.")
        }

        guard let descriptor = protocolsById[allocation.protocolId] else {
            return .blocked(message: "Protocol is no longer available.")
        }

        let duration = allocation.durationMinutes ?? descriptor.estimatedDurationMinutes
        return validatePlacement(
            descriptor: descriptor,
            protocolId: allocation.protocolId,
            day: day,
            slot: slot,
            requiredMinutes: duration,
            excludingAllocationId: allocationId,
            requiresQueueAvailability: false,
            context: .manual,
            candidateAllocations: weekAllocations
        )
    }

    func selectProtocol(_ id: UUID?) {
        if selectedQueueProtocolId == id {
            selectedQueueProtocolId = nil
        } else {
            selectedQueueProtocolId = id
        }
    }

    func clearWarning() {
        warningMessage = nil
    }

    func refresh(system: CommitmentSystem, calendarEvents: [PlanCalendarEvent], referenceDate: Date = Date()) {
        lastSystem = system
        lastReferenceDate = referenceDate
        weekInterval = DateRules.weekInterval(containing: referenceDate, calendar: calendar)
        weekId = DateRules.weekID(for: referenceDate, calendar: calendar)

        sourceCalendarEvents = calendarEvents
        self.calendarEvents = calendarEvents.filter { event in
            event.endDateTime > weekInterval.start && event.startDateTime < weekInterval.end
        }

        buildProtocolDescriptors(from: system, referenceDate: referenceDate)
        normalizeAllocations()
        buildQueue(referenceDate: referenceDate)
        buildWeekDays(referenceDate: referenceDate)
        buildTodaySummary(referenceDate: referenceDate)
        buildStructureStatus()

        if let selectedQueueProtocolId,
           queueItems.contains(where: { $0.protocolId == selectedQueueProtocolId }) == false {
            self.selectedQueueProtocolId = nil
        }
    }

    @discardableResult
    func placeSelectedProtocol(day: Date, slot: PlanSlot) -> PlanMutation? {
        guard let selectedQueueProtocolId else {
            setWarning("Select a protocol first.")
            return nil
        }
        return placeProtocol(protocolId: selectedQueueProtocolId, day: day, slot: slot)
    }

    @discardableResult
    func placeProtocol(protocolId: UUID, day: Date, slot: PlanSlot) -> PlanMutation? {
        guard let descriptor = protocolsById[protocolId] else {
            setWarning("Protocol is no longer available.")
            return nil
        }

        let validation = validatePlacement(
            descriptor: descriptor,
            protocolId: protocolId,
            day: day,
            slot: slot,
            requiredMinutes: descriptor.estimatedDurationMinutes,
            excludingAllocationId: nil,
            requiresQueueAvailability: true,
            context: .manual,
            candidateAllocations: weekAllocations
        )
        if case .blocked(let message) = validation {
            setWarning(message)
            return nil
        }

        let dayStart = DateRules.startOfDay(day, calendar: calendar)
        let allocation = PlanAllocation(
            id: UUID(),
            protocolId: protocolId,
            weekId: DateRules.weekID(for: dayStart, calendar: calendar),
            day: dayStart,
            slot: slot,
            startTime: nil,
            durationMinutes: descriptor.estimatedDurationMinutes,
            createdAt: Date(),
            updatedAt: Date()
        )

        allAllocations.append(allocation)
        saveAndRefresh()
        return .placed(
            allocationId: allocation.id,
            protocolTitle: descriptor.title,
            day: dayStart,
            slot: slot
        )
    }

    @discardableResult
    func moveAllocation(id: UUID, newDay: Date, newSlot: PlanSlot) -> PlanMutation? {
        guard let index = allAllocations.firstIndex(where: { $0.id == id }) else { return nil }
        let allocation = allAllocations[index]

        guard let descriptor = protocolsById[allocation.protocolId] else {
            setWarning("Protocol is no longer available.")
            return nil
        }

        let newDayStart = DateRules.startOfDay(newDay, calendar: calendar)
        let duration = allocation.durationMinutes ?? descriptor.estimatedDurationMinutes
        let validation = validatePlacement(
            descriptor: descriptor,
            protocolId: allocation.protocolId,
            day: newDayStart,
            slot: newSlot,
            requiredMinutes: duration,
            excludingAllocationId: id,
            requiresQueueAvailability: false,
            context: .manual,
            candidateAllocations: weekAllocations
        )
        if case .blocked(let message) = validation {
            setWarning(message)
            return nil
        }

        let previousDay = allocation.day
        let previousSlot = allocation.slot
        allAllocations[index] = PlanAllocation(
            id: allocation.id,
            protocolId: allocation.protocolId,
            weekId: DateRules.weekID(for: newDayStart, calendar: calendar),
            day: newDayStart,
            slot: newSlot,
            startTime: allocation.startTime,
            durationMinutes: duration,
            createdAt: allocation.createdAt,
            updatedAt: Date()
        )

        saveAndRefresh()
        return .moved(
            allocationId: allocation.id,
            protocolTitle: descriptor.title,
            fromDay: previousDay,
            fromSlot: previousSlot,
            toDay: newDayStart,
            toSlot: newSlot
        )
    }

    func removeAllocation(id: UUID) {
        allAllocations.removeAll(where: { $0.id == id })
        saveAndRefresh()
    }

    func clearAllAllocations() {
        allAllocations = []
        do {
            try repository.save([])
        } catch {
            setWarning("Could not clear saved plan data.")
        }
        refreshWithLastContext()
    }

    func validateDraft(_ draft: [PlanAllocationDraft]) -> [PlanSuggestion] {
        guard draft.isEmpty == false else { return [] }

        var warnings: [PlanSuggestion] = []
        var simulated = weekAllocations

        for item in draft {
            guard let descriptor = protocolsById[item.protocolId] else {
                warnings.append(
                    PlanSuggestion(
                        id: UUID(),
                        protocolId: item.protocolId,
                        dayIndex: dayIndex(for: item.day) ?? 0,
                        slot: item.slot,
                        startTimeMinutesFromMidnight: nil,
                        durationMinutes: item.durationMinutes,
                        confidence: 0.1,
                        reason: "Protocol is no longer available.",
                        kind: .warning
                    )
                )
                continue
            }

            let validation = validatePlacement(
                descriptor: descriptor,
                protocolId: item.protocolId,
                day: item.day,
                slot: planSlot(for: item.slot),
                requiredMinutes: item.durationMinutes,
                excludingAllocationId: nil,
                requiresQueueAvailability: false,
                context: .regulator,
                candidateAllocations: simulated
            )

            if case .blocked(let reason) = validation {
                warnings.append(
                    PlanSuggestion(
                        id: UUID(),
                        protocolId: item.protocolId,
                        dayIndex: dayIndex(for: item.day) ?? 0,
                        slot: item.slot,
                        startTimeMinutesFromMidnight: nil,
                        durationMinutes: item.durationMinutes,
                        confidence: 0.15,
                        reason: reason,
                        kind: .warning
                    )
                )
                continue
            }

            simulated.append(
                PlanAllocation(
                    id: UUID(),
                    protocolId: item.protocolId,
                    weekId: item.weekId,
                    day: DateRules.startOfDay(item.day, calendar: calendar),
                    slot: planSlot(for: item.slot),
                    startTime: nil,
                    durationMinutes: item.durationMinutes,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            )
        }

        return warnings
    }

    func applyDraft(_ draft: [PlanAllocationDraft]) -> Result<Int, PlanDraftApplyError> {
        guard draft.isEmpty == false else {
            return .failure(.message("No draft allocations to apply."))
        }

        let warnings = validateDraft(draft)
        if let firstWarning = warnings.first {
            setWarning(firstWarning.reason)
            return .failure(.message(firstWarning.reason))
        }

        var simulated = weekAllocations
        var newAllocations: [PlanAllocation] = []
        let now = Date()

        for item in draft {
            guard let descriptor = protocolsById[item.protocolId] else {
                let message = "Protocol is no longer available."
                setWarning(message)
                return .failure(.message(message))
            }

            let validation = validatePlacement(
                descriptor: descriptor,
                protocolId: item.protocolId,
                day: item.day,
                slot: planSlot(for: item.slot),
                requiredMinutes: item.durationMinutes,
                excludingAllocationId: nil,
                requiresQueueAvailability: false,
                context: .regulator,
                candidateAllocations: simulated
            )

            if case .blocked(let reason) = validation {
                setWarning(reason)
                return .failure(.message(reason))
            }

            let allocation = PlanAllocation(
                id: UUID(),
                protocolId: item.protocolId,
                weekId: item.weekId,
                day: DateRules.startOfDay(item.day, calendar: calendar),
                slot: planSlot(for: item.slot),
                startTime: nil,
                durationMinutes: item.durationMinutes,
                createdAt: now,
                updatedAt: now
            )
            simulated.append(allocation)
            newAllocations.append(allocation)
        }

        let updatedAllAllocations = allAllocations + newAllocations
        do {
            try repository.save(updatedAllAllocations)
        } catch {
            let message = "Could not persist draft plan."
            setWarning(message)
            return .failure(.message(message))
        }

        allAllocations = updatedAllAllocations
        refreshWithLastContext()
        return .success(newAllocations.count)
    }
}

private extension PlanStore {
    struct PlanProtocolDescriptor {
        let id: UUID
        let title: String
        let mode: NonNegotiableMode
        let frequencyPerWeek: Int
        let state: NonNegotiableState
        let estimatedDurationMinutes: Int
        let tone: PlanTone
        let icon: String
        let completionsThisWeek: Int
        let completionsTodayCount: Int
    }

    struct PlanSlotSnapshot {
        let busyMinutes: Int
        let plannedMinutes: Int
        let freeCapacityBeforePlanning: Int
        let freeMinutes: Int
    }

    var dailyPlacementsPerDayTarget: Int { 1 }

    func buildProtocolDescriptors(from system: CommitmentSystem, referenceDate: Date) {
        let managed = system.nonNegotiables.filter {
            $0.state == .active || $0.state == .recovery || $0.state == .suspended
        }
        hasTrackableProtocols = managed.isEmpty == false

        let today = DateRules.startOfDay(referenceDate, calendar: calendar)
        var result: [UUID: PlanProtocolDescriptor] = [:]

        for (index, nn) in managed.enumerated() {
            let tone = PlanTone.allCases[index % PlanTone.allCases.count]
            let completionsThisWeek = nn.completions.filter { $0.weekId == weekId }.count
            let completionsTodayCount = nn.completions.filter {
                DateRules.startOfDay($0.date, calendar: calendar) == today
            }.count

            result[nn.id] = PlanProtocolDescriptor(
                id: nn.id,
                title: nn.definition.title,
                mode: nn.definition.mode,
                frequencyPerWeek: nn.definition.frequencyPerWeek,
                state: nn.state,
                estimatedDurationMinutes: nn.definition.estimatedDurationMinutes,
                tone: tone,
                icon: nn.definition.iconSystemName,
                completionsThisWeek: completionsThisWeek,
                completionsTodayCount: completionsTodayCount
            )
        }

        protocolsById = result
    }

    func normalizeAllocations() {
        let oldAllocations = allAllocations

        let normalized = oldAllocations
            .filter { allocation in
                protocolsById[allocation.protocolId] != nil
            }
            .sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.createdAt < rhs.createdAt
            }

        var seen: Set<String> = []
        var unique: [PlanAllocation] = []
        var didMutate = normalized.count != oldAllocations.count

        for allocation in normalized {
            let dayStart = DateRules.startOfDay(allocation.day, calendar: calendar)
            let allocationWeekId = DateRules.weekID(for: dayStart, calendar: calendar)
            let key = "\(allocationWeekId.description)|\(allocation.protocolId.uuidString)|\(dayStart.timeIntervalSince1970)"

            guard seen.insert(key).inserted else {
                didMutate = true
                continue
            }

            if allocation.day != dayStart || allocation.weekId != allocationWeekId {
                didMutate = true
                unique.append(
                    PlanAllocation(
                        id: allocation.id,
                        protocolId: allocation.protocolId,
                        weekId: allocationWeekId,
                        day: dayStart,
                        slot: allocation.slot,
                        startTime: allocation.startTime,
                        durationMinutes: allocation.durationMinutes,
                        createdAt: allocation.createdAt,
                        updatedAt: allocation.updatedAt
                    )
                )
            } else {
                unique.append(allocation)
            }
        }

        allAllocations = unique
        weekAllocations = allAllocations.filter { allocation in
            allocation.weekId == weekId && protocolsById[allocation.protocolId] != nil
        }

        if didMutate {
            try? repository.save(allAllocations)
        }
    }

    func buildQueue(referenceDate: Date) {
        let today = DateRules.startOfDay(referenceDate, calendar: calendar)

        queueItems = protocolsById.values.compactMap { descriptor in
            let plannedThisWeek = weekAllocations.filter { $0.protocolId == descriptor.id }.count
            let plannedToday = weekAllocations.filter {
                $0.protocolId == descriptor.id && DateRules.startOfDay($0.day, calendar: calendar) == today
            }.count

            let remaining: Int
            switch descriptor.mode {
            case .daily:
                remaining = max(0, dailyPlacementsPerDayTarget - descriptor.completionsTodayCount - plannedToday)
            case .session:
                remaining = max(0, descriptor.frequencyPerWeek - descriptor.completionsThisWeek - plannedThisWeek)
            }

            guard remaining > 0 else { return nil }

            return PlanQueueItem(
                id: descriptor.id,
                protocolId: descriptor.id,
                title: descriptor.title,
                icon: descriptor.icon,
                remainingCount: remaining,
                durationLabel: "\(descriptor.estimatedDurationMinutes)m",
                requiredMinutes: descriptor.estimatedDurationMinutes,
                isDisabled: descriptor.state == .suspended,
                mode: descriptor.mode,
                tone: descriptor.tone
            )
        }
        .sorted { lhs, rhs in
            if lhs.isDisabled != rhs.isDisabled {
                return lhs.isDisabled == false
            }
            return lhs.title < rhs.title
        }
    }

    func buildWeekDays(referenceDate: Date) {
        let weekStart = DateRules.startOfDay(weekInterval.start, calendar: calendar)
        let today = DateRules.startOfDay(referenceDate, calendar: calendar)

        currentWeekDays = (0..<7).compactMap { dayOffset in
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { return nil }
            let dayStart = DateRules.startOfDay(day, calendar: calendar)

            let slots = PlanSlot.allCases.map { slot -> PlanSlotModel in
                let busyEvents = busyEvents(for: dayStart, slot: slot)
                let busyMinutes = busyMinutes(for: dayStart, slot: slot)
                let allocations = allocationsFor(day: dayStart, slot: slot)

                let displays = allocations.compactMap { allocation -> PlanAllocationDisplay? in
                    guard let descriptor = protocolsById[allocation.protocolId] else { return nil }
                    let minutes = allocation.durationMinutes ?? descriptor.estimatedDurationMinutes
                    return PlanAllocationDisplay(
                        id: allocation.id,
                        protocolId: allocation.protocolId,
                        title: descriptor.title,
                        tone: descriptor.tone,
                        icon: descriptor.icon,
                        durationLabel: "\(minutes)m",
                        durationMinutes: minutes
                    )
                }

                let plannedMinutes = displays.reduce(0) { $0 + $1.durationMinutes }
                let freeBeforePlanning = max(0, slot.durationMinutes - busyMinutes)
                let freeMinutes = max(0, freeBeforePlanning - plannedMinutes)

                return PlanSlotModel(
                    id: "\(dayStart.timeIntervalSince1970)-\(slot.rawValue)",
                    slot: slot,
                    busyEvents: busyEvents,
                    allocations: displays,
                    busyMinutes: busyMinutes,
                    plannedMinutes: plannedMinutes,
                    freeCapacityBeforePlanning: freeBeforePlanning,
                    freeMinutes: freeMinutes,
                    availableLabel: availabilityLabel(freeMinutes)
                )
            }

            let dayFormatter = DateFormatter()
            dayFormatter.locale = .current
            dayFormatter.calendar = calendar
            dayFormatter.dateFormat = "EEE"

            let numberFormatter = DateFormatter()
            numberFormatter.locale = .current
            numberFormatter.calendar = calendar
            numberFormatter.dateFormat = "d"

            return PlanDayModel(
                id: dayStart,
                date: dayStart,
                weekdayLabel: dayFormatter.string(from: dayStart).uppercased(),
                dayNumberLabel: numberFormatter.string(from: dayStart),
                isToday: dayStart == today,
                slots: slots,
                busyMinutesTotal: slots.reduce(0) { $0 + $1.busyMinutes },
                freeMinutesTotal: slots.reduce(0) { $0 + $1.freeMinutes },
                plannedCount: slots.reduce(0) { $0 + $1.allocations.count }
            )
        }
    }

    func buildTodaySummary(referenceDate: Date) {
        let today = DateRules.startOfDay(referenceDate, calendar: calendar)
        let remaining = queueItems.reduce(0) { $0 + $1.remainingCount }

        guard let todayModel = currentWeekDays.first(where: { $0.date == today }) else {
            todaySummary = PlanTodaySummary(
                busyMinutes: 0,
                freeMinutes: 0,
                plannedCount: 0,
                remainingSessions: remaining
            )
            return
        }

        todaySummary = PlanTodaySummary(
            busyMinutes: todayModel.busyMinutesTotal,
            freeMinutes: todayModel.freeMinutesTotal,
            plannedCount: todayModel.plannedCount,
            remainingSessions: remaining
        )
    }

    func buildStructureStatus() {
        let remainingSessions = queueItems.reduce(0) { $0 + $1.remainingCount }
        let plannedCount = weekAllocations.count

        if remainingSessions > 0 && plannedCount == 0 {
            setStructure(.unstructured, message: "Sessions remain but no plan exists.")
            return
        }

        let dayCounts = Dictionary(grouping: weekAllocations) {
            DateRules.startOfDay($0.day, calendar: calendar)
        }
        let maxDayCount = dayCounts.values.map(\.count).max() ?? 0
        let clumped = plannedCount > 0 && (Double(maxDayCount) / Double(plannedCount)) > 0.60

        let overloaded = currentWeekDays.flatMap(\.slots).contains { slot in
            slot.plannedMinutes > slot.freeCapacityBeforePlanning ||
            slot.plannedMinutes > Int(Double(slot.slot.durationMinutes) * 0.8)
        }

        let distributedAcrossMultipleDays = dayCounts.keys.count >= 2

        if clumped || overloaded {
            if clumped {
                setStructure(.fragile, message: "Plan is clumped. Spread sessions across more days.")
            } else {
                setStructure(.fragile, message: "One or more slots are overloaded.")
            }
            return
        }

        if remainingSessions > 0 {
            setStructure(.fragile, message: "Plan is incomplete. Allocate remaining sessions.")
            return
        }

        if plannedCount == 0 {
            setStructure(.structural, message: "No pending sessions. Week is clear.")
            return
        }

        if distributedAcrossMultipleDays {
            setStructure(.structural, message: "Sessions are distributed across the week.")
        } else {
            setStructure(.fragile, message: "Sessions are concentrated on one day.")
        }
    }

    func setStructure(_ status: PlanStructureStatus, message: String) {
        structureStatus = status
        structureMessage = message
        planSignal = status
        planSignalMessage = message
    }

    func saveAndRefresh() {
        do {
            try repository.save(allAllocations)
        } catch {
            setWarning("Could not persist plan changes.")
        }
        refreshWithLastContext()
    }

    func refreshWithLastContext() {
        guard let lastSystem else { return }
        refresh(system: lastSystem, calendarEvents: sourceCalendarEvents, referenceDate: lastReferenceDate)
    }

    func busyEvents(for day: Date, slot: PlanSlot) -> [PlanCalendarEvent] {
        guard let slotInterval = slot.interval(on: day, calendar: calendar) else { return [] }
        let dayStart = DateRules.startOfDay(day, calendar: calendar)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
        let dayInterval = DateInterval(start: dayStart, end: dayEnd)

        return calendarEvents.filter { event in
            let eventInterval = DateInterval(start: event.startDateTime, end: event.endDateTime)
            if event.isAllDay {
                return slot == .am && eventInterval.intersects(dayInterval)
            }
            if eventInterval.intersects(slotInterval) {
                return true
            }
            return touchesSlotBoundary(eventInterval: eventInterval, slotInterval: slotInterval)
        }
    }

    func busyMinutes(for day: Date, slot: PlanSlot) -> Int {
        guard let slotInterval = slot.interval(on: day, calendar: calendar) else { return 0 }
        let dayStart = DateRules.startOfDay(day, calendar: calendar)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return 0 }
        let dayInterval = DateInterval(start: dayStart, end: dayEnd)

        var totalBusyMinutes = 0

        for event in calendarEvents {
            let eventInterval = DateInterval(start: event.startDateTime, end: event.endDateTime)
            if event.isAllDay {
                if eventInterval.intersects(dayInterval) {
                    return slot.durationMinutes
                }
                continue
            }
            let overlap = overlapMinutes(slotInterval, eventInterval)
            if overlap > 0 {
                totalBusyMinutes += overlap
            } else if touchesSlotBoundary(eventInterval: eventInterval, slotInterval: slotInterval) {
                totalBusyMinutes += 1
            }
        }

        return min(slot.durationMinutes, max(0, totalBusyMinutes))
    }

    func overlapMinutes(_ lhs: DateInterval, _ rhs: DateInterval) -> Int {
        let start = max(lhs.start, rhs.start)
        let end = min(lhs.end, rhs.end)
        guard end > start else { return 0 }
        return Int((end.timeIntervalSince(start) / 60).rounded())
    }

    func touchesSlotBoundary(eventInterval: DateInterval, slotInterval: DateInterval) -> Bool {
        (eventInterval.start == slotInterval.end && eventInterval.end > slotInterval.end) ||
        (eventInterval.end == slotInterval.start && eventInterval.start < slotInterval.start)
    }

    func allocationsFor(day: Date, slot: PlanSlot) -> [PlanAllocation] {
        allocationsFor(day: day, slot: slot, in: weekAllocations)
    }

    func allocationsFor(day: Date, slot: PlanSlot, in allocations: [PlanAllocation]) -> [PlanAllocation] {
        allocations
            .filter {
                DateRules.startOfDay($0.day, calendar: calendar) == day && $0.slot == slot
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func slotSnapshot(day: Date, slot: PlanSlot, excluding allocationId: UUID?) -> PlanSlotSnapshot {
        slotSnapshot(day: day, slot: slot, excluding: allocationId, in: weekAllocations)
    }

    func slotSnapshot(day: Date, slot: PlanSlot, excluding allocationId: UUID?, in allocations: [PlanAllocation]) -> PlanSlotSnapshot {
        let busy = busyMinutes(for: day, slot: slot)

        let planned = allocationsFor(day: day, slot: slot, in: allocations)
            .filter { $0.id != allocationId }
            .reduce(0) { partial, allocation in
                let duration = allocation.durationMinutes ?? protocolsById[allocation.protocolId]?.estimatedDurationMinutes ?? 90
                return partial + duration
            }

        let freeBefore = max(0, slot.durationMinutes - busy)
        let free = max(0, freeBefore - planned)

        return PlanSlotSnapshot(
            busyMinutes: busy,
            plannedMinutes: planned,
            freeCapacityBeforePlanning: freeBefore,
            freeMinutes: free
        )
    }

    func plannedCount(on day: Date, excluding allocationId: UUID?) -> Int {
        plannedCount(on: day, excluding: allocationId, in: weekAllocations)
    }

    func plannedCount(on day: Date, excluding allocationId: UUID?, in allocations: [PlanAllocation]) -> Int {
        let dayStart = DateRules.startOfDay(day, calendar: calendar)
        return allocations.filter {
            DateRules.startOfDay($0.day, calendar: calendar) == dayStart && $0.id != allocationId
        }.count
    }

    func dailyPlannedCount(protocolId: UUID, day: Date, excluding allocationId: UUID?) -> Int {
        dailyPlannedCount(protocolId: protocolId, day: day, excluding: allocationId, in: weekAllocations)
    }

    func dailyPlannedCount(protocolId: UUID, day: Date, excluding allocationId: UUID?, in allocations: [PlanAllocation]) -> Int {
        let dayStart = DateRules.startOfDay(day, calendar: calendar)
        return allocations.filter {
            $0.protocolId == protocolId &&
            DateRules.startOfDay($0.day, calendar: calendar) == dayStart &&
            $0.id != allocationId
        }.count
    }

    func validatePlacement(
        descriptor: PlanProtocolDescriptor,
        protocolId: UUID,
        day: Date,
        slot: PlanSlot,
        requiredMinutes: Int,
        excludingAllocationId: UUID?,
        requiresQueueAvailability: Bool,
        context: PlanValidationContext,
        candidateAllocations: [PlanAllocation]
    ) -> PlanPlacementValidation {
        if descriptor.state == .suspended {
            return .blocked(message: "Suspended protocol cannot be planned right now.")
        }

        if requiresQueueAvailability {
            guard let queueItem = queueItems.first(where: { $0.protocolId == protocolId }) else {
                return .blocked(message: "No remaining sessions for this protocol this week.")
            }
            if queueItem.isDisabled {
                return .blocked(message: "Suspended protocol cannot be planned right now.")
            }
        }

        let weeklyTarget: Int
        switch descriptor.mode {
        case .daily:
            weeklyTarget = 7
        case .session:
            weeklyTarget = descriptor.frequencyPerWeek
        }
        let plannedThisWeek = candidateAllocations.filter {
            $0.protocolId == protocolId && $0.id != excludingAllocationId
        }.count
        if descriptor.completionsThisWeek + plannedThisWeek >= weeklyTarget {
            return .blocked(message: "No remaining sessions for this protocol this week.")
        }

        let dayStart = DateRules.startOfDay(day, calendar: calendar)
        if dailyPlannedCount(
            protocolId: protocolId,
            day: dayStart,
            excluding: excludingAllocationId,
            in: candidateAllocations
        ) >= 1 {
            return .blocked(message: "Protocol already planned for this day.")
        }

        if descriptor.mode == .daily {
            if context == .manual {
                let todayStart = DateRules.startOfDay(lastReferenceDate, calendar: calendar)
                let tomorrowStart = DateRules.addingDays(1, to: todayStart, calendar: calendar)
                if dayStart != todayStart && dayStart != tomorrowStart {
                    return .blocked(message: "Daily protocols can only be planned for today or tomorrow.")
                }
            }
        }

        let snapshot = slotSnapshot(day: dayStart, slot: slot, excluding: excludingAllocationId, in: candidateAllocations)
        if snapshot.freeMinutes < requiredMinutes {
            return .blocked(message: "Insufficient free minutes in this slot.")
        }

        if shouldApplyRecoveryStrictness(for: descriptor),
           plannedCount(on: dayStart, excluding: excludingAllocationId, in: candidateAllocations) >= 2 {
            return .blocked(message: "Recovery capacity reached for this day.")
        }

        return .allowed
    }

    func shouldApplyRecoveryStrictness(for descriptor: PlanProtocolDescriptor) -> Bool {
        if descriptor.state == .recovery {
            return true
        }
        return protocolsById.values.contains(where: { $0.state == .recovery })
    }

    func availabilityLabel(_ freeMinutes: Int) -> String {
        let rounded = max(0, Int((Double(freeMinutes) / 5.0).rounded() * 5.0))
        if rounded == 0 { return "0m AVAILABLE" }

        let hours = rounded / 60
        let minutes = rounded % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m AVAILABLE"
        }
        if hours > 0 {
            return "\(hours)h AVAILABLE"
        }
        return "\(minutes)m AVAILABLE"
    }

    func dayIndex(for day: Date) -> Int? {
        let start = DateRules.startOfDay(day, calendar: calendar)
        let weekStart = DateRules.startOfDay(weekInterval.start, calendar: calendar)
        let delta = calendar.dateComponents([.day], from: weekStart, to: start).day ?? 0
        guard (0...6).contains(delta) else { return nil }
        return delta
    }

    func planSlot(for regulationSlot: RegulationSlot) -> PlanSlot {
        switch regulationSlot {
        case .am: return .am
        case .pm: return .pm
        case .eve: return .eve
        }
    }

    func regulationSlot(for planSlot: PlanSlot) -> RegulationSlot {
        switch planSlot {
        case .am: return .am
        case .pm: return .pm
        case .eve: return .eve
        }
    }

    func setWarning(_ message: String) {
        warningMessage = message
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if self?.warningMessage == message {
                self?.warningMessage = nil
            }
        }
    }
}
