//
//  OnboardingStep.swift
//  LockedIn
//
//  Pure domain enum for onboarding step identity
//  Contains no presentation logic — UI config lives in Features layer
//

import Foundation

enum OnboardingStep: CaseIterable, Identifiable, Equatable {
    case welcome
    case identityWarning
    case failureLoop
    case coreDifferentiation
    case commitmentAgreement

    var id: String { String(describing: self) }
}
