import Foundation

enum WeeklyAllowanceCalculator {
    static func remainingThisWeek(
        mode: NonNegotiableMode,
        frequencyPerWeek: Int,
        completionsThisWeek: Int,
        plannedThisWeek: Int = 0
    ) -> Int {
        switch mode {
        case .daily:
            return max(0, 7 - completionsThisWeek - plannedThisWeek)
        case .session:
            return max(0, frequencyPerWeek - completionsThisWeek - plannedThisWeek)
        }
    }
}
