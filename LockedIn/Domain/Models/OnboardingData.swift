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
    // MARK: - Screen 3: User History
    var selectedUserHistoryOption: String?
    
    // MARK: - Screen 6: Create Non-Negotiable
    var nonNegotiableAction: String = ""
    var nonNegotiableFrequency: String = "Every Day"
    var nonNegotiableMinimum: String = ""
    
    // MARK: - Screen 8: Commitment Agreement
    var hasAcceptedTerms: Bool = false
    var fullName: String = ""
    
    // MARK: - Validation State
    var showValidationError: Bool = false
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
    case userHistoryNotSelected
    case nonNegotiableIncomplete
    case termsNotAccepted
    case nameEmpty
    
    var message: String {
        switch self {
        case .userHistoryNotSelected:
            return "Please select an option to continue"
        case .nonNegotiableIncomplete:
            return "Please complete all fields"
        case .termsNotAccepted:
            return "You must accept the terms to continue"
        case .nameEmpty:
            return "Please enter your full name"
        }
    }
}
