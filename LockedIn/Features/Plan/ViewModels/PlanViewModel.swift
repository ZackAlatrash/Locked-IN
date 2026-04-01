import Foundation
import Combine

@MainActor
final class PlanViewModel: ObservableObject {
    @Published private(set) var currentWeekDays: [PlanDayModel] = []
    @Published private(set) var queueItems: [PlanQueueItem] = []
    @Published private(set) var selectedQueueProtocolId: UUID?
    @Published private(set) var todaySummary: PlanTodaySummary = .empty
    @Published private(set) var structureStatus: PlanStructureStatus = .unstructured
    @Published private(set) var structureMessage: String = ""
    @Published private(set) var warningMessage: String?
    @Published private(set) var warningCopy: PolicyCopy?
    @Published private(set) var hasTrackableProtocols = false
    @Published private(set) var regulatorSuggestions: [PlanSuggestionUIModel] = []
    @Published private(set) var draftAllocations: [PlanAllocationDraft] = []
    @Published private(set) var regulatorSummary: PlanRegulatorSummary = .empty
    @Published private(set) var hasDraft = false
    @Published private(set) var calendarAccessStatus: PlanCalendarAuthorizationStatus = .notDetermined
    @Published private(set) var calendarEventsThisWeekCount: Int = 0
    @Published var protocolSchedulingEditor: ProtocolSchedulingEditorState?
    @Published var protocolEditErrorMessage: String?
    @Published var showingRegulatorSheet = false

    @Published var selectedAllocation: PlanAllocation?

    private let calendarProvider: PlanCalendarProviding
    private let regulatorEngine: PlanRegulatorEngine
    private var cancellables: Set<AnyCancellable> = []
    private var referenceDateProvider: () -> Date = { Date() }

    private weak var planStore: PlanStore?
    private weak var commitmentStore: CommitmentSystemStore?

    init(
        calendarProvider: PlanCalendarProviding? = nil,
        regulatorEngine: PlanRegulatorEngine? = nil
    ) {
        self.calendarProvider = calendarProvider ?? AppleCalendarProvider()
        self.regulatorEngine = regulatorEngine ?? PlanRegulatorEngine()
    }

    var isCalendarConnected: Bool {
        calendarAccessStatus.isAuthorized
    }

    var calendarStatusMessage: String {
        switch calendarAccessStatus {
        case .authorized:
            return "Apple Calendar connected."
        case .notDetermined:
            return "Connect Apple Calendar to import real events."
        case .denied:
            return "Calendar access denied. Enable it in iOS Settings."
        case .restricted:
            return "Calendar access is restricted on this device."
        case .writeOnly:
            return "Calendar is write-only. Enable full access in iOS Settings."
        }
    }

    var weekSubtitle: String {
        planStore?.weekSubtitle ?? ""
    }

    func setReferenceDateProvider(_ provider: @escaping () -> Date) {
        referenceDateProvider = provider
    }

    func bind(planStore: PlanStore, commitmentStore: CommitmentSystemStore) {
        let needsRebind = self.planStore !== planStore || self.commitmentStore !== commitmentStore
        guard needsRebind else { return }

        cancellables.removeAll()

        self.planStore = planStore
        self.commitmentStore = commitmentStore
        calendarAccessStatus = calendarProvider.authorizationStatus()

        planStore.$currentWeekDays
            .sink { [weak self] in self?.currentWeekDays = $0 }
            .store(in: &cancellables)

        planStore.$queueItems
            .sink { [weak self] in self?.queueItems = $0 }
            .store(in: &cancellables)

        planStore.$selectedQueueProtocolId
            .sink { [weak self] in self?.selectedQueueProtocolId = $0 }
            .store(in: &cancellables)

        planStore.$todaySummary
            .sink { [weak self] in self?.todaySummary = $0 }
            .store(in: &cancellables)

        planStore.$structureStatus
            .sink { [weak self] in self?.structureStatus = $0 }
            .store(in: &cancellables)

        planStore.$structureMessage
            .sink { [weak self] in self?.structureMessage = $0 }
            .store(in: &cancellables)

        planStore.$warningMessage
            .sink { [weak self] in self?.warningMessage = $0 }
            .store(in: &cancellables)

        planStore.$warningReason
            .sink { [weak self] reason in
                self?.warningCopy = reason?.copy()
            }
            .store(in: &cancellables)

        planStore.$hasTrackableProtocols
            .sink { [weak self] in self?.hasTrackableProtocols = $0 }
            .store(in: &cancellables)

        commitmentStore.$system
            .sink { [weak self] _ in
                self?.refresh(referenceDate: self?.currentReferenceDate())
            }
            .store(in: &cancellables)

        refresh(referenceDate: currentReferenceDate())
    }

    func refresh(referenceDate: Date? = nil) {
        guard let planStore, let commitmentStore else { return }
        let referenceDate = referenceDate ?? currentReferenceDate()
        let week = DateRules.weekInterval(containing: referenceDate, calendar: DateRules.isoCalendar)
        calendarAccessStatus = calendarProvider.authorizationStatus()
        let events: [PlanCalendarEvent]
        if calendarAccessStatus.isAuthorized {
            events = calendarProvider.events(for: week, calendar: DateRules.isoCalendar)
        } else {
            events = []
        }
        calendarEventsThisWeekCount = events.count
        planStore.refresh(system: commitmentStore.system, calendarEvents: events, referenceDate: referenceDate)
    }

    func requestCalendarAccess() async {
        let status = await calendarProvider.requestAccess()
        calendarAccessStatus = status
        refresh(referenceDate: currentReferenceDate())
    }

    func handleDidBecomeActive(referenceDate: Date? = nil) {
        refresh(referenceDate: referenceDate ?? currentReferenceDate())
    }

    func protocolTitle(for id: UUID) -> String {
        planStore?.protocolTitle(for: id) ?? "Protocol"
    }

    func queueItem(for protocolId: UUID) -> PlanQueueItem? {
        queueItems.first(where: { $0.protocolId == protocolId })
    }

    func allocationDisplay(for allocationId: UUID) -> PlanAllocationDisplay? {
        currentWeekDays
            .flatMap(\.slots)
            .flatMap(\.allocations)
            .first(where: { $0.id == allocationId })
    }

    func validateProtocolPlacement(protocolId: UUID, day: Date, slot: PlanSlot) -> PlanPlacementValidation {
        planStore?.validateProtocolPlacement(protocolId: protocolId, day: day, slot: slot, context: .manual)
            ?? .blocked(message: "Plan system unavailable.", reason: .generic(message: "Plan system unavailable."))
    }

    func validateMove(allocationId: UUID, day: Date, slot: PlanSlot) -> PlanPlacementValidation {
        planStore?.validateMove(allocationId: allocationId, day: day, slot: slot)
            ?? .blocked(message: "Plan system unavailable.", reason: .generic(message: "Plan system unavailable."))
    }

    func selectProtocol(id: UUID) {
        planStore?.selectProtocol(id)
    }

    func focusProtocol(id: UUID?) {
        planStore?.focusProtocol(id)
    }

    func clearWarning() {
        planStore?.clearWarning()
    }

    @discardableResult
    func placeSelectedProtocol(day: Date, slot: PlanSlot) -> PlanMutation? {
        planStore?.placeSelectedProtocol(day: day, slot: slot)
    }

    @discardableResult
    func placeProtocol(protocolId: UUID, day: Date, slot: PlanSlot) -> PlanMutation? {
        planStore?.placeProtocol(protocolId: protocolId, day: day, slot: slot)
    }

    func editAllocation(allocationId: UUID) {
        selectedAllocation = planStore?.allocation(id: allocationId)
    }

    func removeAllocation(allocationId: UUID) {
        planStore?.removeAllocation(id: allocationId)
        selectedAllocation = nil
    }

    @discardableResult
    func moveAllocation(allocationId: UUID, to day: Date, slot: PlanSlot) -> PlanMutation? {
        let mutation = planStore?.moveAllocation(id: allocationId, newDay: day, newSlot: slot)
        selectedAllocation = nil
        return mutation
    }

    func runRegulator() {
        guard let planStore, let commitmentStore else { return }

        let snapshot = planStore.currentWeekSnapshot()
        let activeAllocations = snapshot.currentWeekAllocations.filter { $0.status == .active }
        let protocols = buildProtocolPlanItems(
            system: commitmentStore.system,
            weekId: snapshot.weekId,
            allocations: activeAllocations
        )
        let durationsByProtocolId = Dictionary(uniqueKeysWithValues: protocols.map { ($0.id, $0.durationMinutes) })
        let events = snapshot.calendarEvents.map {
            RegulationCalendarEvent(
                id: $0.id,
                startDateTime: $0.startDateTime,
                endDateTime: $0.endDateTime,
                isAllDay: $0.isAllDay
            )
        }
        let existing = activeAllocations.map { allocation in
            ExistingAllocationSnapshot(
                protocolId: allocation.protocolId,
                day: allocation.day,
                slot: allocation.slot.regulationSlot,
                durationMinutes: allocation.durationMinutes ?? durationsByProtocolId[allocation.protocolId] ?? defaultDurationMinutes(for: .session)
            )
        }

        let input = PlanRegulationInput(
            weekId: snapshot.weekId,
            weekStartDate: snapshot.weekStartDate,
            protocols: protocols,
            calendarEvents: events,
            existingAllocations: existing,
            rules: PlanRegulationRules()
        )

        let draft = regulatorEngine.regulate(input: input)
        let validationWarnings = planStore.validateDraft(draft.suggestedAllocations)
        let mergedSuggestions = draft.suggestions + validationWarnings

        draftAllocations = draft.suggestedAllocations
        hasDraft = draftAllocations.isEmpty == false
        regulatorSuggestions = mapSuggestionUIModels(mergedSuggestions)
        regulatorSummary = buildRegulatorSummary(
            weekStartDate: snapshot.weekStartDate,
            protocols: protocols,
            draftAllocations: draft.suggestedAllocations,
            calendarEvents: snapshot.calendarEvents
        )
        showingRegulatorSheet = true

        let protocolsNeedingPlacement = protocols.filter { remainingSessions(for: $0) > 0 }.count

        let freeSlots = countFreeSlots(
            weekStartDate: snapshot.weekStartDate,
            events: snapshot.calendarEvents,
            allocations: activeAllocations
        )
        let warningsCount = mergedSuggestions.filter { $0.kind == .warning }.count

        print("protocolsNeedingPlacement=\(protocolsNeedingPlacement)")
        print("freeSlots=\(freeSlots)")
        print("draftAllocations=\(draftAllocations.count)")
        print("warnings=\(warningsCount)")
    }

    @discardableResult
    func applyDraft() -> Bool {
        guard let planStore else { return false }
        guard hasDraft else { return false }

        let result = planStore.applyDraft(draftAllocations)
        switch result {
        case .success:
            discardDraft()
            refresh(referenceDate: currentReferenceDate())
            return true
        case .failure:
            return false
        }
    }

    func discardDraft() {
        draftAllocations = []
        regulatorSuggestions = []
        regulatorSummary = .empty
        hasDraft = false
        showingRegulatorSheet = false
    }

    func draftAllocations(for day: Date, slot: PlanSlot) -> [PlanAllocationDraft] {
        let dayStart = DateRules.startOfDay(day, calendar: DateRules.isoCalendar)
        return draftAllocations.filter {
            DateRules.startOfDay($0.day, calendar: DateRules.isoCalendar) == dayStart &&
            $0.slot.planSlot == slot
        }
    }

    func openProtocolEditor(protocolId: UUID) {
        guard let commitmentStore else { return }
        guard let nonNegotiable = commitmentStore.system.nonNegotiables.first(where: { $0.id == protocolId }) else {
            return
        }
        let referenceDate = currentReferenceDate()
        let editableFields = commitmentStore.allowedEditableFields(for: protocolId, referenceDate: referenceDate)
        let lockEnd = DateRules.addingDays(
            nonNegotiable.lock.totalLockDays,
            to: DateRules.startOfDay(nonNegotiable.lock.startDate, calendar: DateRules.isoCalendar),
            calendar: DateRules.isoCalendar
        )
        let lockDaysRemaining = max(
            0,
            DateRules.isoCalendar.dateComponents(
                [.day],
                from: DateRules.startOfDay(referenceDate, calendar: DateRules.isoCalendar),
                to: lockEnd
            ).day ?? 0
        )
        protocolEditErrorMessage = nil
        protocolSchedulingEditor = ProtocolSchedulingEditorState(
            id: nonNegotiable.id,
            title: nonNegotiable.definition.title,
            preferredExecutionSlot: nonNegotiable.definition.preferredExecutionSlot,
            estimatedDurationMinutes: nonNegotiable.definition.estimatedDurationMinutes,
            iconSystemName: nonNegotiable.definition.iconSystemName,
            mode: nonNegotiable.definition.mode,
            frequencyPerWeek: nonNegotiable.definition.frequencyPerWeek,
            lockDays: nonNegotiable.lock.totalLockDays,
            lockDaysRemaining: lockDaysRemaining,
            lockEndsOn: lockEnd,
            editableFields: editableFields
        )
    }

    func dismissProtocolEditor() {
        protocolSchedulingEditor = nil
        protocolEditErrorMessage = nil
    }

    @discardableResult
    func saveProtocolEditor(
        id: UUID,
        title: String,
        preferredSlot: PreferredExecutionSlot,
        durationMinutes: Int,
        iconSystemName: String,
        mode: NonNegotiableMode?,
        frequencyPerWeek: Int?,
        lockDays: Int?
    ) -> Bool {
        guard let commitmentStore else { return false }
        do {
            try commitmentStore.editNonNegotiable(
                id: id,
                patch: NonNegotiablePatch(
                    newTitle: title,
                    newIconName: iconSystemName,
                    newPreferredTime: preferredSlot,
                    newEstimatedDurationMinutes: durationMinutes,
                    newMode: mode,
                    newFrequencyPerWeek: frequencyPerWeek,
                    newLockDays: lockDays
                ),
                referenceDate: currentReferenceDate()
            )
            protocolSchedulingEditor = nil
            protocolEditErrorMessage = nil
            refresh(referenceDate: currentReferenceDate())
            return true
        } catch {
            protocolEditErrorMessage = mapProtocolEditError(error)
            return false
        }
    }
}

private extension PlanViewModel {
    func buildProtocolPlanItems(
        system: CommitmentSystem,
        weekId: WeekID,
        allocations: [PlanAllocation]
    ) -> [ProtocolPlanItem] {
        system.nonNegotiables
            .filter { nn in
                nn.state == .active || nn.state == .recovery
            }
            .map { nn in
                let plannedThisWeek = allocations.filter { $0.protocolId == nn.id }.count
                let completionsThisWeek = nn.completions.filter {
                    $0.weekId == weekId && $0.kind == .counted
                }.count
                return ProtocolPlanItem(
                    id: nn.id,
                    title: nn.definition.title,
                    mode: nn.definition.mode,
                    state: nn.state,
                    frequencyPerWeek: nn.definition.frequencyPerWeek,
                    completionsThisWeek: completionsThisWeek,
                    plannedThisWeek: plannedThisWeek,
                    durationMinutes: nn.definition.estimatedDurationMinutes,
                    timePreference: nn.definition.preferredExecutionSlot.regulationPreference
                )
            }
    }

    func defaultDurationMinutes(for mode: NonNegotiableMode) -> Int {
        switch mode {
        case .daily: return 15
        case .session: return 60
        }
    }

    func countFreeSlots(weekStartDate: Date, events: [PlanCalendarEvent], allocations: [PlanAllocation]) -> Int {
        let days: [Date] = (0..<7).compactMap {
            DateRules.isoCalendar.date(byAdding: .day, value: $0, to: weekStartDate).map {
                DateRules.startOfDay($0, calendar: DateRules.isoCalendar)
            }
        }

        var free = 0
        for day in days {
            for slot in PlanSlot.allCases {
                let hasEvent = events.contains { event in
                    guard event.isAllDay == false else { return false }
                    guard let slotInterval = slot.interval(on: day, calendar: DateRules.isoCalendar) else {
                        return false
                    }
                    let eventInterval = DateInterval(start: event.startDateTime, end: event.endDateTime)
                    return eventInterval.intersects(slotInterval)
                }
                let hasAllocation = allocations.contains {
                    DateRules.startOfDay($0.day, calendar: DateRules.isoCalendar) == day &&
                    $0.slot == slot &&
                    $0.status == .active
                }
                if hasEvent == false && hasAllocation == false {
                    free += 1
                }
            }
        }
        return free
    }

    func mapSuggestionUIModels(_ suggestions: [PlanSuggestion]) -> [PlanSuggestionUIModel] {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEE"

        return suggestions.map { suggestion in
            let dayLabel: String
            if (0...6).contains(suggestion.dayIndex),
               let planStore {
                let start = planStore.currentWeekSnapshot().weekStartDate
                if let day = DateRules.isoCalendar.date(byAdding: .day, value: suggestion.dayIndex, to: start) {
                    dayLabel = formatter.string(from: day).uppercased()
                } else {
                    dayLabel = "-"
                }
            } else {
                dayLabel = "-"
            }

            return PlanSuggestionUIModel(
                id: suggestion.id,
                protocolId: suggestion.protocolId,
                protocolTitle: planStore?.protocolTitle(for: suggestion.protocolId) ?? "Protocol",
                dayLabel: dayLabel,
                slotLabel: suggestion.slot.title,
                confidence: suggestion.confidence,
                confidenceLabel: "\(Int((suggestion.confidence * 100).rounded()))%",
                reason: suggestion.reason,
                kind: suggestion.kind
            )
        }
    }

    func buildRegulatorSummary(
        weekStartDate: Date,
        protocols: [ProtocolPlanItem],
        draftAllocations: [PlanAllocationDraft],
        calendarEvents: [PlanCalendarEvent]
    ) -> PlanRegulatorSummary {
        let actionableProtocols = protocols.filter { $0.state == .active || $0.state == .recovery }
        let totalRemaining = actionableProtocols.reduce(0) { partial, item in
            partial + remainingSessions(for: item)
        }
        let placedSessions = draftAllocations.count
        let unscheduledSessions = max(0, totalRemaining - placedSessions)
        let draftCountByProtocolId = Dictionary(grouping: draftAllocations, by: \.protocolId).mapValues(\.count)
        let unscheduledNeeds = actionableProtocols
            .map { item -> PlanRegulatorUnscheduledNeed? in
                let remaining = remainingSessions(for: item)
                let placed = draftCountByProtocolId[item.id, default: 0]
                let unmet = max(0, remaining - placed)
                guard unmet > 0 else { return nil }
                return PlanRegulatorUnscheduledNeed(
                    protocolTitle: item.title,
                    unmetSessions: unmet
                )
            }
            .compactMap { $0 }
            .sorted { lhs, rhs in
                if lhs.unmetSessions != rhs.unmetSessions { return lhs.unmetSessions > rhs.unmetSessions }
                return lhs.protocolTitle.localizedCaseInsensitiveCompare(rhs.protocolTitle) == .orderedAscending
            }

        let spreadDays = Set(
            draftAllocations.map { DateRules.startOfDay($0.day, calendar: DateRules.isoCalendar) }
        ).count

        let dayCounts = Dictionary(
            grouping: draftAllocations,
            by: { DateRules.startOfDay($0.day, calendar: DateRules.isoCalendar) }
        ).mapValues(\.count)
        let isBalanced: Bool = {
            guard dayCounts.isEmpty == false else { return false }
            let maxPerDay = dayCounts.values.max() ?? 0
            let minPerDay = dayCounts.values.min() ?? 0
            let requiredSpread = min(max(placedSessions, 1), 4)
            return spreadDays >= requiredSpread && (maxPerDay - minPerDay) <= 1
        }()

        let hasCalendarConflicts = draftAllocations.contains { draft in
            guard let slotInterval = draft.slot.planSlot.interval(
                on: DateRules.startOfDay(draft.day, calendar: DateRules.isoCalendar),
                calendar: DateRules.isoCalendar
            ) else {
                return false
            }
            return calendarEvents.contains { event in
                guard event.isAllDay == false else { return false }
                let eventInterval = DateInterval(start: event.startDateTime, end: event.endDateTime)
                return eventInterval.intersects(slotInterval)
            }
        }

        return PlanRegulatorSummary(
            placedSessions: placedSessions,
            unscheduledSessions: unscheduledSessions,
            spreadDays: spreadDays,
            isBalanced: isBalanced,
            hasCalendarConflicts: hasCalendarConflicts,
            unscheduledNeeds: unscheduledNeeds
        )
    }

    func remainingSessions(for item: ProtocolPlanItem) -> Int {
        switch item.mode {
        case .session:
            return max(0, item.frequencyPerWeek - item.completionsThisWeek - item.plannedThisWeek)
        case .daily:
            return max(0, 7 - item.completionsThisWeek - item.plannedThisWeek)
        }
    }

    func currentReferenceDate() -> Date {
        referenceDateProvider()
    }

    func mapProtocolEditError(_ error: Error) -> String {
        if let commitmentStore,
           let copy = commitmentStore.policyCopy(for: error) {
            return copy.message
        }

        if let engineError = error as? NonNegotiableEngineError,
           case let .invalidDefinition(reason) = engineError {
            switch reason {
            case .titleEmpty:
                return "Title is required."
            case .frequencyOutOfRange:
                return "Frequency is out of range."
            case .invalidDailyFrequency:
                return "Daily mode requires 7 sessions per week."
            case .invalidLockDuration:
                return "Invalid lock duration."
            case .durationOutOfRange:
                return "Duration must be between 5 and 360 minutes."
            case .iconEmpty:
                return "Please select an icon."
            }
        }

        if let systemError = error as? CommitmentSystemError {
            switch systemError {
            case .nonNegotiableNotFound:
                return "Protocol no longer exists."
            default:
                break
            }
        }

        return "Unable to update protocol."
    }
}

struct ProtocolSchedulingEditorState: Identifiable, Equatable {
    let id: UUID
    var title: String
    var preferredExecutionSlot: PreferredExecutionSlot
    var estimatedDurationMinutes: Int
    var iconSystemName: String
    var mode: NonNegotiableMode
    var frequencyPerWeek: Int
    var lockDays: Int
    var lockDaysRemaining: Int
    var lockEndsOn: Date
    var editableFields: Set<ProtocolField>
}

struct PlanSuggestionUIModel: Identifiable, Equatable {
    let id: UUID
    let protocolId: UUID
    let protocolTitle: String
    let dayLabel: String
    let slotLabel: String
    let confidence: Double
    let confidenceLabel: String
    let reason: String
    let kind: PlanSuggestionKind

    var kindLabel: String {
        switch kind {
        case .recommendOnly: return "RECOMMEND"
        case .draftCandidate: return "DRAFT"
        case .warning: return "WARNING"
        }
    }
}

private extension PlanSlot {
    var regulationSlot: RegulationSlot {
        switch self {
        case .am: return .am
        case .pm: return .pm
        case .eve: return .eve
        }
    }
}

private extension RegulationSlot {
    var planSlot: PlanSlot {
        switch self {
        case .am: return .am
        case .pm: return .pm
        case .eve: return .eve
        }
    }
}

struct PlanRegulatorSummary: Equatable {
    let placedSessions: Int
    let unscheduledSessions: Int
    let spreadDays: Int
    let isBalanced: Bool
    let hasCalendarConflicts: Bool
    let unscheduledNeeds: [PlanRegulatorUnscheduledNeed]

    static let empty = PlanRegulatorSummary(
        placedSessions: 0,
        unscheduledSessions: 0,
        spreadDays: 0,
        isBalanced: false,
        hasCalendarConflicts: false,
        unscheduledNeeds: []
    )
}

struct PlanRegulatorUnscheduledNeed: Equatable {
    let protocolTitle: String
    let unmetSessions: Int
}

private extension PreferredExecutionSlot {
    var regulationPreference: ProtocolTimePreference {
        switch self {
        case .none: return .none
        case .am: return .am
        case .pm: return .pm
        case .eve: return .eve
        }
    }
}
