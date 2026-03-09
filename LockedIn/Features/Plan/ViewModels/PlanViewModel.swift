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

    private let planService: PlanService
    private let commitmentService: CommitmentActionService

    init(
        planService: PlanService,
        commitmentService: CommitmentActionService,
        calendarProvider: PlanCalendarProviding? = nil,
        regulatorEngine: PlanRegulatorEngine? = nil
    ) {
        self.planService = planService
        self.commitmentService = commitmentService
        self.calendarProvider = calendarProvider ?? AppleCalendarProvider()
        self.regulatorEngine = regulatorEngine ?? PlanRegulatorEngine()
        setupSubscriptions()
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
        planService.weekSubtitle
    }

    func setReferenceDateProvider(_ provider: @escaping () -> Date) {
        referenceDateProvider = provider
    }

    private func setupSubscriptions() {
        calendarAccessStatus = calendarProvider.authorizationStatus()

        planService.currentWeekDaysPublisher
            .sink { [weak self] in self?.currentWeekDays = $0 }
            .store(in: &cancellables)

        planService.queueItemsPublisher
            .sink { [weak self] in self?.queueItems = $0 }
            .store(in: &cancellables)

        planService.selectedQueueProtocolIdPublisher
            .sink { [weak self] in self?.selectedQueueProtocolId = $0 }
            .store(in: &cancellables)

        planService.todaySummaryPublisher
            .sink { [weak self] in self?.todaySummary = $0 }
            .store(in: &cancellables)

        planService.structureStatusPublisher
            .sink { [weak self] in self?.structureStatus = $0 }
            .store(in: &cancellables)

        planService.structureMessagePublisher
            .sink { [weak self] in self?.structureMessage = $0 }
            .store(in: &cancellables)

        planService.warningMessagePublisher
            .sink { [weak self] in self?.warningMessage = $0 }
            .store(in: &cancellables)

        planService.warningReasonPublisher
            .sink { [weak self] reason in
                self?.warningCopy = reason?.copy()
            }
            .store(in: &cancellables)

        planService.hasTrackableProtocolsPublisher
            .sink { [weak self] in self?.hasTrackableProtocols = $0 }
            .store(in: &cancellables)

        commitmentService.systemPublisher
            .sink { [weak self] _ in
                self?.refresh(referenceDate: self?.currentReferenceDate())
            }
            .store(in: &cancellables)

        refresh(referenceDate: currentReferenceDate())
    }

    func refresh(referenceDate: Date? = nil) {
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
        
        var currentSystem: CommitmentSystem?
        commitmentService.systemPublisher.prefix(1).sink { system in
            currentSystem = system
        }.store(in: &cancellables)
        
        if let currentSystem = currentSystem {
            planService.refresh(system: currentSystem, calendarEvents: events, referenceDate: referenceDate)
        }
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
        planService.protocolTitle(for: id)
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
        planService.validateProtocolPlacement(protocolId: protocolId, day: day, slot: slot, context: .manual)
    }

    func validateMove(allocationId: UUID, day: Date, slot: PlanSlot) -> PlanPlacementValidation {
        planService.validateMove(allocationId: allocationId, day: day, slot: slot)
    }

    func selectProtocol(id: UUID) {
        planService.selectProtocol(id)
    }

    func focusProtocol(id: UUID?) {
        planService.focusProtocol(id)
    }

    func clearWarning() {
        planService.clearWarning()
    }

    @discardableResult
    func placeSelectedProtocol(day: Date, slot: PlanSlot) -> PlanMutation? {
        planService.placeSelectedProtocol(day: day, slot: slot)
    }

    @discardableResult
    func placeProtocol(protocolId: UUID, day: Date, slot: PlanSlot) -> PlanMutation? {
        planService.placeProtocol(protocolId: protocolId, day: day, slot: slot)
    }

    func editAllocation(allocationId: UUID) {
        selectedAllocation = planService.allocation(id: allocationId)
    }

    func removeAllocation(allocationId: UUID) {
        planService.removeAllocation(id: allocationId)
        selectedAllocation = nil
    }

    @discardableResult
    func moveAllocation(allocationId: UUID, to day: Date, slot: PlanSlot) -> PlanMutation? {
        let mutation = planService.moveAllocation(id: allocationId, newDay: day, newSlot: slot)
        selectedAllocation = nil
        return mutation
    }

    func runRegulator() {
        var currentSystem: CommitmentSystem?
        commitmentService.systemPublisher.prefix(1).sink { system in
            currentSystem = system
        }.store(in: &cancellables)
        guard let system = currentSystem else { return }

        let snapshot = planService.currentWeekSnapshot()
        let activeAllocations = snapshot.currentWeekAllocations.filter { $0.status == .active }
        let protocols = buildProtocolPlanItems(
            system: system,
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
        let validationWarnings = planService.validateDraft(draft.suggestedAllocations)
        let mergedSuggestions = draft.suggestions + validationWarnings

        draftAllocations = draft.suggestedAllocations
        hasDraft = draftAllocations.isEmpty == false
        regulatorSuggestions = mapSuggestionUIModels(mergedSuggestions)
        showingRegulatorSheet = true

        let protocolsNeedingPlacement = protocols.filter { protocolItem in
            let remaining: Int
            switch protocolItem.mode {
            case .session:
                remaining = max(0, protocolItem.frequencyPerWeek - protocolItem.completionsThisWeek - protocolItem.plannedThisWeek)
            case .daily:
                remaining = max(0, 7 - protocolItem.completionsThisWeek - protocolItem.plannedThisWeek)
            }
            return remaining > 0
        }.count

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
        guard hasDraft else { return false }

        let result = planService.applyDraft(draftAllocations)
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
        var currentSystem: CommitmentSystem?
        commitmentService.systemPublisher.prefix(1).sink { system in
            currentSystem = system
        }.store(in: &cancellables)
        guard let system = currentSystem else { return }
        
        guard let nonNegotiable = system.nonNegotiables.first(where: { $0.id == protocolId }) else {
            return
        }
        let referenceDate = currentReferenceDate()
        let editableFields = commitmentService.allowedEditableFields(for: protocolId, referenceDate: referenceDate)
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
        do {
            try commitmentService.editNonNegotiable(
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
                    guard let slotInterval = slot.interval(on: day, calendar: DateRules.isoCalendar) else {
                        return false
                    }
                    if event.isAllDay {
                        guard let dayEnd = DateRules.isoCalendar.date(byAdding: .day, value: 1, to: day) else {
                            return false
                        }
                        let dayInterval = DateInterval(start: day, end: dayEnd)
                        let eventInterval = DateInterval(start: event.startDateTime, end: event.endDateTime)
                        return eventInterval.intersects(dayInterval)
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
            if (0...6).contains(suggestion.dayIndex) {
                let start = planService.currentWeekSnapshot().weekStartDate
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
                protocolTitle: planService.protocolTitle(for: suggestion.protocolId),
                dayLabel: dayLabel,
                slotLabel: suggestion.slot.title,
                confidence: suggestion.confidence,
                confidenceLabel: "\(Int((suggestion.confidence * 100).rounded()))%",
                reason: suggestion.reason,
                kind: suggestion.kind
            )
        }
    }

    func currentReferenceDate() -> Date {
        referenceDateProvider()
    }

    func mapProtocolEditError(_ error: Error) -> String {
        if let copy = commitmentService.policyCopy(for: error) {
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
