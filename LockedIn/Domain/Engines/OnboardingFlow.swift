//
//  OnboardingFlow.swift
//  LockedIn
//
//  Explicit state machine for onboarding navigation
//  Replaces rawValue arithmetic with explicit transitions
//

import Foundation

/// Flow engine for onboarding navigation
/// Encapsulates all navigation logic with explicit state transitions
struct OnboardingFlow {
    
    /// Determines the next step based on current step and user data
    /// - Parameters:
    ///   - step: Current onboarding step
    ///   - data: User's onboarding data (for conditional logic)
    /// - Returns: The next step, or nil if at the end
    func nextStep(after step: OnboardingStep, data: OnboardingData) -> OnboardingStep? {
        switch step {
        case .identityWarning:
            return .failureLoop
        case .failureLoop:
            return .userHistory
        case .userHistory:
            return .coreDifferentiation
        case .coreDifferentiation:
            return .nonNegotiables
        case .nonNegotiables:
            return .createNonNegotiable
        case .createNonNegotiable:
            return .aiRegulator
        case .aiRegulator:
            return .commitmentAgreement
        case .commitmentAgreement:
            return .paywall
        case .paywall:
            return nil // End of onboarding
        }
    }
    
    /// Determines the previous step
    /// - Parameter step: Current onboarding step
    /// - Returns: The previous step, or nil if at the beginning
    func previousStep(before step: OnboardingStep) -> OnboardingStep? {
        switch step {
        case .identityWarning:
            return nil // Beginning of onboarding
        case .failureLoop:
            return .identityWarning
        case .userHistory:
            return .failureLoop
        case .coreDifferentiation:
            return .userHistory
        case .nonNegotiables:
            return .coreDifferentiation
        case .createNonNegotiable:
            return .nonNegotiables
        case .aiRegulator:
            return .createNonNegotiable
        case .commitmentAgreement:
            return .aiRegulator
        case .paywall:
            return .commitmentAgreement
        }
    }
    
    /// Check if a step can be skipped to another step
    /// - Parameters:
    ///   - from: Source step
    ///   - to: Target step
    /// - Returns: True if skip is allowed
    func canSkip(from: OnboardingStep, to: OnboardingStep) -> Bool {
        // Only allow skip to commitment agreement from certain steps
        switch (from, to) {
        case (.failureLoop, .commitmentAgreement),
             (.userHistory, .commitmentAgreement),
             (.coreDifferentiation, .commitmentAgreement),
             (.nonNegotiables, .commitmentAgreement),
             (.createNonNegotiable, .commitmentAgreement):
            return true
        default:
            return false
        }
    }
    
    /// Get the first step of onboarding
    var firstStep: OnboardingStep { .identityWarning }
    
    /// Get the last step of onboarding
    var lastStep: OnboardingStep { .commitmentAgreement }
}
