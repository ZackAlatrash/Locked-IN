import Foundation
import Combine

@MainActor
final class AppRouter: ObservableObject {
    // Plan intent lifecycle contract:
    // - Each intent is a single pending slot (last write wins).
    // - Consuming an intent clears only that intent slot.
    // - Re-consuming with no pending value is a no-op.
    @Published var selectedTab: MainTab = .cockpit
    @Published var pendingPlanFocusProtocolId: UUID?
    @Published var pendingPlanEditProtocolId: UUID?
    @Published var presentDailyCheckIn = false
    @Published var presentRecoveryEntry = false

    /// Routes to the plan tab and replaces the pending focus intent.
    func openPlan(protocolId: UUID?) {
        selectedTab = .plan
        pendingPlanFocusProtocolId = protocolId
    }

    /// Consumes only the pending plan focus intent.
    func consumePlanFocusIntent() {
        pendingPlanFocusProtocolId = nil
    }

    /// Routes to the plan tab and replaces both focus and edit intents.
    func openPlanEditor(protocolId: UUID) {
        selectedTab = .plan
        pendingPlanFocusProtocolId = protocolId
        pendingPlanEditProtocolId = protocolId
    }

    /// Consumes only the pending plan edit intent.
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
