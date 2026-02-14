//
//  OnboardingPresentationConfig.swift
//  LockedIn
//
//  Presentation configuration for onboarding screens
//  Contains all UI-facing config (CTA labels, button visibility, step labeling)
//  Separated from Domain to maintain pure business logic layer
//

import Foundation

/// Presentation configuration for each onboarding step
struct OnboardingPresentationConfig {
    let showBackButton: Bool
    let showCloseButton: Bool
    let showHelpButton: Bool
    let showSkipButton: Bool
    let ctaTitle: String
    let ctaSubtitle: String
    let stepLabel: String
    
    /// Total number of onboarding steps (for display purposes)
    static let totalSteps: Int = OnboardingStep.allCases.count
    
    /// Creates presentation config for a given step
    static func config(for step: OnboardingStep) -> OnboardingPresentationConfig {
        let stepNumber = OnboardingStep.allCases.firstIndex(of: step).map { $0 + 1 } ?? 1
        let stepLabel = String(format: "Step %02d / %02d", stepNumber, totalSteps)
        
        switch step {
        case .identityWarning:
            return OnboardingPresentationConfig(
                showBackButton: false,
                showCloseButton: true,
                showHelpButton: true,
                showSkipButton: false,
                ctaTitle: "I Understand",
                ctaSubtitle: "Proceeding implies absolute commitment",
                stepLabel: stepLabel
            )
            
        case .failureLoop:
            return OnboardingPresentationConfig(
                showBackButton: true,
                showCloseButton: false,
                showHelpButton: false,
                showSkipButton: true,
                ctaTitle: "Break the cycle",
                ctaSubtitle: "Momento Mori",
                stepLabel: stepLabel
            )
            
        case .userHistory:
            return OnboardingPresentationConfig(
                showBackButton: true,
                showCloseButton: false,
                showHelpButton: false,
                showSkipButton: true,
                ctaTitle: "Continue",
                ctaSubtitle: "The Dichotomy of Control",
                stepLabel: stepLabel
            )
            
        case .coreDifferentiation:
            return OnboardingPresentationConfig(
                showBackButton: true,
                showCloseButton: false,
                showHelpButton: false,
                showSkipButton: true,
                ctaTitle: "I Understand",
                ctaSubtitle: "No man is free who is not master of himself",
                stepLabel: stepLabel
            )
            
        case .nonNegotiables:
            return OnboardingPresentationConfig(
                showBackButton: true,
                showCloseButton: false,
                showHelpButton: false,
                showSkipButton: true,
                ctaTitle: "Continue",
                ctaSubtitle: "Locked In: discipline over motivation",
                stepLabel: stepLabel
            )
            
        case .createNonNegotiable:
            return OnboardingPresentationConfig(
                showBackButton: true,
                showCloseButton: false,
                showHelpButton: false,
                showSkipButton: true,
                ctaTitle: "Lock in",
                ctaSubtitle: "",
                stepLabel: stepLabel
            )
            
        case .aiRegulator:
            return OnboardingPresentationConfig(
                showBackButton: true,
                showCloseButton: false,
                showHelpButton: false,
                showSkipButton: false,
                ctaTitle: "Accept Regulation",
                ctaSubtitle: "Authority verified by Locked In protocol",
                stepLabel: stepLabel
            )
            
        case .commitmentAgreement:
            return OnboardingPresentationConfig(
                showBackButton: true,
                showCloseButton: false,
                showHelpButton: false,
                showSkipButton: false,
                ctaTitle: "Sign & Lock In",
                ctaSubtitle: "Your commitment begins now",
                stepLabel: stepLabel
            )
        }
    }
}
