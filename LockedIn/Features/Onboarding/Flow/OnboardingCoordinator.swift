//
//  OnboardingCoordinator.swift
//  LockedIn
//
//  Coordinates onboarding screen state, domain validation, and flow transitions.
//

import Foundation
import Combine

enum OnboardingNextResult {
    case advanced
    case reachedEnd
    case blocked
}

final class OnboardingCoordinator: ObservableObject {
    private let flow: OnboardingFlow
    private let engine: OnboardingEngine

    @Published private(set) var currentStep: OnboardingStep
    @Published private(set) var isTransitioning = false

    let commitmentAgreementVM: CommitmentAgreementViewModel

    private var cancellables = Set<AnyCancellable>()

    init(
        initialStep: OnboardingStep = .welcome,
        flow: OnboardingFlow,
        engine: OnboardingEngine
    ) {
        self.currentStep = initialStep
        self.flow = flow
        self.engine = engine

        self.commitmentAgreementVM = CommitmentAgreementViewModel()

        bindScreenViewModels()
    }

    var canAdvanceCurrentStep: Bool {
        switch currentStep {
        case .commitmentAgreement:
            return commitmentAgreementVM.isValid
        default:
            return true
        }
    }

    func next() -> OnboardingNextResult {
        guard !isTransitioning else { return .blocked }

        let data = buildOnboardingData()
        let validation = engine.canAdvance(from: currentStep, data: data)

        guard validation.isValid else {
            applyValidationFailure(validation)
            return .blocked
        }

        guard let next = flow.nextStep(after: currentStep, data: data) else {
            return .reachedEnd
        }

        transition(to: next)
        return .advanced
    }

    @discardableResult
    func back() -> Bool {
        guard !isTransitioning, engine.canGoBack(from: currentStep) else { return false }
        guard let previous = flow.previousStep(before: currentStep) else { return false }

        transition(to: previous)
        return true
    }

    @discardableResult
    func skip() -> Bool {
        guard !isTransitioning else { return false }
        guard let target = flow.skip(from: currentStep, data: buildOnboardingData()) else { return false }

        transition(to: target)
        return true
    }

    private func bindScreenViewModels() {
        commitmentAgreementVM.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    private func applyValidationFailure(_ validation: ValidationResult) {
        guard case .invalid(let reason) = validation else { return }

        switch reason {
        case .termsNotAccepted, .nameEmpty:
            commitmentAgreementVM.showValidationError = true
        }
    }

    private func transition(to step: OnboardingStep) {
        isTransitioning = true
        currentStep = step

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }

    private func buildOnboardingData() -> OnboardingData {
        let commitmentData = commitmentAgreementVM.exportData()

        return OnboardingData(
            hasAcceptedTerms: commitmentData.hasAcceptedTerms,
            fullName: commitmentData.fullName
        )
    }
}
