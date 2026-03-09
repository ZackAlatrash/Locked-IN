import Foundation
import Combine

@MainActor
final class LegacyPlanWrapper: PlanService {
    private let store: PlanStore
    
    init(store: PlanStore) {
        self.store = store
    }
    
    func reconcileAfterCompletion(
        protocolId: UUID,
        mode: NonNegotiableMode,
        completionDate: Date,
        completionKind: CompletionKind
    ) -> PlanCompletionReconciliationOutcome {
        store.reconcileAfterCompletion(
            protocolId: protocolId,
            mode: mode,
            completionDate: completionDate,
            completionKind: completionKind
        )
    }
    
    func pauseAllocations(for protocolId: UUID, referenceDate: Date) {
        store.pauseAllocations(for: protocolId, referenceDate: referenceDate)
    }
    
    func currentWeekSnapshot() -> PlanWeekSnapshot {
        store.currentWeekSnapshot()
    }
    
    var currentWeekDaysPublisher: AnyPublisher<[PlanDayModel], Never> { store.$currentWeekDays.eraseToAnyPublisher() }
    var queueItemsPublisher: AnyPublisher<[PlanQueueItem], Never> { store.$queueItems.eraseToAnyPublisher() }
    var selectedQueueProtocolIdPublisher: AnyPublisher<UUID?, Never> { store.$selectedQueueProtocolId.eraseToAnyPublisher() }
    var todaySummaryPublisher: AnyPublisher<PlanTodaySummary, Never> { store.$todaySummary.eraseToAnyPublisher() }
    var structureStatusPublisher: AnyPublisher<PlanStructureStatus, Never> { store.$structureStatus.eraseToAnyPublisher() }
    var structureMessagePublisher: AnyPublisher<String, Never> { store.$structureMessage.eraseToAnyPublisher() }
    var warningMessagePublisher: AnyPublisher<String?, Never> { store.$warningMessage.eraseToAnyPublisher() }
    var warningReasonPublisher: AnyPublisher<PolicyReason?, Never> { store.$warningReason.eraseToAnyPublisher() }
    var hasTrackableProtocolsPublisher: AnyPublisher<Bool, Never> { store.$hasTrackableProtocols.eraseToAnyPublisher() }
    
    var weekSubtitle: String { store.weekSubtitle }
    func protocolTitle(for id: UUID) -> String { store.protocolTitle(for: id) }
    func validateProtocolPlacement(protocolId: UUID, day: Date, slot: PlanSlot, context: PlanValidationContext) -> PlanPlacementValidation {
        store.validateProtocolPlacement(protocolId: protocolId, day: day, slot: slot, context: context)
    }
    func validateMove(allocationId: UUID, day: Date, slot: PlanSlot) -> PlanPlacementValidation {
        store.validateMove(allocationId: allocationId, day: day, slot: slot)
    }
    func selectProtocol(_ id: UUID) { store.selectProtocol(id) }
    func focusProtocol(_ id: UUID?) { store.focusProtocol(id) }
    func clearWarning() { store.clearWarning() }
    func placeSelectedProtocol(day: Date, slot: PlanSlot) -> PlanMutation? { store.placeSelectedProtocol(day: day, slot: slot) }
    func placeProtocol(protocolId: UUID, day: Date, slot: PlanSlot) -> PlanMutation? { store.placeProtocol(protocolId: protocolId, day: day, slot: slot) }
    func allocation(id: UUID) -> PlanAllocation? { store.allocation(id: id) }
    func removeAllocation(id: UUID) { store.removeAllocation(id: id) }
    func moveAllocation(id: UUID, newDay: Date, newSlot: PlanSlot) -> PlanMutation? { store.moveAllocation(id: id, newDay: newDay, newSlot: newSlot) }
    func validateDraft(_ allocations: [PlanAllocationDraft]) -> [PlanSuggestion] { store.validateDraft(allocations) }
    func applyDraft(_ allocations: [PlanAllocationDraft]) -> Result<Int, PlanDraftApplyError> { store.applyDraft(allocations) }
    func refresh(system: CommitmentSystem, calendarEvents: [PlanCalendarEvent], referenceDate: Date) {
        store.refresh(system: system, calendarEvents: calendarEvents, referenceDate: referenceDate)
    }
}
