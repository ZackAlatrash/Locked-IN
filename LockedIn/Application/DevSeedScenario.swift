import Foundation

enum DevSeedScenario: String, CaseIterable, Identifiable {
    case freshStartMinimal
    case stableWeek
    case overloadedWeek
    case checkInDueTonight
    case inRecovery
    case usedForAWhile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .freshStartMinimal:
            return "Fresh Start (Minimal)"
        case .stableWeek:
            return "Stable Week"
        case .overloadedWeek:
            return "Overloaded Week"
        case .checkInDueTonight:
            return "Check-In Due Tonight"
        case .inRecovery:
            return "In Recovery"
        case .usedForAWhile:
            return "Used For A While"
        }
    }

    var subtitle: String {
        switch self {
        case .freshStartMinimal:
            return "Single protocol, clean baseline"
        case .stableWeek:
            return "Balanced completions + allocations"
        case .overloadedWeek:
            return "Heavy load with unresolved pressure"
        case .checkInDueTonight:
            return "Evening state with pending check-in"
        case .inRecovery:
            return "Backdated misses that trigger the recovery popup"
        case .usedForAWhile:
            return "3 protocols, 20 days mixed full/partial/missed"
        }
    }
}
