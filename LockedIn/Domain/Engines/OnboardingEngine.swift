//
//  OnboardingEngine.swift
//  LockedIn
//
//  Pure business logic for onboarding validation and gating
//  No SwiftUI dependencies - fully testable
//

import Foundation

/// Pure logic engine for onboarding rules and validation
/// Called by coordinator to determine if navigation can proceed
final class OnboardingEngine {

    init() {}

    /// Determines if the user can advance from the current step
    func canAdvance(from step: OnboardingStep, data: OnboardingData) -> ValidationResult {
        switch step {
        case .identityWarning, .failureLoop, .coreDifferentiation, .nonNegotiables, .aiRegulator:
            return .valid

        case .userHistory:
            return validateUserHistory(data)

        case .commitmentAgreement:
            return validateCommitment(data)
        }
    }

    /// Determines if the user can go back from the current step
    func canGoBack(from step: OnboardingStep) -> Bool {
        step != .identityWarning
    }

    private func validateUserHistory(_ data: OnboardingData) -> ValidationResult {
        guard data.selectedUserHistoryOption != nil else {
            return .invalid(reason: .userHistoryNotSelected)
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
}
