import Foundation

enum CompletionKind: String, Codable, Equatable {
    case counted
    case extra
}

struct CompletionRecord: Codable, Equatable {
    let date: Date
    let weekId: WeekID
    let kind: CompletionKind
    /// True when this completion was recorded while the owning protocol was in .recovery or .suspended state.
    /// Persisted so log context survives retirement/state changes (LIF-EC-16).
    let wasRecoveryRelated: Bool

    init(date: Date, weekId: WeekID, kind: CompletionKind = .counted, wasRecoveryRelated: Bool = false) {
        self.date = date
        self.weekId = weekId
        self.kind = kind
        self.wasRecoveryRelated = wasRecoveryRelated
    }

    private enum CodingKeys: String, CodingKey {
        case date
        case weekId
        case kind
        case wasRecoveryRelated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        weekId = try container.decode(WeekID.self, forKey: .weekId)
        kind = try container.decodeIfPresent(CompletionKind.self, forKey: .kind) ?? .counted
        wasRecoveryRelated = try container.decodeIfPresent(Bool.self, forKey: .wasRecoveryRelated) ?? false
    }
}
