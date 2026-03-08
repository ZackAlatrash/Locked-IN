import Foundation
import Combine

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: MainTab = .cockpit
    @Published var pendingPlanFocusProtocolId: UUID?
    @Published var pendingPlanEditProtocolId: UUID?
    @Published var presentDailyCheckIn = false
    @Published var presentRecoveryEntry = false

    func openPlan(protocolId: UUID?) {
        selectedTab = .plan
        pendingPlanFocusProtocolId = protocolId
    }

    func consumePlanFocusIntent() {
        pendingPlanFocusProtocolId = nil
    }

    func openPlanEditor(protocolId: UUID) {
        selectedTab = .plan
        pendingPlanFocusProtocolId = protocolId
        pendingPlanEditProtocolId = protocolId
    }

    func consumePlanEditIntent() {
        pendingPlanEditProtocolId = nil
    }

    func requestDailyCheckInPresentation() {
        presentDailyCheckIn = true
    }

    func dismissDailyCheckIn() {
        presentDailyCheckIn = false
    }

    func requestRecoveryEntryPresentation() {
        presentRecoveryEntry = true
    }

    func dismissRecoveryEntry() {
        presentRecoveryEntry = false
    }
}
