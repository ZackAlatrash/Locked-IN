import Foundation

enum ProtocolField: String, Equatable, Hashable {
    case title
    case icon
    case preferredTime
    case estimatedDuration
    case mode
    case frequency
    case lockDuration

    var displayName: String {
        switch self {
        case .title: return "Title"
        case .icon: return "Icon"
        case .preferredTime: return "Preferred time"
        case .estimatedDuration: return "Estimated duration"
        case .mode: return "Mode"
        case .frequency: return "Frequency"
        case .lockDuration: return "Lock duration"
        }
    }
}

struct PolicyCopy: Equatable {
    let title: String
    let message: String
    let hint: String?
}

enum PolicyReason: Equatable {
    case locked(daysRemaining: Int, endsOn: Date)
    case recoveryActive(maxProtocols: Int, cleanDaysRemaining: Int)
    case capacityExceeded(active: Int, allowed: Int)
    case systemUnstable
    case protocolSuspended
    case cannotEditFieldDuringLock(field: ProtocolField, daysRemaining: Int, endsOn: Date)
    case cannotRetireDuringLock(daysRemaining: Int, endsOn: Date)
    case cannotRemoveUnlessCompletedOrRetired
    case cannotPlanIntoPast
    case protocolAlreadyScheduledThatDay
    case notEnoughFreeMinutes(required: Int, available: Int)
    case alreadyCompletedToday
    case extraAlreadyLoggedToday
    case weeklyCapReached(cap: Int)
    case protocolCompletedOrRetired
    case dailyPlacementLimited(maxDaysAhead: Int)
    case generic(message: String)
}

extension PolicyReason {
    func copy() -> PolicyCopy {
        switch self {
        case let .locked(daysRemaining, endsOn):
            return PolicyCopy(
                title: "Locked",
                message: "Locked for \(daysRemaining) day\(daysRemaining == 1 ? "" : "s") (ends \(Self.dateString(endsOn))).",
                hint: "Core rules cannot be changed during lock."
            )

        case let .recoveryActive(maxProtocols, cleanDaysRemaining):
            return PolicyCopy(
                title: "Recovery Active",
                message: "Recovery mode is active. Capacity is limited to \(maxProtocols) protocols.",
                hint: "Keep clean days to stabilize. \(cleanDaysRemaining) day\(cleanDaysRemaining == 1 ? "" : "s") remaining."
            )

        case let .capacityExceeded(active, allowed):
            return PolicyCopy(
                title: "Capacity Reached",
                message: "System capacity is \(active)/\(allowed). Additions are blocked.",
                hint: "Complete or retire protocols first."
            )

        case .systemUnstable:
            return PolicyCopy(
                title: "Recovery Active",
                message: "System is in recovery. This action is blocked right now.",
                hint: "Stabilize active protocols, then retry."
            )

        case .protocolSuspended:
            return PolicyCopy(
                title: "Paused During Recovery",
                message: "This protocol is paused during recovery.",
                hint: "It cannot be completed or planned until recovery ends."
            )

        case let .cannotEditFieldDuringLock(field, daysRemaining, endsOn):
            return PolicyCopy(
                title: "Field Locked",
                message: "\(field.displayName) cannot change during lock. \(daysRemaining) day\(daysRemaining == 1 ? "" : "s") remaining (ends \(Self.dateString(endsOn))).",
                hint: "You can still edit title, icon, preferred time, and estimated duration."
            )

        case let .cannotRetireDuringLock(daysRemaining, endsOn):
            return PolicyCopy(
                title: "Retirement Locked",
                message: "Protocol cannot be retired during lock. \(daysRemaining) day\(daysRemaining == 1 ? "" : "s") remaining (ends \(Self.dateString(endsOn))).",
                hint: "Retirement unlocks after lock end."
            )

        case .cannotRemoveUnlessCompletedOrRetired:
            return PolicyCopy(
                title: "Removal Blocked",
                message: "Only completed or retired protocols can be removed.",
                hint: "Retire the protocol after lock, then remove it."
            )

        case .cannotPlanIntoPast:
            return PolicyCopy(
                title: "Past Day Blocked",
                message: "You cannot schedule protocols into past days.",
                hint: "Move or place sessions on today or future days."
            )

        case .protocolAlreadyScheduledThatDay:
            return PolicyCopy(
                title: "Already Scheduled",
                message: "This protocol is already scheduled for that day.",
                hint: "One protocol allocation per day is allowed."
            )

        case let .notEnoughFreeMinutes(required, available):
            return PolicyCopy(
                title: "Not Enough Capacity",
                message: "This slot has \(available)m free, but \(required)m is required.",
                hint: "Choose a slot with more free minutes or reduce duration."
            )

        case .alreadyCompletedToday:
            return PolicyCopy(
                title: "Already Completed",
                message: "Counted completion already exists for today.",
                hint: "Only one counted completion per day is allowed."
            )

        case .extraAlreadyLoggedToday:
            return PolicyCopy(
                title: "Extra Already Logged",
                message: "EXTRA already logged today for this protocol.",
                hint: "At most one EXTRA per protocol per day is allowed."
            )

        case let .weeklyCapReached(cap):
            return PolicyCopy(
                title: "Weekly Cap Reached",
                message: "Weekly target of \(cap) counted completions is already met.",
                hint: "You can still log one EXTRA today."
            )

        case .protocolCompletedOrRetired:
            return PolicyCopy(
                title: "Protocol Closed",
                message: "This protocol is completed or retired.",
                hint: "Create a new protocol to continue tracking."
            )

        case let .dailyPlacementLimited(maxDaysAhead):
            return PolicyCopy(
                title: "Daily Placement Limited",
                message: "Daily protocols can only be planned for today or up to \(maxDaysAhead) day ahead.",
                hint: "Use regulator mode for broader weekly placement."
            )

        case .generic(let message):
            return PolicyCopy(
                title: "Action Blocked",
                message: message,
                hint: nil
            )
        }
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
