//
//  OnboardingData.swift
//  LockedIn
//
//  Shared state container for onboarding data
//  Passed between screens via dependency injection
//

import Foundation

/// Container for all onboarding data collected across screens
struct OnboardingData {
    // MARK: - Commitment Agreement
    var hasAcceptedTerms: Bool = false
    var fullName: String = ""
}

// MARK: - Validation Results
enum ValidationResult {
    case valid
    case invalid(reason: ValidationReason)
    
    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
}

enum ValidationReason {
    case termsNotAccepted
    case nameEmpty
}
