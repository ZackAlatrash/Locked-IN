import Foundation

struct NonNegotiable: Codable, Equatable {
    let id: UUID
    let goalId: UUID
    let definition: NonNegotiableDefinition
    var state: NonNegotiableState
    let lock: LockConfiguration
    let createdAt: Date
    var windows: [Window]
    var completions: [CompletionRecord]
    var violations: [Violation]
    var lastDailyComplianceCheckedDay: Date?
}
