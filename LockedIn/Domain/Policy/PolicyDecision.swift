import Foundation

struct PolicyDecision: Equatable {
    let allowed: Bool
    let reason: PolicyReason?

    static func allow() -> PolicyDecision {
        PolicyDecision(allowed: true, reason: nil)
    }

    static func deny(_ reason: PolicyReason) -> PolicyDecision {
        PolicyDecision(allowed: false, reason: reason)
    }
}
