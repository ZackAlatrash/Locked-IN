import SwiftUI

enum PlanBoardMode {
    case focusToday
    case expandedWeek
}

struct PlanSlotDropFeedback {
    let isTargeted: Bool
    let isAllowed: Bool
    let message: String?
}

struct PlanDragPreview {
    let title: String
    let durationLabel: String
    let tone: PlanTone
}

struct BusyEventEntry: Identifiable {
    let id: String
    let event: PlanCalendarEvent
    let title: String
    let isContinuation: Bool
    let continuesFromPrevious: Bool
    let continuesToNext: Bool
}

struct PlanToast {
    let message: String
    let undoLabel: String
}

enum PlanUndoAction {
    case remove(allocationId: UUID)
    case move(allocationId: UUID, day: Date, slot: PlanSlot)
}

enum PlanDropPayload {
    static let queuePrefix = "queue:"
    static let allocationPrefix = "allocation:"

    static func queuePayload(for id: UUID) -> String {
        "\(queuePrefix)\(id.uuidString)"
    }

    static func allocationPayload(for id: UUID) -> String {
        "\(allocationPrefix)\(id.uuidString)"
    }

    static func protocolId(from payload: String) -> UUID? {
        guard payload.hasPrefix(queuePrefix) else { return nil }
        let value = String(payload.dropFirst(queuePrefix.count))
        return UUID(uuidString: value)
    }

    static func allocationId(from payload: String) -> UUID? {
        guard payload.hasPrefix(allocationPrefix) else { return nil }
        let value = String(payload.dropFirst(allocationPrefix.count))
        return UUID(uuidString: value)
    }
}

extension PlanDayModel {
    var isCompactEligible: Bool { isToday == false }
}
