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
        case .welcome:
            return OnboardingPresentationConfig(
                showBackButton: false,
                showSkipButton: false,
                ctaTitle: "Enter",
                ctaSubtitle: "",
                stepLabel: stepLabel
            )

        case .identityWarning:
            return OnboardingPresentationConfig(
                showBackButton: true,
                showSkipButton: false,
                ctaTitle: "I Understand",
                ctaSubtitle: "Proceeding implies absolute commitment",
                stepLabel: stepLabel
            )
            
        case .failureLoop:
            return OnboardingPresentationConfig(
                showBackButton: true,
                showSkipButton: true,
                ctaTitle: "Break the cycle",
                ctaSubtitle: "Momento Mori",
                stepLabel: stepLabel
            )
            
        case .coreDifferentiation:
            return OnboardingPresentationConfig(
                showBackButton: true,
                showSkipButton: true,
                ctaTitle: "I Understand",
                ctaSubtitle: "No man is free who is not master of himself",
                stepLabel: stepLabel
            )
            
        case .commitmentAgreement:
            return OnboardingPresentationConfig(
                showBackButton: true,
                showSkipButton: false,
                ctaTitle: "Sign & Lock In",
                ctaSubtitle: "Your commitment begins now",
                stepLabel: stepLabel
            )
        }
    }
}
