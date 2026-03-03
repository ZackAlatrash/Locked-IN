import Foundation

enum PlanSlot: String, CaseIterable, Codable, Identifiable {
    case am
    case pm
    case eve

    var id: String { rawValue }

    var title: String {
        switch self {
        case .am: return "AM"
        case .pm: return "PM"
        case .eve: return "EVE"
        }
    }

    var axisTitle: String {
        switch self {
        case .am: return "Morning"
        case .pm: return "Afternoon"
        case .eve: return "Evening"
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

enum PlanTone: String, Codable, CaseIterable {
    case cyan
    case indigo
    case purple
    case amber
    case blue
}

enum PlanStructureStatus {
    case structural
    case fragile
    case unstructured

    var title: String {
        switch self {
        case .structural: return "STRUCTURAL"
        case .fragile: return "FRAGILE"
        case .unstructured: return "UNSTRUCTURED"
        }
    }

    var icon: String {
        switch self {
        case .structural: return "checkmark.seal.fill"
        case .fragile: return "exclamationmark.triangle.fill"
        case .unstructured: return "xmark.octagon.fill"
        }
    }
}

struct PlanCalendarEvent: Identifiable, Equatable {
    let id: UUID
    let title: String?
    let startDateTime: Date
    let endDateTime: Date
    let isAllDay: Bool
    let sourceCalendarName: String?
}

struct PlanAllocation: Codable, Equatable, Identifiable {
    let id: UUID
    let protocolId: UUID
    let weekId: WeekID
    let day: Date
    let slot: PlanSlot
    let startTime: Date?
    let durationMinutes: Int?
    let createdAt: Date
    var updatedAt: Date
}

struct PlanQueueItem: Identifiable {
    let id: UUID
    let protocolId: UUID
    let title: String
    let remainingCount: Int
    let durationLabel: String
    let requiredMinutes: Int
    let isDisabled: Bool
    let mode: NonNegotiableMode
    let tone: PlanTone
}

struct PlanAllocationDisplay: Identifiable {
    let id: UUID
    let protocolId: UUID
    let title: String
    let tone: PlanTone
    let icon: String
    let durationLabel: String
    let durationMinutes: Int
}

struct PlanSlotModel: Identifiable {
    let id: String
    let slot: PlanSlot
    let busyEvents: [PlanCalendarEvent]
    let allocations: [PlanAllocationDisplay]
    let busyMinutes: Int
    let plannedMinutes: Int
    let freeCapacityBeforePlanning: Int
    let freeMinutes: Int
    let availableLabel: String
}

struct PlanDayModel: Identifiable {
    let id: Date
    let date: Date
    let weekdayLabel: String
    let dayNumberLabel: String
    let isToday: Bool
    let slots: [PlanSlotModel]
    let busyMinutesTotal: Int
    let freeMinutesTotal: Int
    let plannedCount: Int
}

struct PlanTodaySummary {
    let busyMinutes: Int
    let freeMinutes: Int
    let plannedCount: Int
    let remainingSessions: Int

    static let empty = PlanTodaySummary(
        busyMinutes: 0,
        freeMinutes: 0,
        plannedCount: 0,
        remainingSessions: 0
    )
}

enum PlanPlacementValidation: Equatable {
    case allowed
    case blocked(message: String)

    var isAllowed: Bool {
        if case .allowed = self { return true }
        return false
    }

    var message: String? {
        switch self {
        case .allowed:
            return nil
        case .blocked(let message):
            return message
        }
    }
}

enum PlanMutation {
    case placed(
        allocationId: UUID,
        protocolTitle: String,
        day: Date,
        slot: PlanSlot
    )
    case moved(
        allocationId: UUID,
        protocolTitle: String,
        fromDay: Date,
        fromSlot: PlanSlot,
        toDay: Date,
        toSlot: PlanSlot
    )
}

protocol PlanCalendarProviding {
    func events(for week: DateInterval, calendar: Calendar) -> [PlanCalendarEvent]
}

struct MockPlanCalendarProvider: PlanCalendarProviding {
    func events(for week: DateInterval, calendar: Calendar) -> [PlanCalendarEvent] {
        let base = DateRules.startOfDay(week.start, calendar: calendar)
        let templates: [(Int, Int, Int, String)] = [
            (0, 8, 9, "Standup"),
            (0, 10, 11, "Sync"),
            (1, 14, 16, "Client Call"),
            (2, 10, 12, "Deep Meeting"),
            (3, 8, 9, "Review"),
            (4, 12, 14, "Product Sync"),
            (5, 18, 20, "Family Event")
        ]

        return templates.compactMap { dayOffset, startHour, endHour, title in
            guard
                let day = calendar.date(byAdding: .day, value: dayOffset, to: base),
                let start = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: day),
                let end = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: day)
            else { return nil }

            return PlanCalendarEvent(
                id: UUID(),
                title: title,
                startDateTime: start,
                endDateTime: end,
                isAllDay: false,
                sourceCalendarName: "Mock"
            )
        }
    }
}
