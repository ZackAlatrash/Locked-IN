import Foundation

enum ReliabilityCalculator {
    static func calculateCockpitScore(
        for nonNegotiables: [NonNegotiable],
        referenceDate: Date,
        calendar: Calendar = DateRules.isoCalendar
    ) -> Int {
        guard !nonNegotiables.isEmpty else { return 92 }

        let weekId = DateRules.weekID(for: referenceDate, calendar: calendar)
        var score = 92

        for nn in nonNegotiables {
            let currentWindow = nn.windows.first {
                referenceDate >= $0.startDate && referenceDate < $0.endDate
            }
            let thisWeekCompletions = nn.completions.reduce(into: 0) { partial, completion in
                if completion.weekId == weekId && completion.kind == .counted {
                    partial += 1
                }
            }
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

    static func calculateDailyCheckInScore(
        for nonNegotiables: [NonNegotiable],
        referenceDate: Date,
        calendar: Calendar = DateRules.isoCalendar
    ) -> Int {
        guard !nonNegotiables.isEmpty else { return 92 }

        let weekId = DateRules.weekID(for: referenceDate, calendar: calendar)
        let target = max(1, nonNegotiables.reduce(0) { $0 + $1.definition.frequencyPerWeek })
        let completions = nonNegotiables.reduce(0) { partial, item in
            partial + item.completions.filter {
                $0.weekId == weekId && $0.kind == .counted
            }.count
        }
        let completionRate = min(1.0, Double(completions) / Double(target))
        var score = Int((completionRate * 40.0) + 58.0)

        let suspendedCount = nonNegotiables.filter { $0.state == .suspended }.count
        let recoveryCount = nonNegotiables.filter { $0.state == .recovery }.count
        score -= suspendedCount * 8
        score -= recoveryCount * 12

        return max(0, min(100, score))
    }
}
