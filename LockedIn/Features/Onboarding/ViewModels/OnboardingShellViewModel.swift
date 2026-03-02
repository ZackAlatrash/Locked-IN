//
//  OnboardingShellViewModel.swift
//  LockedIn
//
//  Thin bridge between onboarding view and coordinator.
//

import Foundation
import Combine

final class OnboardingShellViewModel: ObservableObject {
    @Published private(set) var currentStep: OnboardingStep

    private let coordinator: OnboardingCoordinator
    private var cancellables = Set<AnyCancellable>()
    var onComplete: (() -> Void)?

    var progress: Double {
        let total = Double(OnboardingStep.allCases.count)
        guard total > 0 else { return 0 }
        let index = Double((OnboardingStep.allCases.firstIndex(of: currentStep) ?? 0) + 1)
        return index / total
    }

    init(
        coordinator: OnboardingCoordinator,
        onComplete: (() -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.onComplete = onComplete
        self.currentStep = coordinator.currentStep

        coordinator.$currentStep
            .sink { [weak self] step in
                self?.currentStep = step
            }
            .store(in: &cancellables)
    }

    func next() -> OnboardingNextResult {
        coordinator.next()
    }

    @discardableResult
    func back() -> Bool {
        coordinator.back()
    }

    @discardableResult
    func skip() -> Bool {
        coordinator.skip()
    }

    func completeOnboarding() {
        onComplete?()
    }
}
