import Foundation

struct CommitmentSystem: Codable, Equatable {
    var nonNegotiables: [NonNegotiable]
    let createdAt: Date
    var recoveryCleanDayStreak: Int
    var lastRecoveryEvaluationDay: Date?

    init(
        nonNegotiables: [NonNegotiable],
        createdAt: Date,
        recoveryCleanDayStreak: Int = 0,
        lastRecoveryEvaluationDay: Date? = nil
    ) {
        self.nonNegotiables = nonNegotiables
        self.createdAt = createdAt
        self.recoveryCleanDayStreak = recoveryCleanDayStreak
        self.lastRecoveryEvaluationDay = lastRecoveryEvaluationDay
    }

    private enum CodingKeys: String, CodingKey {
        case nonNegotiables
        case createdAt
        case recoveryCleanDayStreak
        case lastRecoveryEvaluationDay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nonNegotiables = try container.decode([NonNegotiable].self, forKey: .nonNegotiables)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        recoveryCleanDayStreak = try container.decodeIfPresent(Int.self, forKey: .recoveryCleanDayStreak) ?? 0
        lastRecoveryEvaluationDay = try container.decodeIfPresent(Date.self, forKey: .lastRecoveryEvaluationDay)
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
