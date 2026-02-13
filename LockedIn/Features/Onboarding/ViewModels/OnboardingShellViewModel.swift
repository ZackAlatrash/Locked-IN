//
//  OnboardingShellViewModel.swift
//  LockedIn
//
//  Navigation-only ViewModel for the onboarding shell
//  All screen-specific state moved to individual ViewModels
//

import SwiftUI
import Combine

final class OnboardingShellViewModel: ObservableObject {
    
    // MARK: - Published Properties (Navigation Only)
    @Published private(set) var currentStep: OnboardingStep = .identityWarning
    @Published private(set) var isTransitioning: Bool = false
    @Published var showPaywall: Bool = false
    
    // MARK: - Dependencies
    private let engine: OnboardingEngine
    private let flow: OnboardingFlow
    var onComplete: (() -> Void)?
    
    // MARK: - Screen-Specific ViewModels (injected)
    let userHistoryViewModel = UserHistoryViewModel()
    let createNonNegotiableViewModel = CreateNonNegotiableViewModel()
    let commitmentAgreementViewModel = CommitmentAgreementViewModel()
    
    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties (from StepConfig)
    var stepLabel: String { currentStep.stepLabel }
    var totalSteps: Int { OnboardingStep.totalCount }
    
    var showBackButton: Bool { currentStep.config.showBackButton }
    var showCloseButton: Bool { currentStep.config.showCloseButton }
    var showHelpButton: Bool { currentStep.config.showHelpButton }
    var showSkipButton: Bool { currentStep.config.showSkipButton }
    
    var ctaTitle: String { currentStep.config.ctaTitle }
    var ctaSubtitle: String { currentStep.config.ctaSubtitle }
    
    var canGoBack: Bool { flow.previousStep(before: currentStep) != nil }
    var isLastStep: Bool { currentStep == flow.lastStep }
    
    /// Whether the current step can advance (delegated to engine)
    var canAdvanceCurrentStep: Bool {
        switch currentStep {
        case .userHistory:
            return userHistoryViewModel.isValid
        case .createNonNegotiable:
            return createNonNegotiableViewModel.isValid
        case .commitmentAgreement:
            return commitmentAgreementViewModel.isValid
        default:
            return true
        }
    }
    
    // MARK: - Initialization
    init(
        engine: OnboardingEngine = OnboardingEngine(),
        flow: OnboardingFlow = OnboardingFlow(),
        onComplete: (() -> Void)? = nil
    ) {
        self.engine = engine
        self.flow = flow
        self.onComplete = onComplete
        
        setupBindings()
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        // Observe changes from child ViewModels to trigger UI updates
        userHistoryViewModel.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        createNonNegotiableViewModel.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        commitmentAgreementViewModel.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation Actions
    
    /// Advances to the next screen with validation
    func advanceToNextScreen() {
        guard !isTransitioning else { return }
        
        guard canAdvanceCurrentStep else {
            withAnimation {
                // Validation error handled by individual ViewModels
                triggerValidationError()
            }
            return
        }
        
        proceedToNext()
    }
    
    private func triggerValidationError() {
        switch currentStep {
        case .userHistory:
            break // No validation error to show
        case .createNonNegotiable:
            createNonNegotiableViewModel.showValidationError = true
        case .commitmentAgreement:
            commitmentAgreementViewModel.showValidationError = true
        default:
            break
        }
    }
    
    private func proceedToNext() {
        guard let next = flow.nextStep(after: currentStep, data: buildOnboardingData()) else {
            // Last step - show paywall as separate view
            withAnimation {
                showPaywall = true
            }
            return
        }
        
        isTransitioning = true
        currentStep = next
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }
    
    /// Called when paywall is dismissed (user subscribed or skipped)
    func completeOnboarding() {
        onComplete?()
    }
    
    /// Goes back to the previous screen
    func goToPreviousScreen() {
        guard !isTransitioning, let previous = flow.previousStep(before: currentStep) else { return }
        
        isTransitioning = true
        currentStep = previous
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }
    
    /// Skip action - jumps directly to commitment agreement
    func skip() {
        guard !isTransitioning else { return }
        
        isTransitioning = true
        currentStep = .commitmentAgreement
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }
    
    /// Close/dismiss onboarding
    func close() {
        // Could trigger a dismiss or navigate away
    }
    
    /// Help action
    func showHelp() {
        // Could show a help sheet
    }
    
    // MARK: - Data Assembly
    
    /// Builds OnboardingData from screen ViewModels for engine validation
    private func buildOnboardingData() -> OnboardingData {
        var data = OnboardingData()
        data.selectedUserHistoryOption = userHistoryViewModel.exportData()
        let nonNegData = createNonNegotiableViewModel.exportData()
        data.nonNegotiableAction = nonNegData.action
        data.nonNegotiableFrequency = nonNegData.frequency
        data.nonNegotiableMinimum = nonNegData.minimum
        let commitmentData = commitmentAgreementViewModel.exportData()
        data.hasAcceptedTerms = commitmentData.hasAcceptedTerms
        data.fullName = commitmentData.fullName
        return data
    }
}
