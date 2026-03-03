import Foundation
import Combine

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

    func placeSelectedProtocol(day: Date, slot: PlanSlot) {
        guard let selectedQueueProtocolId else {
            setWarning("Select a protocol first.")
            return
        }
        placeProtocol(protocolId: selectedQueueProtocolId, day: day, slot: slot)
    }

    func placeProtocol(protocolId: UUID, day: Date, slot: PlanSlot) {
        guard let descriptor = protocolsById[protocolId] else {
            setWarning("Protocol is no longer available.")
            return
        }

        guard let queueItem = queueItems.first(where: { $0.protocolId == protocolId }) else {
            setWarning("No remaining sessions for this protocol this week.")
            return
        }

        if queueItem.isDisabled {
            setWarning("Suspended protocol cannot be planned right now.")
            return
        }

        let dayStart = DateRules.startOfDay(day, calendar: calendar)
        if descriptor.mode == .daily {
            let todayStart = DateRules.startOfDay(lastReferenceDate, calendar: calendar)
            let tomorrowStart = DateRules.addingDays(1, to: todayStart, calendar: calendar)
            if dayStart != todayStart && dayStart != tomorrowStart {
                setWarning("Daily protocols can only be planned for today or tomorrow.")
                return
            }
            if hasDailyPlanned(protocolId: protocolId, day: dayStart, excluding: nil) {
                setWarning("Daily protocol already planned for this day.")
                return
            }
        }

        let snapshot = slotSnapshot(day: dayStart, slot: slot, excluding: nil)
        if snapshot.freeMinutes < queueItem.requiredMinutes {
            setWarning("Insufficient free minutes in this slot.")
            return
        }

        if shouldApplyRecoveryStrictness(for: descriptor), plannedCount(on: dayStart, excluding: nil) >= 2 {
            setWarning("Recovery capacity reached for this day.")
            return
        }

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
    }

    func moveAllocation(id: UUID, newDay: Date, newSlot: PlanSlot) {
        guard let index = allAllocations.firstIndex(where: { $0.id == id }) else { return }
        let allocation = allAllocations[index]

        guard let descriptor = protocolsById[allocation.protocolId] else {
            setWarning("Protocol is no longer available.")
            return
        }

        let newDayStart = DateRules.startOfDay(newDay, calendar: calendar)

        if descriptor.mode == .daily {
            let todayStart = DateRules.startOfDay(lastReferenceDate, calendar: calendar)
            let tomorrowStart = DateRules.addingDays(1, to: todayStart, calendar: calendar)
            if newDayStart != todayStart && newDayStart != tomorrowStart {
                setWarning("Daily protocols can only be planned for today or tomorrow.")
                return
            }
            if hasDailyPlanned(protocolId: allocation.protocolId, day: newDayStart, excluding: id) {
                setWarning("Daily protocol already planned for this day.")
                return
            }
        }

        let duration = allocation.durationMinutes ?? descriptor.estimatedDurationMinutes
        let snapshot = slotSnapshot(day: newDayStart, slot: newSlot, excluding: id)
        if snapshot.freeMinutes < duration {
            setWarning("Insufficient free minutes in this slot.")
            return
        }

        if shouldApplyRecoveryStrictness(for: descriptor), plannedCount(on: newDayStart, excluding: id) >= 2 {
            setWarning("Recovery capacity reached for this day.")
            return
        }

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
    }

    func removeAllocation(id: UUID) {
        allAllocations.removeAll(where: { $0.id == id })
        saveAndRefresh()
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
        let completedToday: Bool
    }

    struct PlanSlotSnapshot {
        let busyMinutes: Int
        let plannedMinutes: Int
        let freeCapacityBeforePlanning: Int
        let freeMinutes: Int
    }

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
            let completedToday = nn.completions.contains {
                DateRules.startOfDay($0.date, calendar: calendar) == today
            }

            result[nn.id] = PlanProtocolDescriptor(
                id: nn.id,
                title: nn.definition.title,
                mode: nn.definition.mode,
                frequencyPerWeek: nn.definition.frequencyPerWeek,
                state: nn.state,
                estimatedDurationMinutes: estimatedDuration(for: nn.definition.mode, title: nn.definition.title),
                tone: tone,
                icon: icon(for: nn.definition.title),
                completionsThisWeek: completionsThisWeek,
                completedToday: completedToday
            )
        }

        protocolsById = result
    }

    func normalizeAllocations() {
        weekAllocations = allAllocations.filter { allocation in
            allocation.weekId == weekId && protocolsById[allocation.protocolId] != nil
        }

        let oldCount = allAllocations.count
        allAllocations = allAllocations.filter { allocation in
            protocolsById[allocation.protocolId] != nil
        }

        if oldCount != allAllocations.count {
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
                remaining = (descriptor.completedToday || plannedToday > 0) ? 0 : 1
            case .session:
                remaining = max(0, descriptor.frequencyPerWeek - descriptor.completionsThisWeek - plannedThisWeek)
            }

            guard remaining > 0 else { return nil }

            return PlanQueueItem(
                id: descriptor.id,
                protocolId: descriptor.id,
                title: descriptor.title,
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

        return calendarEvents.filter { event in
            guard event.isAllDay == false else { return false }
            let eventInterval = DateInterval(start: event.startDateTime, end: event.endDateTime)
            return eventInterval.intersects(slotInterval)
        }
    }

    func busyMinutes(for day: Date, slot: PlanSlot) -> Int {
        guard let slotInterval = slot.interval(on: day, calendar: calendar) else { return 0 }

        return calendarEvents.reduce(0) { partial, event in
            guard event.isAllDay == false else { return partial }
            let eventInterval = DateInterval(start: event.startDateTime, end: event.endDateTime)
            return partial + overlapMinutes(slotInterval, eventInterval)
        }
    }

    func overlapMinutes(_ lhs: DateInterval, _ rhs: DateInterval) -> Int {
        let start = max(lhs.start, rhs.start)
        let end = min(lhs.end, rhs.end)
        guard end > start else { return 0 }
        return Int((end.timeIntervalSince(start) / 60).rounded())
    }

    func allocationsFor(day: Date, slot: PlanSlot) -> [PlanAllocation] {
        weekAllocations
            .filter {
                DateRules.startOfDay($0.day, calendar: calendar) == day && $0.slot == slot
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func slotSnapshot(day: Date, slot: PlanSlot, excluding allocationId: UUID?) -> PlanSlotSnapshot {
        let busy = busyMinutes(for: day, slot: slot)

        let planned = allocationsFor(day: day, slot: slot)
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
        let dayStart = DateRules.startOfDay(day, calendar: calendar)
        return weekAllocations.filter {
            DateRules.startOfDay($0.day, calendar: calendar) == dayStart && $0.id != allocationId
        }.count
    }

    func hasDailyPlanned(protocolId: UUID, day: Date, excluding allocationId: UUID?) -> Bool {
        let dayStart = DateRules.startOfDay(day, calendar: calendar)
        return weekAllocations.contains {
            $0.protocolId == protocolId &&
            DateRules.startOfDay($0.day, calendar: calendar) == dayStart &&
            $0.id != allocationId
        }
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

    func estimatedDuration(for mode: NonNegotiableMode, title: String) -> Int {
        let lower = title.lowercased()
        if lower.contains("hydrat") || lower.contains("water") { return 15 }
        if lower.contains("iso") || lower.contains("stretch") { return 20 }
        if mode == .daily { return 20 }
        return 90
    }

    func icon(for title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("hydrat") || lower.contains("water") { return "drop.fill" }
        if lower.contains("drill") || lower.contains("neural") { return "brain.head.profile" }
        if lower.contains("deep") || lower.contains("focus") { return "bolt.fill" }
        if lower.contains("iso") || lower.contains("strength") { return "figure.strengthtraining.traditional" }
        return "waveform.path.ecg"
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
