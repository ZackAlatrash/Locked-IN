import Foundation

enum ViolationKind: String, Codable, Equatable {
    case missedWeeklyFrequency
    case missedDailyCompliance
}

struct Violation: Codable, Equatable {
    let date: Date
    let kind: ViolationKind
    let windowIndex: Int
    let weekId: WeekID
    /// True when this violation occurred while the owning protocol was in .recovery or .suspended state.
    /// Persisted so log context survives retirement/state changes (LIF-EC-16).
    let wasRecoveryRelated: Bool

    init(date: Date, kind: ViolationKind, windowIndex: Int, weekId: WeekID, wasRecoveryRelated: Bool = false) {
        self.date = date
        self.kind = kind
        self.windowIndex = windowIndex
        self.weekId = weekId
        self.wasRecoveryRelated = wasRecoveryRelated
    }

    private enum CodingKeys: String, CodingKey {
        case date
        case kind
        case windowIndex
        case weekId
        case wasRecoveryRelated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        kind = try container.decode(ViolationKind.self, forKey: .kind)
        windowIndex = try container.decode(Int.self, forKey: .windowIndex)
        weekId = try container.decode(WeekID.self, forKey: .weekId)
        wasRecoveryRelated = try container.decodeIfPresent(Bool.self, forKey: .wasRecoveryRelated) ?? false
    }
}
