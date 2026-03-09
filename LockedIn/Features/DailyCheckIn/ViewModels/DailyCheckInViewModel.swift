import Foundation
import Combine

@MainActor
final class DailyCheckInViewModel: ObservableObject {
    @Published private(set) var overview: DailyCheckInOverviewModel?
    @Published private(set) var protocolItems: [DailyCheckInProtocolItem] = []
    @Published private(set) var unresolvedCount = 0
    @Published private(set) var step: DailyCheckInFlowStep = .overview
    @Published private(set) var recommendation: DailyCheckInRecommendationModel?
    @Published private(set) var warningMessage: String?
    @Published private(set) var toastMessage: String?

    private let commitmentStore: CommitmentSystemStore
    private let planStore: PlanStore
    private let commitmentService: CommitmentActionService
    private let planService: PlanService
    private let regulatorEngine: PlanRegulatorEngine
    private let router: AppRouter
    private let referenceDateProvider: () -> Date
    private let calendar: Calendar

    init(
        commitmentStore: CommitmentSystemStore,
        planStore: PlanStore,
        commitmentService: CommitmentActionService,
        planService: PlanService,
        regulatorEngine: PlanRegulatorEngine = PlanRegulatorEngine(),
        router: AppRouter,
        referenceDateProvider: @escaping () -> Date = { Date() },
        calendar: Calendar = DateRules.isoCalendar
    ) {
        self.commitmentStore = commitmentStore
        self.planStore = planStore
        self.commitmentService = commitmentService
        self.planService = planService
        self.regulatorEngine = regulatorEngine
        self.router = router
        self.referenceDateProvider = referenceDateProvider
        self.calendar = calendar
    }

    var resolvingProtocol: DailyCheckInProtocolItem? {
        guard case let .resolve(protocolId) = step else { return nil }
        return protocolItems.first(where: { $0.protocolId == protocolId })
    }

    var recommendationProtocol: DailyCheckInProtocolItem? {
        guard case let .recommendation(protocolId) = step else { return nil }
        return protocolItems.first(where: { $0.protocolId == protocolId })
    }

    func refresh() {
        let now = referenceDateProvider()
        let weekId = DateRules.weekID(for: now, calendar: calendar)
        let today = DateRules.startOfDay(now, calendar: calendar)
        let snapshot = planStore.currentWeekSnapshot()

        let tracked = commitmentStore.system.nonNegotiables
            .filter { $0.state == .active || $0.state == .recovery || $0.state == .suspended }
            .sorted { $0.createdAt > $1.createdAt }

        protocolItems = tracked.map { protocolModel in
            let completionsThisWeek = protocolModel.completions.filter {
                $0.weekId == weekId && $0.kind == .counted
            }.count
            let plannedThisWeek = snapshot.currentWeekAllocations.filter {
                $0.protocolId == protocolModel.id && $0.status == .active
            }.count
            let completedToday = protocolModel.completions.contains {
                $0.kind == .counted && DateRules.startOfDay($0.date, calendar: calendar) == today
            }
            let extraLoggedToday = protocolModel.completions.contains {
                $0.kind == .extra && DateRules.startOfDay($0.date, calendar: calendar) == today
            }

            let remainingWeek = WeeklyAllowanceCalculator.remainingThisWeek(
                mode: protocolModel.definition.mode,
                frequencyPerWeek: protocolModel.definition.frequencyPerWeek,
                completionsThisWeek: completionsThisWeek,
                plannedThisWeek: plannedThisWeek
            )

            let needsAttention: Bool
            switch protocolModel.definition.mode {
            case .daily:
                needsAttention = completedToday == false
            case .session:
                needsAttention = completedToday == false && remainingWeek > 0
            }

            let isSuspended = protocolModel.state == .suspended
            let canLogExtraSession = protocolModel.definition.mode == .session
                && remainingWeek == 0
                && completedToday == false
                && extraLoggedToday == false
                && isSuspended == false
            let canMarkDone = isSuspended == false && (
                (completedToday == false && remainingWeek > 0) || canLogExtraSession
            )
            let canResolve = needsAttention && isSuspended == false

            let statusText: String
            let actionTitle: String
            let actionDisabledReason: String?
            if isSuspended {
                statusText = "Paused during recovery"
                actionTitle = "Unavailable"
                actionDisabledReason = "Paused protocols cannot be completed."
            } else if completedToday {
                statusText = "Completed today"
                actionTitle = "Done"
                actionDisabledReason = "Already completed today."
            } else if protocolModel.definition.mode == .daily {
                statusText = "Due today"
                actionTitle = "Mark Done"
                actionDisabledReason = nil
            } else if remainingWeek > 0 {
                statusText = "Needs attention"
                actionTitle = "Mark Done"
                actionDisabledReason = nil
            } else {
                if extraLoggedToday {
                    statusText = "Extra logged"
                    actionTitle = "Extra Logged"
                    actionDisabledReason = "EXTRA already logged today."
                } else {
                    statusText = "Weekly target met"
                    actionTitle = "Log Extra"
                    actionDisabledReason = nil
                }
            }

            return DailyCheckInProtocolItem(
                id: protocolModel.id,
                protocolId: protocolModel.id,
                title: protocolModel.definition.title,
                iconSystemName: protocolModel.definition.iconSystemName,
                modeLabel: protocolModel.definition.mode == .daily ? "DAILY" : "SESSION",
                statusText: statusText,
                remainingWeekText: protocolModel.definition.mode == .session
                    ? "\(remainingWeek) remaining this week"
                    : nil,
                completedToday: completedToday,
                isExtraToday: extraLoggedToday,
                needsAttention: needsAttention,
                isSuspended: isSuspended,
                canMarkDone: canMarkDone,
                canResolve: canResolve,
                actionTitle: actionTitle,
                actionDisabledReason: actionDisabledReason
            )
        }

        protocolItems.sort { lhs, rhs in
            if lhs.completedToday != rhs.completedToday {
                return lhs.completedToday == false
            }
            if lhs.needsAttention != rhs.needsAttention {
                return lhs.needsAttention
            }
            return lhs.title < rhs.title
        }

        unresolvedCount = protocolItems.filter(\.needsAttention).count
        let completedCount = protocolItems.filter(\.completedToday).count

        overview = DailyCheckInOverviewModel(
            dateLabel: dateLabel(for: now),
            modeLabel: systemModeLabel(),
            reliabilityScore: reliabilityScore(referenceDate: now),
            streakDays: commitmentStore.currentStreakDays(referenceDate: now),
            completedCount: completedCount,
            needsAttentionCount: unresolvedCount
        )

        if unresolvedCount == 0 && step != .closeDay {
            step = .closeDay
        } else {
            switch step {
            case .resolve(let protocolId), .recommendation(let protocolId):
                if protocolItems.contains(where: { $0.protocolId == protocolId }) == false {
                    step = unresolvedCount == 0 ? .closeDay : .overview
                    recommendation = nil
                }
            case .overview, .closeDay:
                break
            }
        }
    }

    func markDone(protocolId: UUID) {
        warningMessage = nil
        toastMessage = nil
        do {
            guard let protocolModel = commitmentStore.system.nonNegotiables.first(where: { $0.id == protocolId }) else {
                warningMessage = "Protocol is no longer available."
                return
            }
            let now = referenceDateProvider()
            let outcome = try commitmentService.recordCompletionDetailed(for: protocolId, at: now)
            let reconciliation = planService.reconcileAfterCompletion(
                protocolId: protocolId,
                mode: protocolModel.definition.mode,
                completionDate: now,
                completionKind: outcome.kind
            )
            commitmentService.runDailyIntegrityTick(referenceDate: referenceDateProvider())
            if outcome.kind == .extra {
                if protocolModel.definition.mode == .session {
                    toastMessage = "Weekly target already met. Logged as EXTRA."
                } else {
                    toastMessage = "Logged as EXTRA."
                }
            } else if case .released(let released) = reconciliation {
                let completionDay = DateRules.startOfDay(now, calendar: calendar)
                let tomorrow = DateRules.addingDays(1, to: completionDay, calendar: calendar)
                let releasedDay = DateRules.startOfDay(released.day, calendar: calendar)
                if releasedDay == tomorrow {
                    toastMessage = "\(protocolModel.definition.title) wasn't scheduled today. Tomorrow's \(released.slot.title) session was removed."
                } else {
                    toastMessage = "\(protocolModel.definition.title) wasn't scheduled today. \(weekdayLabel(for: releasedDay)) \(released.slot.title) was removed."
                }
            }
            refresh()
        } catch {
            if let copy = commitmentService.policyCopy(for: error) {
                warningMessage = copy.message
            } else {
                warningMessage = "Unable to mark protocol done right now."
            }
        }
    }

    func openResolve(protocolId: UUID) {
        warningMessage = nil
        recommendation = nil
        guard let item = protocolItems.first(where: { $0.protocolId == protocolId }) else { return }
        if item.isSuspended {
            warningMessage = "Paused protocol cannot be resolved right now."
            return
        }
        step = .resolve(protocolId: protocolId)
    }

    func resolveManually() {
        guard let protocolId = currentProtocolInContext else { return }
        router.openPlan(protocolId: protocolId)
    }

    func runSingleProtocolRegulator(protocolId: UUID) {
        warningMessage = nil
        recommendation = nil

        guard let nonNegotiable = commitmentStore.system.nonNegotiables.first(where: { $0.id == protocolId }) else {
            warningMessage = "Protocol is no longer available."
            return
        }
        if nonNegotiable.state == .suspended {
            warningMessage = "Paused protocol cannot be auto-placed."
            return
        }

        let snapshot = planStore.currentWeekSnapshot()
        let plannedThisWeek = snapshot.currentWeekAllocations.filter {
            $0.protocolId == nonNegotiable.id && $0.status == .active
        }.count
        let completionsThisWeek = nonNegotiable.completions.filter {
            $0.weekId == snapshot.weekId && $0.kind == .counted
        }.count

        let planItem = ProtocolPlanItem(
            id: nonNegotiable.id,
            title: nonNegotiable.definition.title,
            mode: nonNegotiable.definition.mode,
            state: nonNegotiable.state,
            frequencyPerWeek: nonNegotiable.definition.frequencyPerWeek,
            completionsThisWeek: completionsThisWeek,
            plannedThisWeek: plannedThisWeek,
            durationMinutes: nonNegotiable.definition.estimatedDurationMinutes,
            timePreference: nonNegotiable.definition.preferredExecutionSlot.regulationPreference
        )

        let regulationEvents = snapshot.calendarEvents.map {
            RegulationCalendarEvent(
                id: $0.id,
                startDateTime: $0.startDateTime,
                endDateTime: $0.endDateTime,
                isAllDay: $0.isAllDay
            )
        }

        let modeByProtocolId = Dictionary(
            uniqueKeysWithValues: commitmentStore.system.nonNegotiables.map { ($0.id, $0.definition.mode) }
        )
        let existingAllocations = snapshot.currentWeekAllocations
            .filter { $0.status == .active }
            .map { allocation in
            ExistingAllocationSnapshot(
                protocolId: allocation.protocolId,
                day: allocation.day,
                slot: allocation.slot.regulationSlot,
                durationMinutes: allocation.durationMinutes
                    ?? defaultDurationMinutes(for: modeByProtocolId[allocation.protocolId] ?? .session)
            )
        }

        let input = PlanRegulationInput(
            weekId: snapshot.weekId,
            weekStartDate: snapshot.weekStartDate,
            protocols: [planItem],
            calendarEvents: regulationEvents,
            existingAllocations: existingAllocations,
            rules: PlanRegulationRules()
        )

        let draft = regulatorEngine.regulate(input: input)
        guard let draftCandidate = draft.suggestedAllocations.first(where: { $0.protocolId == protocolId }) else {
            warningMessage = "No safe slot found. Place it manually in Plan."
            step = .resolve(protocolId: protocolId)
            return
        }

        if let validationWarning = planStore.validateDraft([draftCandidate]).first {
            warningMessage = validationWarning.reason
            step = .resolve(protocolId: protocolId)
            return
        }

        let suggestion = draft.suggestions.first {
            $0.protocolId == protocolId && $0.kind == .draftCandidate
        }

        recommendation = DailyCheckInRecommendationModel(
            protocolId: protocolId,
            protocolTitle: nonNegotiable.definition.title,
            dayLabel: weekdayLabel(for: draftCandidate.day),
            slotLabel: draftCandidate.slot.title,
            durationLabel: "\(draftCandidate.durationMinutes)m",
            confidenceLabel: "\(Int(((suggestion?.confidence ?? 0.72) * 100).rounded()))%",
            reason: suggestion?.reason ?? "Best valid placement based on current week capacity.",
            draft: draftCandidate
        )
        step = .recommendation(protocolId: protocolId)
    }

    @discardableResult
    func applyRecommendation() -> Bool {
        warningMessage = nil
        guard let recommendation else { return false }

        let result = planStore.applyDraft([recommendation.draft])
        switch result {
        case .success:
            self.recommendation = nil
            refresh()
            if unresolvedCount == 0 {
                step = .closeDay
            } else {
                step = .overview
            }
            return true
        case .failure(let error):
            warningMessage = error.localizedDescription
            return false
        }
    }

    func dismissRecommendation() {
        recommendation = nil
        step = .overview
    }

    func consumeToastMessage(_ message: String) {
        if toastMessage == message {
            toastMessage = nil
        }
    }

    func closeDay() {
        step = .closeDay
    }

    func dismissOutcome(completed: Bool) -> DailyCheckInDismissOutcome {
        DailyCheckInDismissOutcome(
            completed: completed,
            unresolvedCount: unresolvedCount
        )
    }

    func closingLine() -> String {
        let lines = [
            "Discipline compounds quietly.",
            "Consistency is a decision, not a mood.",
            "The day is closed. Keep the standard.",
            "Order held. Continue tomorrow.",
            "Small executions preserve long horizons."
        ]

        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: referenceDateProvider()) ?? 0
        let index = dayOfYear % lines.count
        return lines[index]
    }
}

private extension DailyCheckInViewModel {
    var currentProtocolInContext: UUID? {
        switch step {
        case .resolve(let protocolId), .recommendation(let protocolId):
            return protocolId
        case .overview, .closeDay:
            return nil
        }
    }

    func dateLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.calendar = calendar
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    func weekdayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.calendar = calendar
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    func systemModeLabel() -> String {
        if commitmentStore.system.nonNegotiables.contains(where: { $0.state == .recovery }) {
            return "RECOVERY"
        }
        return commitmentStore.isSystemStable ? "NORMAL" : "RECOVERY"
    }

    func reliabilityScore(referenceDate: Date) -> Int {
        let tracked = commitmentStore.system.nonNegotiables.filter {
            $0.state == .active || $0.state == .recovery || $0.state == .suspended
        }
        return ReliabilityCalculator.calculateDailyCheckInScore(for: tracked, referenceDate: referenceDate, calendar: calendar)
    }

    func defaultDurationMinutes(for mode: NonNegotiableMode) -> Int {
        switch mode {
        case .daily:
            return 15
        case .session:
            return 60
        }
    }
}

private extension PlanSlot {
    var regulationSlot: RegulationSlot {
        switch self {
        case .am: return .am
        case .pm: return .pm
        case .eve: return .eve
        }
    }
}

private extension PreferredExecutionSlot {
    var regulationPreference: ProtocolTimePreference {
        switch self {
        case .none: return .none
        case .am: return .am
        case .pm: return .pm
        case .eve: return .eve
        }
    }
}
