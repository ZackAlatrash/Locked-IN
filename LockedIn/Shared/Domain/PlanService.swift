import Foundation
import Combine

@MainActor
protocol PlanService {
    func reconcileAfterCompletion(
        protocolId: UUID,
        mode: NonNegotiableMode,
        completionDate: Date,
        completionKind: CompletionKind
    ) -> PlanCompletionReconciliationOutcome
    
    func pauseAllocations(for protocolId: UUID, referenceDate: Date)
    func currentWeekSnapshot() -> PlanWeekSnapshot
    
    var currentWeekDaysPublisher: AnyPublisher<[PlanDayModel], Never> { get }
    var queueItemsPublisher: AnyPublisher<[PlanQueueItem], Never> { get }
    var selectedQueueProtocolIdPublisher: AnyPublisher<UUID?, Never> { get }
    var todaySummaryPublisher: AnyPublisher<PlanTodaySummary, Never> { get }
    var structureStatusPublisher: AnyPublisher<PlanStructureStatus, Never> { get }
    var structureMessagePublisher: AnyPublisher<String, Never> { get }
    var warningMessagePublisher: AnyPublisher<String?, Never> { get }
    var warningReasonPublisher: AnyPublisher<PolicyReason?, Never> { get }
    var hasTrackableProtocolsPublisher: AnyPublisher<Bool, Never> { get }
    
    var weekSubtitle: String { get }
    func protocolTitle(for id: UUID) -> String
    func validateProtocolPlacement(protocolId: UUID, day: Date, slot: PlanSlot, context: PlanValidationContext) -> PlanPlacementValidation
    func validateMove(allocationId: UUID, day: Date, slot: PlanSlot) -> PlanPlacementValidation
    func selectProtocol(_ id: UUID)
    func focusProtocol(_ id: UUID?)
    func clearWarning()
    @discardableResult func placeSelectedProtocol(day: Date, slot: PlanSlot) -> PlanMutation?
    @discardableResult func placeProtocol(protocolId: UUID, day: Date, slot: PlanSlot) -> PlanMutation?
    func allocation(id: UUID) -> PlanAllocation?
    func removeAllocation(id: UUID)
    @discardableResult func moveAllocation(id: UUID, newDay: Date, newSlot: PlanSlot) -> PlanMutation?
    func validateDraft(_ allocations: [PlanAllocationDraft]) -> [PlanSuggestion]
    func applyDraft(_ allocations: [PlanAllocationDraft]) -> Result<Int, PlanDraftApplyError>
    func refresh(system: CommitmentSystem, calendarEvents: [PlanCalendarEvent], referenceDate: Date)
}
