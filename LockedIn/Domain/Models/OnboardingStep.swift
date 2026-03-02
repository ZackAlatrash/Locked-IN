//
//  OnboardingStep.swift
//  LockedIn
//
//  Pure domain enum for onboarding step identity
//  Contains no presentation logic — UI config lives in Features layer
//

import Foundation

enum OnboardingStep: CaseIterable, Identifiable, Equatable {
    case identityWarning
    case failureLoop
    case userHistory
    case coreDifferentiation
    case nonNegotiables
    case aiRegulator
    case commitmentAgreement
    
    var id: String { String(describing: self) }
}
