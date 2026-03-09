import Foundation
import Combine

@MainActor
final class PlanCoordinator: ObservableObject {
    private weak var router: AppRouter?
    private weak var viewModel: PlanViewModel?
    
    init() {}
    
    func bind(router: AppRouter, viewModel: PlanViewModel) {
        self.router = router
        self.viewModel = viewModel
    }
    
    func handleRoutingIntents(focusId: UUID?, editId: UUID?, reduceMotion: Bool, setExpandedWeek: @escaping () -> Void) {
        if let editId = editId {
            viewModel?.openProtocolEditor(protocolId: editId)
            setExpandedWeek()
            router?.consumePlanEditIntent()
        }
        
        if let focusId = focusId {
            viewModel?.focusProtocol(id: focusId)
            setExpandedWeek()
            router?.consumePlanFocusIntent()
        }
    }
}
