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
            return nil // End of onboarding - paywall shown separately
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
        }
    }
    
    /// Skip to commitment agreement from the current step
    /// - Parameters:
    ///   - step: Current onboarding step
    ///   - data: User's onboarding data (for conditional logic)
    /// - Returns: The skip target step, or nil if skip not allowed
    func skip(from step: OnboardingStep, data: OnboardingData) -> OnboardingStep? {
        // Only allow skip from certain steps
        switch step {
        case .failureLoop,
             .userHistory,
             .coreDifferentiation,
             .nonNegotiables,
             .createNonNegotiable:
            return .commitmentAgreement
        case .identityWarning,
             .aiRegulator,
             .commitmentAgreement:
            return nil // Skip not allowed from these steps
        }
    }
    
    /// Check if skip is allowed from the current step
    func canSkip(from step: OnboardingStep) -> Bool {
        skip(from: step, data: OnboardingData()) != nil
    }
    
    /// Check if the step is the first step
    func isFirstStep(_ step: OnboardingStep) -> Bool {
        step == .identityWarning
    }
    
    /// Check if the step is the last step
    func isLastStep(_ step: OnboardingStep) -> Bool {
        step == .commitmentAgreement
    }
}
