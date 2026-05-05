import Foundation
import Combine

@MainActor
final class DevOptionsController: ObservableObject {
    @Published private(set) var statusMessage: String?

    private let commitmentStore: CommitmentSystemStore
    private let planStore: PlanStore
    private let appClock: AppClock
    private let devRuntime: DevRuntimeState
    private let userDefaults: UserDefaults
    private let calendar: Calendar

    init(
        commitmentStore: CommitmentSystemStore,
        planStore: PlanStore,
        appClock: AppClock,
        devRuntime: DevRuntimeState,
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = DateRules.isoCalendar
    ) {
        self.commitmentStore = commitmentStore
        self.planStore = planStore
        self.appClock = appClock
        self.devRuntime = devRuntime
        self.userDefaults = userDefaults
        self.calendar = calendar
    }

    func fullWipeAndReset() {
        commitmentStore.clearAllNonNegotiables()
        planStore.clearAllAllocations()

        appDefaultsKeysForFullWipe.forEach { key in
            userDefaults.removeObject(forKey: key)
        }

        appClock.resetToLive()
        devRuntime.clearSessionOverrides()

        statusMessage = "Data cleared. Relaunch app for cleanest fresh-start verification."
    }

    func clearPlanOnly() {
        planStore.clearAllAllocations()
        statusMessage = "Plan allocations cleared."
    }

    func clearProtocolsOnly() {
        commitmentStore.clearAllNonNegotiables()
        planStore.clearAllAllocations()
        statusMessage = "Protocols cleared."
    }

    func resetOneTimeHintsAndEntrances() {
        oneTimePresentationKeys.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
        statusMessage = "One-time hints and entrance animations reset for this install."
    }

    func seed(_ scenario: DevSeedScenario) {
        do {
            commitmentStore.clearAllNonNegotiables()
            planStore.clearAllAllocations()
            devRuntime.clearSessionOverrides()
            resetDailyCheckInPromptState()

            let referenceNow = scenarioReferenceDate(for: scenario, anchor: appClock.now)
            appClock.setSimulatedNow(referenceNow)
            let weekStart = DateRules.startOfDay(
                DateRules.weekInterval(containing: referenceNow, calendar: calendar).start,
                calendar: calendar
            )

            switch scenario {
            case .freshStartMinimal:
                try seedFreshStartMinimal()
            case .stableWeek:
                try seedStableWeek(weekStart: weekStart)
            case .overloadedWeek:
                try seedOverloadedWeek(weekStart: weekStart)
            case .checkInDueTonight:
                try seedCheckInDueTonight(weekStart: weekStart, referenceNow: referenceNow)
            case .inRecovery:
                try seedInRecovery(referenceNow: referenceNow)
            case .usedForAWhile:
                try seedUsedForAWhile(referenceNow: referenceNow)
            }

            commitmentStore.runDailyIntegrityTick(referenceDate: referenceNow)
            planStore.refresh(system: commitmentStore.system, calendarEvents: [], referenceDate: referenceNow)
            statusMessage = "Applied \(scenario.title) scenario."
        } catch {
            statusMessage = "Failed to seed scenario: \(error.localizedDescription)"
        }
    }

    private func seedFreshStartMinimal() throws {
        _ = try createProtocol(
            title: "Hydration",
            mode: .daily,
            frequencyPerWeek: 7,
            preferredSlot: .am,
            durationMinutes: 15,
            iconSystemName: "drop.fill"
        )
    }

    private func seedStableWeek(weekStart: Date) throws {
        let deepWorkId = try createProtocol(
            title: "Deep Work",
            mode: .session,
            frequencyPerWeek: 3,
            preferredSlot: .am,
            durationMinutes: 90,
            iconSystemName: "bolt.fill"
        )
        let neuralDrillId = try createProtocol(
            title: "Neural Drill",
            mode: .session,
            frequencyPerWeek: 2,
            preferredSlot: .eve,
            durationMinutes: 60,
            iconSystemName: "brain.head.profile"
        )
        let hydrationId = try createProtocol(
            title: "Hydration",
            mode: .daily,
            frequencyPerWeek: 7,
            preferredSlot: .am,
            durationMinutes: 15,
            iconSystemName: "drop.fill"
        )

        try logCompletion(protocolId: deepWorkId, on: day(0, weekStart: weekStart), hour: 8)
        try logCompletion(protocolId: deepWorkId, on: day(1, weekStart: weekStart), hour: 9)
        try logCompletion(protocolId: neuralDrillId, on: day(1, weekStart: weekStart), hour: 19)
        try logCompletion(protocolId: hydrationId, on: day(0, weekStart: weekStart), hour: 7)
        try logCompletion(protocolId: hydrationId, on: day(1, weekStart: weekStart), hour: 7)
        try logCompletion(protocolId: hydrationId, on: day(2, weekStart: weekStart), hour: 7)

        let referenceNow = appClock.now
        planStore.refresh(system: commitmentStore.system, calendarEvents: [], referenceDate: referenceNow)

        _ = planStore.applyDraft([
            PlanAllocationDraft(protocolId: deepWorkId, weekId: DateRules.weekID(for: day(3, weekStart: weekStart), calendar: calendar), day: day(3, weekStart: weekStart), slot: .am, durationMinutes: 90),
            PlanAllocationDraft(protocolId: neuralDrillId, weekId: DateRules.weekID(for: day(4, weekStart: weekStart), calendar: calendar), day: day(4, weekStart: weekStart), slot: .eve, durationMinutes: 60),
            PlanAllocationDraft(protocolId: hydrationId, weekId: DateRules.weekID(for: day(3, weekStart: weekStart), calendar: calendar), day: day(3, weekStart: weekStart), slot: .am, durationMinutes: 15),
        ])
    }

    private func seedOverloadedWeek(weekStart: Date) throws {
        let deepWorkId = try createProtocol(
            title: "Deep Work",
            mode: .session,
            frequencyPerWeek: 4,
            preferredSlot: .pm,
            durationMinutes: 120,
            iconSystemName: "bolt.fill"
        )
        let neuralDrillId = try createProtocol(
            title: "Neural Drill",
            mode: .session,
            frequencyPerWeek: 3,
            preferredSlot: .eve,
            durationMinutes: 90,
            iconSystemName: "brain.head.profile"
        )
        let isometricsId = try createProtocol(
            title: "Isometrics",
            mode: .session,
            frequencyPerWeek: 3,
            preferredSlot: .pm,
            durationMinutes: 60,
            iconSystemName: "figure.strengthtraining.traditional"
        )
        let hydrationId = try createProtocol(
            title: "Hydration",
            mode: .daily,
            frequencyPerWeek: 7,
            preferredSlot: .am,
            durationMinutes: 15,
            iconSystemName: "drop.fill"
        )

        try logCompletion(protocolId: deepWorkId, on: day(1, weekStart: weekStart), hour: 13)
        try logCompletion(protocolId: hydrationId, on: day(4, weekStart: weekStart), hour: 8)

        let referenceNow = appClock.now
        planStore.refresh(system: commitmentStore.system, calendarEvents: [], referenceDate: referenceNow)

        _ = planStore.applyDraft([
            PlanAllocationDraft(protocolId: deepWorkId, weekId: DateRules.weekID(for: day(4, weekStart: weekStart), calendar: calendar), day: day(4, weekStart: weekStart), slot: .pm, durationMinutes: 120),
            PlanAllocationDraft(protocolId: neuralDrillId, weekId: DateRules.weekID(for: day(5, weekStart: weekStart), calendar: calendar), day: day(5, weekStart: weekStart), slot: .eve, durationMinutes: 90),
            PlanAllocationDraft(protocolId: isometricsId, weekId: DateRules.weekID(for: day(5, weekStart: weekStart), calendar: calendar), day: day(5, weekStart: weekStart), slot: .pm, durationMinutes: 60),
            PlanAllocationDraft(protocolId: hydrationId, weekId: DateRules.weekID(for: day(5, weekStart: weekStart), calendar: calendar), day: day(5, weekStart: weekStart), slot: .am, durationMinutes: 15),
        ])
    }

    private func seedCheckInDueTonight(weekStart: Date, referenceNow: Date) throws {
        let deepWorkId = try createProtocol(
            title: "Deep Work",
            mode: .session,
            frequencyPerWeek: 2,
            preferredSlot: .pm,
            durationMinutes: 90,
            iconSystemName: "bolt.fill"
        )
        let hydrationId = try createProtocol(
            title: "Hydration",
            mode: .daily,
            frequencyPerWeek: 7,
            preferredSlot: .am,
            durationMinutes: 15,
            iconSystemName: "drop.fill"
        )

        try logCompletion(protocolId: deepWorkId, on: day(1, weekStart: weekStart), hour: 14)
        try logCompletion(protocolId: hydrationId, on: day(2, weekStart: weekStart), hour: 8)

        planStore.refresh(system: commitmentStore.system, calendarEvents: [], referenceDate: referenceNow)
        _ = planStore.applyDraft([
            PlanAllocationDraft(protocolId: deepWorkId, weekId: DateRules.weekID(for: day(4, weekStart: weekStart), calendar: calendar), day: day(4, weekStart: weekStart), slot: .pm, durationMinutes: 90),
            PlanAllocationDraft(protocolId: hydrationId, weekId: DateRules.weekID(for: day(4, weekStart: weekStart), calendar: calendar), day: day(4, weekStart: weekStart), slot: .am, durationMinutes: 15),
        ])

        let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceNow) ?? referenceNow
        userDefaults.set(DailyCheckInPolicy.dayIdentifier(for: yesterday, calendar: calendar), forKey: DailyCheckInPolicy.Keys.lastCompletedDay)
        userDefaults.removeObject(forKey: DailyCheckInPolicy.Keys.lastPromptedDay)
        userDefaults.removeObject(forKey: DailyCheckInPolicy.Keys.repromptedDay)
        userDefaults.set(0, forKey: DailyCheckInPolicy.Keys.deferredUntilTimestamp)
    }

    private func seedInRecovery(referenceNow: Date) throws {
        let referenceWeekStart = DateRules.startOfDay(
            DateRules.weekInterval(containing: referenceNow, calendar: calendar).start,
            calendar: calendar
        )
        guard let firstWeekStart = calendar.date(byAdding: .day, value: -14, to: referenceWeekStart),
              let secondWeekStart = calendar.date(byAdding: .day, value: -7, to: referenceWeekStart) else {
            throw NSError(domain: "DevOptionsController", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not build recovery seed dates."])
        }

        let creationDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: firstWeekStart) ?? firstWeekStart
        let recoveryProtocolId = try createProtocol(
            title: "Recovery Trigger",
            mode: .session,
            frequencyPerWeek: 5,
            preferredSlot: .am,
            durationMinutes: 90,
            iconSystemName: "exclamationmark.triangle.fill",
            referenceDate: creationDate
        )
        let pauseCandidateId = try createProtocol(
            title: "Pause Candidate",
            mode: .session,
            frequencyPerWeek: 1,
            preferredSlot: .pm,
            durationMinutes: 45,
            iconSystemName: "pause.circle.fill",
            referenceDate: calendar.date(byAdding: .hour, value: 1, to: creationDate) ?? creationDate
        )

        try logCompletion(protocolId: pauseCandidateId, on: day(1, weekStart: firstWeekStart), hour: 14)
        try logCompletion(protocolId: pauseCandidateId, on: day(1, weekStart: secondWeekStart), hour: 14)

        let firstClosedWeekTick = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: secondWeekStart) ?? secondWeekStart
        let secondClosedWeekTick = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: referenceWeekStart) ?? referenceWeekStart
        commitmentStore.runDailyIntegrityTick(referenceDate: firstClosedWeekTick)
        commitmentStore.runDailyIntegrityTick(referenceDate: secondClosedWeekTick)

        guard commitmentStore.system.recoveryEntryPendingResolution,
              commitmentStore.system.nonNegotiables.contains(where: { $0.id == recoveryProtocolId && $0.state == .recovery }) else {
            throw NSError(domain: "DevOptionsController", code: 501, userInfo: [NSLocalizedDescriptionKey: "Recovery seed did not enter recovery."])
        }
        let candidateIds = commitmentStore.recoveryEntryContext()?.candidateProtocolIds ?? []
        let activeProtocolIds = Set(commitmentStore.system.nonNegotiables.filter { $0.state == .active }.map(\.id))
        guard candidateIds.contains(pauseCandidateId),
              candidateIds.allSatisfy({ activeProtocolIds.contains($0) }) else {
            throw NSError(domain: "DevOptionsController", code: 502, userInfo: [NSLocalizedDescriptionKey: "Recovery seed did not expose an active pause candidate."])
        }

        planStore.refresh(system: commitmentStore.system, calendarEvents: [], referenceDate: referenceNow)
        let allocationDay = day(3, weekStart: referenceWeekStart)
        let draftResult = planStore.applyDraft([
            PlanAllocationDraft(
                protocolId: pauseCandidateId,
                weekId: DateRules.weekID(for: allocationDay, calendar: calendar),
                day: allocationDay,
                slot: .pm,
                durationMinutes: 45
            ),
        ])
        if case .failure(let error) = draftResult {
            throw NSError(domain: "DevOptionsController", code: 503, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
        }
    }

    private func seedUsedForAWhile(referenceNow: Date) throws {
        let deepWorkId = try createProtocol(
            title: "Deep Work",
            mode: .session,
            frequencyPerWeek: 4,
            preferredSlot: .am,
            durationMinutes: 90,
            iconSystemName: "bolt.fill"
        )
        let neuralDrillId = try createProtocol(
            title: "Neural Drill",
            mode: .session,
            frequencyPerWeek: 3,
            preferredSlot: .eve,
            durationMinutes: 60,
            iconSystemName: "brain.head.profile"
        )
        let hydrationId = try createProtocol(
            title: "Hydration",
            mode: .daily,
            frequencyPerWeek: 7,
            preferredSlot: .am,
            durationMinutes: 15,
            iconSystemName: "drop.fill"
        )

        let referenceDay = DateRules.startOfDay(referenceNow, calendar: calendar)
        let startDay = calendar.date(byAdding: .day, value: -19, to: referenceDay) ?? referenceDay

        for offset in 0..<20 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDay) else { continue }

            // Pattern: full, partial, partial, missed, minimal.
            switch offset % 5 {
            case 0:
                try? logCompletion(protocolId: hydrationId, on: day, hour: 7)
                try? logCompletion(protocolId: deepWorkId, on: day, hour: 8)
                try? logCompletion(protocolId: neuralDrillId, on: day, hour: 19)
            case 1:
                try? logCompletion(protocolId: hydrationId, on: day, hour: 7)
                try? logCompletion(protocolId: deepWorkId, on: day, hour: 8)
            case 2:
                try? logCompletion(protocolId: hydrationId, on: day, hour: 7)
                try? logCompletion(protocolId: neuralDrillId, on: day, hour: 19)
            case 3:
                break
            default:
                try? logCompletion(protocolId: hydrationId, on: day, hour: 7)
            }

            let tickTime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: day) ?? day
            commitmentStore.runDailyIntegrityTick(referenceDate: tickTime)
        }

        planStore.refresh(system: commitmentStore.system, calendarEvents: [], referenceDate: referenceNow)
        let weekStart = DateRules.startOfDay(
            DateRules.weekInterval(containing: referenceNow, calendar: calendar).start,
            calendar: calendar
        )
        _ = planStore.applyDraft([
            PlanAllocationDraft(protocolId: deepWorkId, weekId: DateRules.weekID(for: day(1, weekStart: weekStart), calendar: calendar), day: day(1, weekStart: weekStart), slot: .am, durationMinutes: 90),
            PlanAllocationDraft(protocolId: neuralDrillId, weekId: DateRules.weekID(for: day(2, weekStart: weekStart), calendar: calendar), day: day(2, weekStart: weekStart), slot: .eve, durationMinutes: 60),
            PlanAllocationDraft(protocolId: hydrationId, weekId: DateRules.weekID(for: day(3, weekStart: weekStart), calendar: calendar), day: day(3, weekStart: weekStart), slot: .am, durationMinutes: 15),
        ])
        statusMessage = "Applied Used For A While scenario (3 protocols, 20 days with full/partial/missed outcomes)."
    }

    private func createProtocol(
        title: String,
        mode: NonNegotiableMode,
        frequencyPerWeek: Int,
        preferredSlot: PreferredExecutionSlot,
        durationMinutes: Int,
        iconSystemName: String,
        referenceDate: Date? = nil
    ) throws -> UUID {
        let definition = NonNegotiableDefinition(
            title: title,
            frequencyPerWeek: frequencyPerWeek,
            mode: mode,
            goalId: UUID(),
            preferredExecutionSlot: preferredSlot,
            estimatedDurationMinutes: durationMinutes,
            iconSystemName: iconSystemName
        )

        try commitmentStore.createNonNegotiable(
            definition: definition,
            totalLockDays: 28,
            referenceDate: referenceDate ?? appClock.now
        )

        guard let created = commitmentStore.system.nonNegotiables
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first(where: { $0.definition.title == title }) else {
            throw NSError(domain: "DevOptionsController", code: 404, userInfo: [NSLocalizedDescriptionKey: "Could not resolve created protocol id for \(title)."])
        }
        return created.id
    }

    private func logCompletion(protocolId: UUID, on day: Date, hour: Int) throws {
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        try commitmentStore.recordCompletion(for: protocolId, at: date)
    }

    private func day(_ offset: Int, weekStart: Date) -> Date {
        let shifted = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
        return DateRules.startOfDay(shifted, calendar: calendar)
    }

    private func scenarioReferenceDate(for scenario: DevSeedScenario, anchor: Date) -> Date {
        let weekStart = DateRules.startOfDay(
            DateRules.weekInterval(containing: anchor, calendar: calendar).start,
            calendar: calendar
        )

        let target: Date
        switch scenario {
        case .freshStartMinimal:
            target = day(1, weekStart: weekStart)
            return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: target) ?? target
        case .stableWeek:
            target = day(2, weekStart: weekStart)
            return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: target) ?? target
        case .overloadedWeek:
            target = day(4, weekStart: weekStart)
            return calendar.date(bySettingHour: 20, minute: 15, second: 0, of: target) ?? target
        case .checkInDueTonight:
            target = day(3, weekStart: weekStart)
            return calendar.date(bySettingHour: 19, minute: 15, second: 0, of: target) ?? target
        case .inRecovery:
            target = day(2, weekStart: weekStart)
            return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: target) ?? target
        case .usedForAWhile:
            let future = calendar.date(byAdding: .day, value: 19, to: weekStart) ?? weekStart
            return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: future) ?? future
        }
    }

    private func resetDailyCheckInPromptState() {
        userDefaults.removeObject(forKey: DailyCheckInPolicy.Keys.lastCompletedDay)
        userDefaults.removeObject(forKey: DailyCheckInPolicy.Keys.lastPromptedDay)
        userDefaults.removeObject(forKey: DailyCheckInPolicy.Keys.repromptedDay)
        userDefaults.removeObject(forKey: DailyCheckInPolicy.Keys.deferredUntilTimestamp)
    }

    private var oneTimePresentationKeys: [String] {
        [
            "phase1MotionSessionID",
            "didAnimateCockpitPhase1SessionID",
            "didAnimateLogsPhase1SessionID",
            "didAnimatePlanColumnsSessionID",
            "didDismissPlanBoardHintSessionID",
        ]
    }

    private var appDefaultsKeysForFullWipe: [String] {
        [
            "hasCompletedOnboarding",
            WalkthroughController.StorageKeys.hasCompletedWalkthrough,
            "appAppearanceMode",
            "phase1MotionSessionID",
            "didAnimateCockpitPhase1SessionID",
            "didAnimateLogsPhase1SessionID",
            "didAnimatePlanColumnsSessionID",
            "didDismissPlanBoardHintSessionID",
            DailyCheckInPolicy.Keys.lastCompletedDay,
            DailyCheckInPolicy.Keys.lastPromptedDay,
            DailyCheckInPolicy.Keys.repromptedDay,
            DailyCheckInPolicy.Keys.deferredUntilTimestamp,
            DailyCheckInPolicy.Keys.hour,
            DailyCheckInPolicy.Keys.minute,
            "recent_protocol_icon_symbols_v1",
            "didRunFreshStartReset20260303",
            "didRunProtocolReset20260303",
        ]
    }
}
