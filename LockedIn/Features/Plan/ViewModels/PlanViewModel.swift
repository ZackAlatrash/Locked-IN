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
    @Published private(set) var hasTrackableProtocols = false

    @Published var selectedAllocation: PlanAllocation?

    private let calendarProvider: PlanCalendarProviding
    private var cancellables: Set<AnyCancellable> = []

    private weak var planStore: PlanStore?
    private weak var commitmentStore: CommitmentSystemStore?

    init(calendarProvider: PlanCalendarProviding = MockPlanCalendarProvider()) {
        self.calendarProvider = calendarProvider
    }

    var weekSubtitle: String {
        planStore?.weekSubtitle ?? ""
    }

    func bind(planStore: PlanStore, commitmentStore: CommitmentSystemStore) {
        let needsRebind = self.planStore !== planStore || self.commitmentStore !== commitmentStore
        guard needsRebind else { return }

        cancellables.removeAll()

        self.planStore = planStore
        self.commitmentStore = commitmentStore

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

        planStore.$hasTrackableProtocols
            .sink { [weak self] in self?.hasTrackableProtocols = $0 }
            .store(in: &cancellables)

        commitmentStore.$system
            .sink { [weak self] _ in
                self?.refresh(referenceDate: Date())
            }
            .store(in: &cancellables)

        refresh(referenceDate: Date())
    }

    func refresh(referenceDate: Date = Date()) {
        guard let planStore, let commitmentStore else { return }
        let week = DateRules.weekInterval(containing: referenceDate, calendar: DateRules.isoCalendar)
        let events = calendarProvider.events(for: week, calendar: DateRules.isoCalendar)
        planStore.refresh(system: commitmentStore.system, calendarEvents: events, referenceDate: referenceDate)
    }

    func protocolTitle(for id: UUID) -> String {
        planStore?.protocolTitle(for: id) ?? "Protocol"
    }

    func selectProtocol(id: UUID) {
        planStore?.selectProtocol(id)
    }

    func clearWarning() {
        planStore?.clearWarning()
    }

    func placeSelectedProtocol(day: Date, slot: PlanSlot) {
        planStore?.placeSelectedProtocol(day: day, slot: slot)
    }

    func placeProtocol(protocolId: UUID, day: Date, slot: PlanSlot) {
        planStore?.placeProtocol(protocolId: protocolId, day: day, slot: slot)
    }

    func editAllocation(allocationId: UUID) {
        selectedAllocation = planStore?.allocation(id: allocationId)
    }

    func removeAllocation(allocationId: UUID) {
        planStore?.removeAllocation(id: allocationId)
        selectedAllocation = nil
    }

    func moveAllocation(allocationId: UUID, to day: Date, slot: PlanSlot) {
        planStore?.moveAllocation(id: allocationId, newDay: day, newSlot: slot)
        selectedAllocation = nil
    }
}
