import Foundation

struct NonNegotiablePatch: Equatable {
    var newTitle: String?
    var newIconName: String?
    var newPreferredTime: PreferredExecutionSlot?
    var newEstimatedDurationMinutes: Int?
    var newMode: NonNegotiableMode?
    var newFrequencyPerWeek: Int?
    var newLockDays: Int?

    var touchedFields: Set<ProtocolField> {
        var fields: Set<ProtocolField> = []
        if newTitle != nil { fields.insert(.title) }
        if newIconName != nil { fields.insert(.icon) }
        if newPreferredTime != nil { fields.insert(.preferredTime) }
        if newEstimatedDurationMinutes != nil { fields.insert(.estimatedDuration) }
        if newMode != nil { fields.insert(.mode) }
        if newFrequencyPerWeek != nil { fields.insert(.frequency) }
        if newLockDays != nil { fields.insert(.lockDuration) }
        return fields
    }

    var isEmpty: Bool {
        touchedFields.isEmpty
    }
}
