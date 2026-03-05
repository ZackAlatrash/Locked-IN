import Foundation

enum CompletionKind: String, Codable, Equatable {
    case counted
    case extra
}

struct CompletionRecord: Codable, Equatable {
    let date: Date
    let weekId: WeekID
    let kind: CompletionKind

    init(date: Date, weekId: WeekID, kind: CompletionKind = .counted) {
        self.date = date
        self.weekId = weekId
        self.kind = kind
    }

    private enum CodingKeys: String, CodingKey {
        case date
        case weekId
        case kind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        weekId = try container.decode(WeekID.self, forKey: .weekId)
        kind = try container.decodeIfPresent(CompletionKind.self, forKey: .kind) ?? .counted
    }
}
