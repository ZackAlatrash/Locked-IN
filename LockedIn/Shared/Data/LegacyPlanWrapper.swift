import Foundation

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
}
