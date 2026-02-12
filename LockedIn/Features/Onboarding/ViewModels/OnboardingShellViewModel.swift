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
    
    // MARK: - Shared Data (passed to screen ViewModels)
    @Published var data = OnboardingData()
    
    // MARK: - Dependencies
    private let engine: OnboardingEngine
    var onComplete: (() -> Void)?
    
    // MARK: - Computed Properties (from StepConfig)
    var stepLabel: String { currentStep.stepLabel }
    var totalSteps: Int { OnboardingStep.totalCount }
    
    var showBackButton: Bool { currentStep.config.showBackButton }
    var showCloseButton: Bool { currentStep.config.showCloseButton }
    var showHelpButton: Bool { currentStep.config.showHelpButton }
    var showSkipButton: Bool { currentStep.config.showSkipButton }
    
    var ctaTitle: String { currentStep.config.ctaTitle }
    var ctaSubtitle: String { currentStep.config.ctaSubtitle }
    
    var canGoBack: Bool { currentStep.previous != nil }
    var isLastStep: Bool { currentStep == .commitmentAgreement }
    
    /// Whether the current step can advance (delegated to engine)
    var canAdvanceCurrentStep: Bool {
        engine.isStepValid(currentStep, data: data)
    }
    
    // MARK: - Initialization
    init(
        engine: OnboardingEngine = .shared,
        onComplete: (() -> Void)? = nil
    ) {
        self.engine = engine
        self.onComplete = onComplete
    }
    
    // MARK: - Navigation Actions
    
    /// Advances to the next screen with validation
    func advanceToNextScreen() {
        guard !isTransitioning else { return }
        
        // Validate current step via engine
        let validation = engine.canAdvance(from: currentStep, data: data)
        
        switch validation {
        case .valid:
            proceedToNext()
        case .invalid:
            withAnimation {
                data.showValidationError = true
            }
        }
    }
    
    private func proceedToNext() {
        guard let next = currentStep.next else {
            // Last step - complete onboarding
            onComplete?()
            return
        }
        
        isTransitioning = true
        currentStep = next
        data.showValidationError = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }
    
    /// Goes back to the previous screen
    func goToPreviousScreen() {
        guard !isTransitioning, let previous = currentStep.previous else { return }
        
        isTransitioning = true
        currentStep = previous
        data.showValidationError = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }
    
    /// Skip action (same as advance for now)
    func skip() {
        advanceToNextScreen()
    }
    
    /// Close/dismiss onboarding
    func close() {
        // Could trigger a dismiss or navigate away
    }
    
    /// Help action
    func showHelp() {
        // Could show a help sheet
    }
}
