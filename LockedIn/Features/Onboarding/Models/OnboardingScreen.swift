//
//  OnboardingScreen.swift
//  LockedIn
//
//  Model representing an onboarding screen configuration
//

import Foundation

struct OnboardingScreen: Identifiable, Equatable {
    let id: String
    let step: Int
    let totalSteps: Int
    let title: String
    let screenType: ScreenType
    
    enum ScreenType: String, CaseIterable {
        case identityWarning = "identity_warning"
        case failureLoop = "failure_loop"
        case commitmentEngine = "commitment_engine"
        case aiRegulator = "ai_regulator"
        case nonNegotiables = "non_negotiables"
        case commitmentAgreement = "commitment_agreement"
        case cockpitPreview = "cockpit_preview"
    }
}

// MARK: - Onboarding Flow Configuration
extension OnboardingScreen {
    static let onboardingFlow: [OnboardingScreen] = [
        OnboardingScreen(
            id: "bf3ce36d862d4402a679fa0fba205f3d",
            step: 1,
            totalSteps: 7,
            title: "Identity & Warning",
            screenType: .identityWarning
        ),
        OnboardingScreen(
            id: "ee4de9152cf84c8c9bf2bd80f2495b0b",
            step: 2,
            totalSteps: 7,
            title: "The Failure Loop",
            screenType: .failureLoop
        )
        // Additional screens will be added as they are implemented
    ]
}
