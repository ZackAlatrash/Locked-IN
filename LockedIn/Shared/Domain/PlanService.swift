import Foundation

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
}
