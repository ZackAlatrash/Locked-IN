import Foundation

struct DailyCheckInOverviewModel: Equatable {
    let dateLabel: String
    let modeLabel: String
    let reliabilityScore: Int
    let streakDays: Int
    let completedCount: Int
    let needsAttentionCount: Int
}

struct DailyCheckInProtocolItem: Identifiable, Equatable {
    let id: UUID
    let protocolId: UUID
    let title: String
    let iconSystemName: String
    let modeLabel: String
    let statusText: String
    let remainingWeekText: String?
    let completedToday: Bool
    let isExtraToday: Bool
    let needsAttention: Bool
    let isSuspended: Bool
    let canMarkDone: Bool
    let canResolve: Bool
    let actionTitle: String
    let actionDisabledReason: String?
}

enum DailyCheckInFlowStep: Equatable {
    case overview
    case resolve(protocolId: UUID)
    case recommendation(protocolId: UUID)
    case closeDay
}

struct DailyCheckInRecommendationModel: Equatable {
    let protocolId: UUID
    let protocolTitle: String
    let dayLabel: String
    let slotLabel: String
    let durationLabel: String
    let confidenceLabel: String
    let reason: String
    let draft: PlanAllocationDraft
}

struct DailyCheckInDismissOutcome {
    let completed: Bool
    let unresolvedCount: Int
}
