import Foundation
import Combine

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: MainTab = .cockpit
    @Published var pendingPlanFocusProtocolId: UUID?
    @Published var presentDailyCheckIn = false

    func openPlan(protocolId: UUID?) {
        selectedTab = .plan
        pendingPlanFocusProtocolId = protocolId
    }

    func consumePlanFocusIntent() {
        pendingPlanFocusProtocolId = nil
    }

    func requestDailyCheckInPresentation() {
        presentDailyCheckIn = true
    }

    func dismissDailyCheckIn() {
        presentDailyCheckIn = false
    }
}
