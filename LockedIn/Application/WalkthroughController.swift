import Foundation
import Combine

enum WalkthroughStep: CaseIterable {
    case intro
    case cockpitIntro
    case cockpitReliability
    case cockpitStreak
    case cockpitProtocols
    case createName
    case createProtocol
    case planningIntro
    case planningQueue
    case planningSelectProtocol
    case planningSelectSlot
    case planningPlacedConfirmation
    case planningRegulatorIntro
    case planningRunRegulator
    case planningApplyDraft
    case planningCompleted
    case logsIntro
    case logsMatrix
    case logsHistory
    case checkInIntro
    case completeProtocol
    case finished
}

private extension WalkthroughStep {
    static let orderedFlow: [WalkthroughStep] = [
        .intro,
        .cockpitIntro,
        .cockpitReliability,
        .cockpitStreak,
        .cockpitProtocols,
        .createName,
        .createProtocol,
        .planningIntro,
        .planningQueue,
        .planningSelectProtocol,
        .planningSelectSlot,
        .planningPlacedConfirmation,
        .planningRegulatorIntro,
        .planningRunRegulator,
        .planningApplyDraft,
        .planningCompleted,
        .logsIntro,
        .logsMatrix,
        .logsHistory,
        .checkInIntro,
        .completeProtocol,
        .finished,
    ]
}

@MainActor
final class WalkthroughController: ObservableObject {
    enum StorageKeys {
        static let hasCompletedWalkthrough = "hasCompletedWalkthrough"
    }

    @Published var isActive: Bool = false
    @Published var step: WalkthroughStep = .intro
    @Published var walkthroughProtocolId: UUID? = nil

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if hasCompletedWalkthrough {
            step = .finished
        }
    }

    var hasCompletedWalkthrough: Bool {
        userDefaults.bool(forKey: StorageKeys.hasCompletedWalkthrough)
    }

    func start() {
        guard hasCompletedWalkthrough == false else {
            isActive = false
            step = .finished
            return
        }

        isActive = true
        step = .intro
        walkthroughProtocolId = nil
    }

    func skip() {
        finish()
    }

    @discardableResult
    func advance(to targetStep: WalkthroughStep) -> Bool {
        guard isActive else { return false }
        guard targetStep != .finished else {
            finish()
            return true
        }

        guard let nextStep = step.next, nextStep == targetStep else { return false }
        step = targetStep
        return true
    }

    func finish() {
        isActive = false
        step = .finished
        userDefaults.set(true, forKey: StorageKeys.hasCompletedWalkthrough)
    }

    @discardableResult
    func handleProtocolCreated(id: UUID) -> Bool {
        guard isActive, step == .createProtocol else { return false }
        walkthroughProtocolId = id
        step = .planningIntro
        return true
    }

    @discardableResult
    func handleCreateProtocolTapped() -> Bool {
        guard isActive, step == .createName else { return false }
        step = .createProtocol
        return true
    }

    @discardableResult
    func handleDraftGenerated() -> Bool {
        guard isActive, step == .planningRunRegulator else { return false }
        step = .planningApplyDraft
        return true
    }

    @discardableResult
    func handleDraftApplied() -> Bool {
        guard isActive, step == .planningApplyDraft else { return false }
        step = .planningCompleted
        return true
    }

    @discardableResult
    func handleProtocolCompleted(id: UUID) -> Bool {
        guard isActive, step == .completeProtocol else { return false }
        guard walkthroughProtocolId == nil || walkthroughProtocolId == id else { return false }
        finish()
        return true
    }
}

private extension WalkthroughStep {
    var next: WalkthroughStep? {
        guard let currentIndex = Self.orderedFlow.firstIndex(of: self) else { return nil }
        let nextIndex = currentIndex + 1
        guard Self.orderedFlow.indices.contains(nextIndex) else { return nil }
        return Self.orderedFlow[nextIndex]
    }
}
