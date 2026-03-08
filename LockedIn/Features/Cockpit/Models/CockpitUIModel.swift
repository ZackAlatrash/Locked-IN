import Foundation

struct RGBColor {
    let r: Double
    let g: Double
    let b: Double
}

struct CockpitUIState {
    var modeText: String
    var recoveryProgressText: String?
    var recoveryProgressFill: Double
    var reliabilityScore: Int
    var currentStreakDays: Int
    var todayCompleted: Bool
    var capacityStatusText: String
    var activeCount: Int
    var allowedCapacity: Int
    var capacityCountText: String
    var capacityDetailText: String
    var capacityDots: [CockpitCapacityDot]
    var accentRGB: RGBColor
    var nonNegotiables: [CockpitNonNegotiableCardModel]
    var todayTasks: [TodayTask]
    var todayWindowTitle: String
    var todayWindowSubtitle: String

    static var placeholder: CockpitUIState {
        CockpitUIState(
            modeText: "NORMAL",
            recoveryProgressText: nil,
            recoveryProgressFill: 0,
            reliabilityScore: 92,
            currentStreakDays: 0,
            todayCompleted: false,
            capacityStatusText: "STABLE",
            activeCount: 0,
            allowedCapacity: 3,
            capacityCountText: "0 / 3",
            capacityDetailText: "Active / Allowed",
            capacityDots: [
                CockpitCapacityDot(isFilled: true),
                CockpitCapacityDot(isFilled: true),
                CockpitCapacityDot(isFilled: true)
            ],
            accentRGB: RGBColor(r: 0.07, g: 0.50, b: 0.93),
            nonNegotiables: [],
            todayTasks: [],
            todayWindowTitle: "TODAY'S WINDOW",
            todayWindowSubtitle: "No active windows yet"
        )
    }
}

struct CockpitCapacityDot: Identifiable {
    let id = UUID()
    let isFilled: Bool
}

struct CockpitNonNegotiableCardModel: Identifiable {
    enum Badge: Equatable {
        case due
        case done
        case verified
        case pending
        case suspended
        case recovery

        var title: String {
            switch self {
            case .due: return "DUE"
            case .done: return "DONE"
            case .verified: return "VERIFIED"
            case .pending: return ""
            case .suspended: return "SUSPENDED"
            case .recovery: return "RECOVERY"
            }
        }
    }

    let id: UUID
    let title: String
    let iconSystemName: String
    let subtitle: String
    let weeklyProgressText: String
    let stateHint: String?
    let badge: Badge
    let daysLeftText: String
    let lockProgressText: String
    let progress: Double
    let isDimmed: Bool
}

enum CockpitAction: Equatable {
    case complete(nnId: UUID)
    case openDetails(nnId: UUID)
    case edit(nnId: UUID)
    case openCreate
    case openLogs
    case openPlan
    case openWeeklyActivity
    case openStreak
    case openCapacity
    case openProfile
    case retire(nnId: UUID)
}

struct TodayTask: Identifiable, Equatable {
    enum ModeLabel: String, Equatable {
        case daily = "DAILY"
        case session = "SESSION"
    }

    enum CompletionVisual: Equatable {
        case none
        case counted
        case extra
    }

    let id: UUID
    let nnId: UUID
    let title: String
    let iconSystemName: String
    let subtitle: String
    let statusText: String
    let recoveryHint: String?
    let modeLabel: ModeLabel
    let isCompleteToday: Bool
    let isExtraToday: Bool
    let isRequiredToday: Bool
    let completionVisual: CompletionVisual
    let ctaTitle: String
    let isCtaEnabled: Bool
}
