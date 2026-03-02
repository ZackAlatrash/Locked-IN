//
//  OnboardingData.swift
//  LockedIn
//
//  Shared state container for onboarding data
//  Passed between screens via dependency injection
//

import Foundation

enum NonNegotiableFrequency: CaseIterable, Equatable {
    case daily
    case weekdays
    case weekends
    case custom
}

/// Container for all onboarding data collected across screens
struct OnboardingData {
    // MARK: - Screen 3: User History
    var selectedUserHistoryOption: String?
    
    // MARK: - Screen 6: Create Non-Negotiable
    var nonNegotiableAction: String = ""
    var nonNegotiableFrequency: NonNegotiableFrequency = .daily
    var nonNegotiableMinimum: String = ""
    
    // MARK: - Screen 8: Commitment Agreement
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
    case userHistoryNotSelected
    case nonNegotiableIncomplete
    case termsNotAccepted
    case nameEmpty
}
