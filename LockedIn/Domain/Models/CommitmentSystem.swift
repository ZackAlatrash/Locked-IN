import Foundation

struct CommitmentSystem: Codable, Equatable {
    var nonNegotiables: [NonNegotiable]
    let createdAt: Date
    var recoveryCleanDayStreak: Int
    var lastRecoveryEvaluationDay: Date?
    var recoveryEntryPendingResolution: Bool
    var recoveryEntryRequiresPauseSelection: Bool
    var recoveryEntryTriggerProtocolId: UUID?
    var recoveryPausedProtocolId: UUID?

    init(
        nonNegotiables: [NonNegotiable],
        createdAt: Date,
        recoveryCleanDayStreak: Int = 0,
        lastRecoveryEvaluationDay: Date? = nil,
        recoveryEntryPendingResolution: Bool = false,
        recoveryEntryRequiresPauseSelection: Bool = false,
        recoveryEntryTriggerProtocolId: UUID? = nil,
        recoveryPausedProtocolId: UUID? = nil
    ) {
        self.nonNegotiables = nonNegotiables
        self.createdAt = createdAt
        self.recoveryCleanDayStreak = recoveryCleanDayStreak
        self.lastRecoveryEvaluationDay = lastRecoveryEvaluationDay
        self.recoveryEntryPendingResolution = recoveryEntryPendingResolution
        self.recoveryEntryRequiresPauseSelection = recoveryEntryRequiresPauseSelection
        self.recoveryEntryTriggerProtocolId = recoveryEntryTriggerProtocolId
        self.recoveryPausedProtocolId = recoveryPausedProtocolId
    }

    private enum CodingKeys: String, CodingKey {
        case nonNegotiables
        case createdAt
        case recoveryCleanDayStreak
        case lastRecoveryEvaluationDay
        case recoveryEntryPendingResolution
        case recoveryEntryRequiresPauseSelection
        case recoveryEntryTriggerProtocolId
        case recoveryPausedProtocolId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nonNegotiables = try container.decode([NonNegotiable].self, forKey: .nonNegotiables)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        recoveryCleanDayStreak = try container.decodeIfPresent(Int.self, forKey: .recoveryCleanDayStreak) ?? 0
        lastRecoveryEvaluationDay = try container.decodeIfPresent(Date.self, forKey: .lastRecoveryEvaluationDay)
        recoveryEntryPendingResolution = try container.decodeIfPresent(Bool.self, forKey: .recoveryEntryPendingResolution) ?? false
        recoveryEntryRequiresPauseSelection = try container.decodeIfPresent(Bool.self, forKey: .recoveryEntryRequiresPauseSelection) ?? false
        recoveryEntryTriggerProtocolId = try container.decodeIfPresent(UUID.self, forKey: .recoveryEntryTriggerProtocolId)
        recoveryPausedProtocolId = try container.decodeIfPresent(UUID.self, forKey: .recoveryPausedProtocolId)
    }

    var activeNonNegotiables: [NonNegotiable] {
        nonNegotiables.filter { $0.state == .active }
    }

    var suspendedNonNegotiables: [NonNegotiable] {
        nonNegotiables.filter { $0.state == .suspended }
    }

    var recoveringNonNegotiables: [NonNegotiable] {
        nonNegotiables.filter { $0.state == .recovery }
    }

    var allowedCapacity: Int {
        recoveringNonNegotiables.isEmpty ? 3 : 2
    }
}
