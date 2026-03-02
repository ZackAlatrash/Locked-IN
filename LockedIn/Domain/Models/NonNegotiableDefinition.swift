import Foundation

struct NonNegotiableDefinition: Codable, Equatable {
    let title: String
    let frequencyPerWeek: Int
    let mode: NonNegotiableMode
    let goalId: UUID

    init(
        title: String,
        frequencyPerWeek: Int,
        mode: NonNegotiableMode,
        goalId: UUID
    ) {
        self.title = title
        self.mode = mode
        self.goalId = goalId
        self.frequencyPerWeek = Self.normalizedFrequency(frequencyPerWeek, mode: mode)
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case frequencyPerWeek
        case mode
        case goalId

        // Legacy payload keys (decoded only, ignored in-memory)
        case minimumMinutes
        case timeWindowStartHour
        case timeWindowEndHour
        case frequency
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let title = try container.decode(String.self, forKey: .title)
        let goalId = try container.decode(UUID.self, forKey: .goalId)

        let decodedFrequency =
            try container.decodeIfPresent(Int.self, forKey: .frequencyPerWeek)
            ?? container.decodeIfPresent(Int.self, forKey: .frequency)
            ?? 1

        // Decode legacy keys if present so old JSON payloads migrate without failing decode.
        _ = try container.decodeIfPresent(Int.self, forKey: .minimumMinutes)
        _ = try container.decodeIfPresent(Int.self, forKey: .timeWindowStartHour)
        _ = try container.decodeIfPresent(Int.self, forKey: .timeWindowEndHour)

        let mode = try container.decodeIfPresent(NonNegotiableMode.self, forKey: .mode)
            ?? Self.inferredLegacyMode(from: decodedFrequency)

        self.init(
            title: title,
            frequencyPerWeek: decodedFrequency,
            mode: mode,
            goalId: goalId
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(Self.normalizedFrequency(frequencyPerWeek, mode: mode), forKey: .frequencyPerWeek)
        try container.encode(mode, forKey: .mode)
        try container.encode(goalId, forKey: .goalId)
    }

    static func normalizedFrequency(_ frequencyPerWeek: Int, mode: NonNegotiableMode) -> Int {
        mode == .daily ? 7 : frequencyPerWeek
    }

    private static func inferredLegacyMode(from decodedFrequency: Int) -> NonNegotiableMode {
        decodedFrequency == 7 ? .daily : .session
    }
}
