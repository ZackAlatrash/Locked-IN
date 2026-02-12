//
//  OnboardingShellViewModel.swift
//  LockedIn
//
//  ViewModel for the shared onboarding shell
//  Manages progress bar, header icons, and CTA button state across all screens
//

import SwiftUI
import Combine

final class OnboardingShellViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var currentStep: Int = 1
    @Published private(set) var totalSteps: Int = 8
    @Published private(set) var isTransitioning: Bool = false
    @Published private(set) var progressAnimationProgress: CGFloat = 0 // 0 to 1 for loading animation
    
    // Header configuration per screen
    @Published private(set) var showBackButton: Bool = false
    @Published private(set) var showCloseButton: Bool = true
    @Published private(set) var showHelpButton: Bool = true
    @Published private(set) var showSkipButton: Bool = false
    
    // CTA configuration per screen
    @Published private(set) var ctaTitle: String = "I Understand"
    @Published private(set) var ctaSubtitle: String = "Proceeding implies absolute commitment"
    
    // MARK: - Screen 3 Validation (User History)
    @Published var selectedUserHistoryOption: String? = nil
    
    // MARK: - Screen 6 Validation (Create Non-Negotiable)
    @Published var nonNegotiableAction: String = ""
    @Published var nonNegotiableFrequency: String = "Every Day"
    @Published var nonNegotiableMinimum: String = ""
    
    // MARK: - Final Screen Validation
    @Published var hasAcceptedTerms: Bool = false
    @Published var fullName: String = ""
    @Published var showValidationError: Bool = false
    
    // MARK: - Navigation Callbacks
    var onComplete: (() -> Void)?
    
    // MARK: - Screen Configuration
    struct ScreenConfig {
        let showBackButton: Bool
        let showCloseButton: Bool
        let showHelpButton: Bool
        let showSkipButton: Bool
        let ctaTitle: String
        let ctaSubtitle: String
    }
    
    private let screenConfigs: [Int: ScreenConfig] = [
        1: ScreenConfig(
            showBackButton: false,
            showCloseButton: true,
            showHelpButton: true,
            showSkipButton: false,
            ctaTitle: "I Understand",
            ctaSubtitle: "Proceeding implies absolute commitment"
        ),
        2: ScreenConfig(
            showBackButton: true,
            showCloseButton: false,
            showHelpButton: false,
            showSkipButton: true,
            ctaTitle: "Break the cycle",
            ctaSubtitle: "Momento Mori"
        ),
        3: ScreenConfig(
            showBackButton: true,
            showCloseButton: false,
            showHelpButton: false,
            showSkipButton: true,
            ctaTitle: "Continue",
            ctaSubtitle: "The Dichotomy of Control"
        ),
        4: ScreenConfig(
            showBackButton: true,
            showCloseButton: false,
            showHelpButton: false,
            showSkipButton: true,
            ctaTitle: "I Understand",
            ctaSubtitle: "No man is free who is not master of himself"
        ),
        5: ScreenConfig(
            showBackButton: true,
            showCloseButton: false,
            showHelpButton: false,
            showSkipButton: true,
            ctaTitle: "Continue",
            ctaSubtitle: "Locked In: discipline over motivation"
        ),
        6: ScreenConfig(
            showBackButton: true,
            showCloseButton: false,
            showHelpButton: false,
            showSkipButton: true,
            ctaTitle: "Lock in",
            ctaSubtitle: ""
        ),
        7: ScreenConfig(
            showBackButton: true,
            showCloseButton: false,
            showHelpButton: false,
            showSkipButton: false,
            ctaTitle: "Accept Regulation",
            ctaSubtitle: "Authority verified by Locked In protocol"
        ),
        8: ScreenConfig(
            showBackButton: true,
            showCloseButton: false,
            showHelpButton: false,
            showSkipButton: false,
            ctaTitle: "Sign & Lock In",
            ctaSubtitle: "Your commitment begins now"
        )
    ]
    
    // MARK: - Computed Properties
    var stepLabel: String {
        String(format: "Step %02d / %02d", currentStep, totalSteps)
    }
    
    var canGoBack: Bool {
        currentStep > 1
    }
    
    var isLastStep: Bool {
        currentStep == totalSteps
    }
    
    // MARK: - Initialization
    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
        applyConfig(for: 1)
    }
    
    // MARK: - Actions
    
    /// Advances to the next screen with animated progress bar
    func advanceToNextScreen() {
        // Check validation on screen 3 (user history)
        if currentStep == 3 {
            if selectedUserHistoryOption == nil {
                withAnimation {
                    showValidationError = true
                }
                return
            }
        }
        
        // Check validation on screen 6 (create non-negotiable)
        if currentStep == 6 {
            if nonNegotiableAction.isEmpty || nonNegotiableMinimum.isEmpty {
                withAnimation {
                    showValidationError = true
                }
                return
            }
        }
        
        // Check validation on final step
        if currentStep == totalSteps {
            if !hasAcceptedTerms || fullName.isEmpty {
                withAnimation {
                    showValidationError = true
                }
                return
            }
            onComplete?()
            return
        }
        
        guard !isTransitioning, currentStep < totalSteps else { return }
        
        isTransitioning = true
        
        let nextStep = currentStep + 1
        
        // Progress bar and content change happen simultaneously
        currentStep = nextStep
        applyConfig(for: nextStep)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isTransitioning = false
        }
    }
    
    /// Checks if screen 3 can be completed (user made a choice)
    var canCompleteScreen3: Bool {
        selectedUserHistoryOption != nil
    }
    
    /// Checks if screen 6 can be completed (all fields filled)
    var canCompleteScreen6: Bool {
        !nonNegotiableAction.isEmpty && !nonNegotiableMinimum.isEmpty
    }
    
    /// Checks if the final step can be completed
    var canCompleteFinalStep: Bool {
        hasAcceptedTerms && !fullName.isEmpty
    }
    
    /// Goes back to the previous screen
    func goToPreviousScreen() {
        guard !isTransitioning, currentStep > 1 else { return }
        
        isTransitioning = true
        
        let previousStep = currentStep - 1
        currentStep = previousStep
        applyConfig(for: previousStep)
        
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
        // For now, just a placeholder
    }
    
    /// Help action
    func showHelp() {
        // Could show a help sheet
        // For now, just a placeholder
    }
    
    // MARK: - Private Methods
    private func applyConfig(for step: Int) {
        guard let config = screenConfigs[step] else { return }
        
        showBackButton = config.showBackButton
        showCloseButton = config.showCloseButton
        showHelpButton = config.showHelpButton
        showSkipButton = config.showSkipButton
        ctaTitle = config.ctaTitle
        ctaSubtitle = config.ctaSubtitle
    }
}
