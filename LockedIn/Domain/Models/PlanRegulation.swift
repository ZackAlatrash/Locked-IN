import Foundation

enum RegulationSlot: String, CaseIterable, Codable, Equatable, Hashable {
    case am
    case pm
    case eve

    var title: String {
        switch self {
        case .am: return "AM"
        case .pm: return "PM"
        case .eve: return "EVE"
        }
    }

    var startHour: Int {
        switch self {
        case .am: return 6
        case .pm: return 12
        case .eve: return 18
        }
    }

    var durationMinutes: Int { 360 }

    func interval(on day: Date, calendar: Calendar) -> DateInterval? {
        guard let start = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: day) else {
            return nil
        }
        guard let end = calendar.date(byAdding: .minute, value: durationMinutes, to: start) else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }
}

enum ProtocolTimePreference: String, Codable, Equatable, Hashable {
    case none
    case am
    case pm
    case eve

    func matches(slot: RegulationSlot) -> Bool {
        switch self {
        case .none: return true
        case .am: return slot == .am
        case .pm: return slot == .pm
        case .eve: return slot == .eve
        }
    }
}

struct RegulationCalendarEvent: Equatable {
    let id: UUID
    let startDateTime: Date
    let endDateTime: Date
    let isAllDay: Bool
}

struct ProtocolPlanItem: Equatable {
    let id: UUID
    let title: String
    let mode: NonNegotiableMode
    let state: NonNegotiableState
    let frequencyPerWeek: Int
    let completionsThisWeek: Int
    let plannedThisWeek: Int
    let durationMinutes: Int
    let timePreference: ProtocolTimePreference
}

struct PlanRegulationRules: Equatable {
    let maxProtocolsPerDay: Int
    let maxProtocolsPerSlot: Int
    /// How strongly to honour a protocol's preferred time window. Higher = preference is more decisive.
    let preferenceWeight: Double
    /// How strongly to spread sessions across lightly-loaded days. Higher = avoids stacking.
    let avoidClumpingWeight: Double
    /// How much to favour earlier days in the week. Kept low — urgency is a weak signal.
    let urgencyWeight: Double

    init(
        maxProtocolsPerDay: Int = 3,
        maxProtocolsPerSlot: Int = 1,
        preferenceWeight: Double = 1.5,
        avoidClumpingWeight: Double = 1.0,
        urgencyWeight: Double = 0.3
    ) {
        self.maxProtocolsPerDay = maxProtocolsPerDay
        self.maxProtocolsPerSlot = maxProtocolsPerSlot
        self.preferenceWeight = preferenceWeight
        self.avoidClumpingWeight = avoidClumpingWeight
        self.urgencyWeight = urgencyWeight
    }
}

enum PlanSuggestionKind: String, Equatable {
    case recommendOnly
    case draftCandidate
    case warning
}

struct PlanSuggestion: Identifiable, Equatable {
    let id: UUID
    let protocolId: UUID
    let dayIndex: Int
    let slot: RegulationSlot
    let startTimeMinutesFromMidnight: Int?
    let durationMinutes: Int
    let confidence: Double
    let reason: String
    let kind: PlanSuggestionKind
}

struct ExistingAllocationSnapshot: Equatable {
    let protocolId: UUID
    let day: Date
    let slot: RegulationSlot
    let durationMinutes: Int
}

struct PlanAllocationDraft: Equatable {
    let protocolId: UUID
    let weekId: WeekID
    let day: Date
    let slot: RegulationSlot
    let durationMinutes: Int
}

struct PlanDraft: Equatable {
    let suggestedAllocations: [PlanAllocationDraft]
    let suggestions: [PlanSuggestion]
}

struct PlanRegulationInput: Equatable {
    let weekId: WeekID
    let weekStartDate: Date
    let protocols: [ProtocolPlanItem]
    let calendarEvents: [RegulationCalendarEvent]
    let existingAllocations: [ExistingAllocationSnapshot]
    let rules: PlanRegulationRules
}
