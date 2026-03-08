import Foundation

enum RecoveryFlowState: Equatable {
    case entry
    case selectProtocol
    case confirmed
}

struct RecoveryProtocolOption: Identifiable, Equatable {
    let id: UUID
    let title: String
    let modeLabel: String
    let weeklyLoadText: String
    let stateText: String
    let currentWindowViolations: Int
    let plannedLoadCount: Int
    let recoveryLoadScore: Int
    let isRecommended: Bool
}
