import Foundation
import Combine

@MainActor
final class RecoveryModeViewModel: ObservableObject {
    @Published private(set) var step: RecoveryFlowState = .entry
    @Published private(set) var protocolOptions: [RecoveryProtocolOption] = []
    @Published var selectedProtocolId: UUID?
    @Published private(set) var triggerProtocolTitle: String?
    @Published private(set) var pausedProtocolTitle: String?
    @Published private(set) var requiresPauseSelection = false
    @Published private(set) var isPendingResolution = false
    @Published private(set) var warningMessage: String?

    private let commitmentStore: CommitmentSystemStore
    private let planStore: PlanStore
    private let referenceDateProvider: () -> Date

    init(
        commitmentStore: CommitmentSystemStore,
        planStore: PlanStore,
        referenceDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.commitmentStore = commitmentStore
        self.planStore = planStore
        self.referenceDateProvider = referenceDateProvider
    }

    var canConfirmPauseSelection: Bool {
        selectedProtocolId != nil
    }

    var recommendedProtocolId: UUID? {
        protocolOptions.first(where: { $0.isRecommended })?.id
    }

    func refresh() {
        warningMessage = nil
        let now = referenceDateProvider()

        guard let context = commitmentStore.recoveryEntryContext(referenceDate: now) else {
            isPendingResolution = false
            return
        }

        isPendingResolution = true
        requiresPauseSelection = context.requiresPauseSelection
        triggerProtocolTitle = context.triggerProtocolId.flatMap { commitmentStore.nonNegotiable(id: $0)?.definition.title }
        pausedProtocolTitle = context.pausedProtocolId.flatMap { commitmentStore.nonNegotiable(id: $0)?.definition.title }

        let plannedLoads = activePlannedLoadsThisWeek()
        let options = context.candidateProtocolIds.compactMap { id -> RecoveryProtocolOption? in
            guard let nonNegotiable = commitmentStore.nonNegotiable(id: id) else { return nil }
            let weeklyLoad = NonNegotiableDefinition.normalizedFrequency(
                nonNegotiable.definition.frequencyPerWeek,
                mode: nonNegotiable.definition.mode
            )
            let violations = currentWindowViolations(for: nonNegotiable, now: now)
            let planned = plannedLoads[id, default: 0]
            let score = (violations * 100) + (weeklyLoad * 10) + planned

            return RecoveryProtocolOption(
                id: id,
                title: nonNegotiable.definition.title,
                modeLabel: nonNegotiable.definition.mode == .daily ? "DAILY" : "SESSION",
                weeklyLoadText: nonNegotiable.definition.mode == .daily ? "7/week" : "\(weeklyLoad)x/week",
                stateText: nonNegotiable.state == .recovery ? "In recovery" : "Active",
                currentWindowViolations: violations,
                plannedLoadCount: planned,
                recoveryLoadScore: score,
                isRecommended: false
            )
        }

        let sorted = options.sorted { lhs, rhs in
            if lhs.recoveryLoadScore != rhs.recoveryLoadScore {
                return lhs.recoveryLoadScore > rhs.recoveryLoadScore
            }
            if lhs.title != rhs.title {
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }

        protocolOptions = sorted.enumerated().map { index, option in
            RecoveryProtocolOption(
                id: option.id,
                title: option.title,
                modeLabel: option.modeLabel,
                weeklyLoadText: option.weeklyLoadText,
                stateText: option.stateText,
                currentWindowViolations: option.currentWindowViolations,
                plannedLoadCount: option.plannedLoadCount,
                recoveryLoadScore: option.recoveryLoadScore,
                isRecommended: index == 0
            )
        }

        if let selected = selectedProtocolId,
           protocolOptions.contains(where: { $0.id == selected }) == false {
            selectedProtocolId = nil
        }

        if requiresPauseSelection == false {
            selectedProtocolId = nil
        }
    }

    func continueFromEntry() {
        if requiresPauseSelection {
            step = .selectProtocol
        } else {
            step = .confirmed
        }
    }

    func selectProtocol(_ id: UUID) {
        if selectedProtocolId == id {
            selectedProtocolId = nil
        } else {
            selectedProtocolId = id
        }
    }

    @discardableResult
    func confirmPauseSelection() -> Bool {
        guard requiresPauseSelection else {
            step = .confirmed
            return true
        }

        guard let selectedProtocolId else {
            warningMessage = "Select a protocol to pause before continuing."
            return false
        }

        do {
            let now = referenceDateProvider()
            try commitmentStore.pauseProtocolForRecovery(protocolId: selectedProtocolId, referenceDate: now)
            planStore.pauseAllocations(for: selectedProtocolId, referenceDate: now)
            pausedProtocolTitle = commitmentStore.nonNegotiable(id: selectedProtocolId)?.definition.title
            step = .confirmed
            return true
        } catch {
            if let copy = commitmentStore.policyCopy(for: error) {
                warningMessage = copy.message
            } else {
                warningMessage = "Unable to pause selected protocol right now."
            }
            return false
        }
    }

    func completeFlow() {
        commitmentStore.completeRecoveryEntryResolution()
    }

    func dismissWarning() {
        warningMessage = nil
    }
}

private extension RecoveryModeViewModel {
    func currentWindowViolations(for nonNegotiable: NonNegotiable, now: Date) -> Int {
        let window = nonNegotiable.windows.first {
            now >= $0.startDate && now < $0.endDate
        } ?? nonNegotiable.windows.last

        guard let window else { return 0 }
        return nonNegotiable.violations.filter { $0.windowIndex == window.index }.count
    }

    func activePlannedLoadsThisWeek() -> [UUID: Int] {
        let snapshot = planStore.currentWeekSnapshot()
        var result: [UUID: Int] = [:]
        for allocation in snapshot.currentWeekAllocations where allocation.status == .active {
            result[allocation.protocolId, default: 0] += 1
        }
        return result
    }
}
