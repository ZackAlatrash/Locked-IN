import Foundation

enum PreferredExecutionSlot: String, Codable, Equatable, CaseIterable {
    case none
    case am
    case pm
    case eve

    var title: String {
        switch self {
        case .none: return "Any"
        case .am: return "AM"
        case .pm: return "PM"
        case .eve: return "EVE"
        }
    }
}

struct NonNegotiableDefinition: Codable, Equatable {
    let title: String
    let frequencyPerWeek: Int
    let mode: NonNegotiableMode
    let goalId: UUID
    let preferredExecutionSlot: PreferredExecutionSlot
    let estimatedDurationMinutes: Int
    let iconSystemName: String

    static let minimumDurationMinutes = 5
    static let maximumDurationMinutes = 360

    init(
        title: String,
        frequencyPerWeek: Int,
        mode: NonNegotiableMode,
        goalId: UUID,
        preferredExecutionSlot: PreferredExecutionSlot = .none,
        estimatedDurationMinutes: Int? = nil,
        iconSystemName: String? = nil
    ) {
        self.title = title
        self.mode = mode
        self.goalId = goalId
        self.preferredExecutionSlot = preferredExecutionSlot
        self.frequencyPerWeek = Self.normalizedFrequency(frequencyPerWeek, mode: mode)
        self.estimatedDurationMinutes = estimatedDurationMinutes ?? Self.defaultEstimatedDurationMinutes(for: mode)
        self.iconSystemName = Self.normalizedIconSystemName(
            iconSystemName,
            mode: mode,
            title: title
        )
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case frequencyPerWeek
        case mode
        case goalId
        case preferredExecutionSlot
        case estimatedDurationMinutes
        case iconSystemName

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
        let preferredExecutionSlot = try container.decodeIfPresent(PreferredExecutionSlot.self, forKey: .preferredExecutionSlot) ?? .none
        let rawDuration = try container.decodeIfPresent(Int.self, forKey: .estimatedDurationMinutes)
            ?? Self.defaultEstimatedDurationMinutes(for: mode)
        let estimatedDurationMinutes = Self.validatedDurationOrDefault(rawDuration, mode: mode)
        let iconSystemName = try container.decodeIfPresent(String.self, forKey: .iconSystemName)

        self.init(
            title: title,
            frequencyPerWeek: decodedFrequency,
            mode: mode,
            goalId: goalId,
            preferredExecutionSlot: preferredExecutionSlot,
            estimatedDurationMinutes: estimatedDurationMinutes,
            iconSystemName: iconSystemName
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(Self.normalizedFrequency(frequencyPerWeek, mode: mode), forKey: .frequencyPerWeek)
        try container.encode(mode, forKey: .mode)
        try container.encode(goalId, forKey: .goalId)
        try container.encode(preferredExecutionSlot, forKey: .preferredExecutionSlot)
        try container.encode(estimatedDurationMinutes, forKey: .estimatedDurationMinutes)
        try container.encode(iconSystemName, forKey: .iconSystemName)
    }

    static func normalizedFrequency(_ frequencyPerWeek: Int, mode: NonNegotiableMode) -> Int {
        mode == .daily ? 7 : frequencyPerWeek
    }

    static func defaultEstimatedDurationMinutes(for mode: NonNegotiableMode) -> Int {
        mode == .daily ? 15 : 60
    }

    static func isValidEstimatedDuration(_ duration: Int) -> Bool {
        (minimumDurationMinutes...maximumDurationMinutes).contains(duration)
    }

    static func isValidIconSystemName(_ name: String) -> Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private static func inferredLegacyMode(from decodedFrequency: Int) -> NonNegotiableMode {
        decodedFrequency == 7 ? .daily : .session
    }

    private static func validatedDurationOrDefault(_ duration: Int, mode: NonNegotiableMode) -> Int {
        isValidEstimatedDuration(duration) ? duration : defaultEstimatedDurationMinutes(for: mode)
    }

    static func normalizedIconSystemName(
        _ iconSystemName: String?,
        mode: NonNegotiableMode,
        title: String
    ) -> String {
        let trimmed = iconSystemName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if isValidIconSystemName(trimmed) {
            return trimmed
        }
        return defaultIconSystemName(for: mode, title: title)
    }

    static func defaultIconSystemName(for mode: NonNegotiableMode, title: String = "") -> String {
        let lower = title.lowercased()
        if lower.contains("hydrat") || lower.contains("water") { return "drop.fill" }
        if lower.contains("drill") || lower.contains("neural") { return "brain.head.profile" }
        if lower.contains("deep") || lower.contains("focus") { return "bolt.fill" }
        if lower.contains("iso") || lower.contains("strength") { return "figure.strengthtraining.traditional" }
        return mode == .daily ? "checkmark.circle.fill" : "bolt.fill"
    }
}
