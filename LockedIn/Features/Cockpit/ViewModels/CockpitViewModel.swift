import Foundation
import Combine

@MainActor
final class CockpitViewModel: ObservableObject {
    @Published private(set) var uiState: CockpitUIState = .placeholder

    func refresh(
        system: CommitmentSystem,
        isStable: Bool,
        reliabilityOverride: Int? = nil,
        currentStreakDays: Int = 0,
        todayCompleted: Bool = false
    ) {
        let now = Date()

        let computedScore = reliabilityScore(for: system, referenceDate: now)
        let reliabilityScore = min(max(reliabilityOverride ?? computedScore, 0), 100)
        let accent = accentRGB(for: reliabilityScore)
        let inRecovery = system.nonNegotiables.contains(where: { $0.state == .recovery })
        let clampedRecoveryDay = min(max(system.recoveryCleanDayStreak, 0), 7)
        let activeCount = system.activeNonNegotiables.count
        let allowedCapacity = system.allowedCapacity

        uiState = CockpitUIState(
            modeText: systemMode(system: system, isStable: isStable),
            recoveryProgressText: inRecovery ? "Recovery Day \(clampedRecoveryDay) / 7" : nil,
            recoveryProgressFill: inRecovery ? Double(clampedRecoveryDay) / 7.0 : 0,
            reliabilityScore: reliabilityScore,
            currentStreakDays: currentStreakDays,
            todayCompleted: todayCompleted,
            capacityStatusText: isStable ? "STABLE" : "UNSTABLE",
            activeCount: activeCount,
            allowedCapacity: allowedCapacity,
            capacityCountText: "\(activeCount) / \(allowedCapacity)",
            capacityDetailText: "Active / Allowed",
            capacityDots: capacityDots(system: system, isStable: isStable),
            accentRGB: accent,
            nonNegotiables: mapCards(system: system, referenceDate: now),
            todayTasks: todayTasks(system: system, referenceDate: now),
            todayWindowTitle: "TODAY'S WINDOW",
            todayWindowSubtitle: todayWindowSubtitle(system: system, referenceDate: now)
        )
    }
}

private extension CockpitViewModel {
    func systemMode(system: CommitmentSystem, isStable: Bool) -> String {
        if system.nonNegotiables.contains(where: { $0.state == .recovery }) {
            return "RECOVERY"
        }
        return isStable ? "NORMAL" : "UNSTABLE"
    }

    func capacityDots(system: CommitmentSystem, isStable: Bool) -> [CockpitCapacityDot] {
        let filled: Int
        if system.nonNegotiables.contains(where: { $0.state == .recovery }) {
            filled = 1
        } else if isStable {
            filled = 3
        } else {
            filled = 1
        }
        return (0..<3).map { CockpitCapacityDot(isFilled: $0 < filled) }
    }

    func mapCards(system: CommitmentSystem, referenceDate: Date) -> [CockpitNonNegotiableCardModel] {
        let filtered = system.nonNegotiables.filter {
            $0.state == .active || $0.state == .recovery || $0.state == .suspended
        }

        return filtered
            .sorted { $0.createdAt > $1.createdAt }
            .map { nn in
                let progress = lockProgress(for: nn, referenceDate: referenceDate)
                let daysLeft = daysLeftText(for: nn, referenceDate: referenceDate)
                let badge = badge(for: nn, referenceDate: referenceDate)
                let weekId = DateRules.weekID(for: referenceDate)
                let completionsThisWeek = nn.completions.filter { $0.weekId == weekId }.count
                let weeklyTarget = nn.definition.frequencyPerWeek
                let weeklyProgress = "\(min(completionsThisWeek, weeklyTarget))/\(weeklyTarget) this week"

                let subtitle: String = {
                    switch nn.definition.mode {
                    case .daily:
                        return "Daily mode"
                    case .session:
                        return "\(nn.definition.frequencyPerWeek)x/week"
                    }
                }()

                let stateHint: String? = {
                    switch nn.state {
                    case .recovery:
                        let day = min(max(system.recoveryCleanDayStreak, 0), 7)
                        return "Recovery day \(day) / 7"
                    case .suspended:
                        return "Suspended (system stabilizing)"
                    default:
                        return nil
                    }
                }()

                let lockProgressText = "\(Int((progress * 100).rounded()))%"

                return CockpitNonNegotiableCardModel(
                    id: nn.id,
                    title: nn.definition.title,
                    subtitle: subtitle,
                    weeklyProgressText: weeklyProgress,
                    stateHint: stateHint,
                    badge: badge,
                    daysLeftText: daysLeft,
                    lockProgressText: lockProgressText,
                    progress: progress,
                    isDimmed: nn.state == .suspended
                )
            }
    }

    func lockProgress(for nn: NonNegotiable, referenceDate: Date) -> Double {
        let total = max(nn.lock.totalLockDays, 1)
        let start = DateRules.startOfDay(nn.lock.startDate)
        let today = DateRules.startOfDay(referenceDate)
        let elapsed = max(0, DateRules.isoCalendar.dateComponents([.day], from: start, to: today).day ?? 0)
        return min(max(Double(elapsed) / Double(total), 0), 1)
    }

    func daysLeftText(for nn: NonNegotiable, referenceDate: Date) -> String {
        let endDate = DateRules.addingDays(nn.lock.totalLockDays, to: DateRules.startOfDay(nn.lock.startDate))
        let days = max(0, DateRules.isoCalendar.dateComponents([.day], from: DateRules.startOfDay(referenceDate), to: endDate).day ?? 0)
        return "\(days) days left"
    }

    func badge(for nn: NonNegotiable, referenceDate: Date) -> CockpitNonNegotiableCardModel.Badge {
        switch nn.state {
        case .suspended:
            return .suspended
        case .recovery:
            return .recovery
        default:
            break
        }

        let completedToday = nn.completions.contains {
            DateRules.isoCalendar.isDate($0.date, inSameDayAs: referenceDate)
        }
        let weekId = DateRules.weekID(for: referenceDate)
        let completionsThisWeek = nn.completions.filter { $0.weekId == weekId }.count
        let weeklyTargetMet = completionsThisWeek >= nn.definition.frequencyPerWeek

        if completedToday {
            return .done
        }
        if weeklyTargetMet {
            return .verified
        }

        return .due
    }

    func reliabilityScore(for system: CommitmentSystem, referenceDate: Date) -> Int {
        guard !system.nonNegotiables.isEmpty else { return 92 }

        let weekId = DateRules.weekID(for: referenceDate)
        var score = 92

        for nn in system.nonNegotiables {
            let currentWindow = currentWindow(for: nn, referenceDate: referenceDate)
            let thisWeekCompletions = nn.completions.filter { $0.weekId == weekId }.count
            let currentWindowViolations = nn.violations.filter { violation in
                violation.windowIndex == currentWindow?.index
            }.count

            score -= currentWindowViolations * 16

            if nn.state == .suspended {
                score -= 14
            }
            if nn.state == .recovery {
                score -= 22
            }

            let rewardCap = nn.definition.frequencyPerWeek
            score += min(thisWeekCompletions, rewardCap) * 2
        }

        return min(max(score, 0), 100)
    }

    func currentWindow(for nn: NonNegotiable, referenceDate: Date) -> Window? {
        nn.windows.first {
            referenceDate >= $0.startDate && referenceDate < $0.endDate
        }
    }

    func todayWindowSubtitle(system: CommitmentSystem, referenceDate: Date) -> String {
        let dueCount = system.nonNegotiables.filter {
            ($0.state == .active || $0.state == .recovery) &&
            badge(for: $0, referenceDate: referenceDate) == .due
        }.count
        let doneToday = system.nonNegotiables
            .flatMap(\.completions)
            .filter { DateRules.isoCalendar.isDate($0.date, inSameDayAs: referenceDate) }
            .count

        if dueCount == 0 {
            if doneToday > 0 {
                return "\(doneToday) completion\(doneToday == 1 ? "" : "s") logged today"
            }
            return "No urgent protocols right now"
        }

        return "\(dueCount) due • \(doneToday) done today"
    }

    func todayTasks(system: CommitmentSystem, referenceDate: Date) -> [TodayTask] {
        let weekId = DateRules.weekID(for: referenceDate)

        return system.nonNegotiables
            .filter { $0.state == .active || $0.state == .recovery || $0.state == .suspended }
            .sorted { $0.createdAt > $1.createdAt }
            .map { nn in
                let completedToday = nn.completions.contains {
                    DateRules.isoCalendar.isDate($0.date, inSameDayAs: referenceDate)
                }
                let thisWeekCount = nn.completions.filter { $0.weekId == weekId }.count
                let isSuspended = nn.state == .suspended
                let recoveryHint = nn.state == .recovery ? "Recovery rules active" : nil

                switch nn.definition.mode {
                case .daily:
                    let subtitle: String
                    let ctaEnabled: Bool
                    let ctaTitle: String
                    let statusText: String

                    if isSuspended {
                        subtitle = "Suspended (system stabilizing)"
                        statusText = "Suspended (system stabilizing)"
                        ctaEnabled = false
                        ctaTitle = "Unavailable"
                    } else if completedToday {
                        subtitle = "Completed today"
                        statusText = "Completed today"
                        ctaEnabled = false
                        ctaTitle = "Completed"
                    } else {
                        subtitle = "Due today"
                        statusText = "Due today"
                        ctaEnabled = true
                        ctaTitle = "Mark Done"
                    }

                    return TodayTask(
                        id: nn.id,
                        nnId: nn.id,
                        title: nn.definition.title,
                        subtitle: subtitle,
                        statusText: statusText,
                        recoveryHint: recoveryHint,
                        modeLabel: .daily,
                        isCompleteToday: completedToday,
                        ctaTitle: ctaTitle,
                        isCtaEnabled: ctaEnabled
                    )
                case .session:
                    let remaining = max(nn.definition.frequencyPerWeek - thisWeekCount, 0)
                    let subtitle: String
                    let statusText: String
                    let ctaEnabled: Bool
                    let ctaTitle: String

                    if isSuspended {
                        subtitle = "Suspended (system stabilizing)"
                        statusText = "Suspended (system stabilizing)"
                        ctaEnabled = false
                        ctaTitle = "Unavailable"
                    } else if completedToday {
                        subtitle = "Completed today"
                        statusText = "Completed today"
                        ctaEnabled = false
                        ctaTitle = "Completed"
                    } else if remaining > 0 {
                        subtitle = "\(remaining) session\(remaining == 1 ? "" : "s") remaining this week"
                        statusText = "\(remaining) remaining this week"
                        ctaEnabled = true
                        ctaTitle = "Mark Done"
                    } else {
                        subtitle = "Weekly target met"
                        statusText = "Weekly target met"
                        ctaEnabled = false
                        ctaTitle = "Complete"
                    }

                    return TodayTask(
                        id: nn.id,
                        nnId: nn.id,
                        title: nn.definition.title,
                        subtitle: subtitle,
                        statusText: statusText,
                        recoveryHint: recoveryHint,
                        modeLabel: .session,
                        isCompleteToday: completedToday,
                        ctaTitle: ctaTitle,
                        isCtaEnabled: ctaEnabled
                    )
                }
            }
    }

    func accentRGB(for score: Int) -> RGBColor {
        let clamped = max(0, min(score, 100))

        let blue = (r: 0.07, g: 0.50, b: 0.93)
        let orange = (r: 0.95, g: 0.52, b: 0.14)
        let red = (r: 0.92, g: 0.16, b: 0.20)

        if clamped >= 50 {
            let t = Double(clamped - 50) / 50.0
            return interpolate(from: orange, to: blue, t: t)
        }

        let t = Double(clamped) / 50.0
        return interpolate(from: red, to: orange, t: t)
    }

    func interpolate(
        from: (r: Double, g: Double, b: Double),
        to: (r: Double, g: Double, b: Double),
        t: Double
    ) -> RGBColor {
        RGBColor(
            r: from.r + (to.r - from.r) * t,
            g: from.g + (to.g - from.g) * t,
            b: from.b + (to.b - from.b) * t
        )
    }
}
