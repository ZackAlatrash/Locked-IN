//
//  OnboardingEngine.swift
//  LockedIn
//
//  Pure business logic for onboarding validation and gating
//  No SwiftUI dependencies - fully testable
//

import Foundation

/// Pure logic engine for onboarding rules and validation
/// Called by OnboardingShellViewModel to determine if navigation can proceed
final class OnboardingEngine {
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Navigation Gating
    
    /// Determines if the user can advance from the current step
    func canAdvance(from step: OnboardingStep, data: OnboardingData) -> ValidationResult {
        switch step {
        case .identityWarning, .failureLoop, .coreDifferentiation, .nonNegotiables, .aiRegulator:
            // These screens have no validation requirements
            return .valid
            
        case .userHistory:
            return validateUserHistory(data)
            
        case .createNonNegotiable:
            return validateNonNegotiable(data)
            
        case .commitmentAgreement:
            return validateCommitment(data)
        }
    }
    
    /// Determines if the user can go back from the current step
    func canGoBack(from step: OnboardingStep) -> Bool {
        // Can go back from any step except the first one
        return step != .identityWarning
    }
    
    // MARK: - Screen-Specific Validation
    
    private func validateUserHistory(_ data: OnboardingData) -> ValidationResult {
        guard data.selectedUserHistoryOption != nil else {
            return .invalid(reason: .userHistoryNotSelected)
        }
        return .valid
    }
    
    private func validateNonNegotiable(_ data: OnboardingData) -> ValidationResult {
        guard !data.nonNegotiableAction.isEmpty,
              !data.nonNegotiableMinimum.isEmpty else {
            return .invalid(reason: .nonNegotiableIncomplete)
        }
        return .valid
    }
    
    private func validateCommitment(_ data: OnboardingData) -> ValidationResult {
        guard data.hasAcceptedTerms else {
            return .invalid(reason: .termsNotAccepted)
        }
        guard !data.fullName.isEmpty else {
            return .invalid(reason: .nameEmpty)
        }
        return .valid
    }
    
    // MARK: - Step-Specific Checks
    
    /// Quick check for a specific step's validation state
    func isStepValid(_ step: OnboardingStep, data: OnboardingData) -> Bool {
        canAdvance(from: step, data: data).isValid
    }
}
