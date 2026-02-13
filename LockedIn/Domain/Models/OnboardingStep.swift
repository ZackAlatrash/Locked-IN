//
//  OnboardingStep.swift
//  LockedIn
//
//  Typed enum for onboarding navigation
//  Replaces Int-based routing for type safety
//

import Foundation

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case identityWarning = 1
    case failureLoop
    case userHistory
    case coreDifferentiation
    case nonNegotiables
    case createNonNegotiable
    case aiRegulator
    case commitmentAgreement
    
    var id: Int { rawValue }
    
    static var first: OnboardingStep { .identityWarning }
    static var last: OnboardingStep { .commitmentAgreement }
    static var totalCount: Int { allCases.count }
    
    var stepLabel: String {
        String(format: "Step %02d / %02d", rawValue, OnboardingStep.totalCount)
    }
    
    var config: StepConfig {
        StepConfig(for: self)
    }
}

// MARK: - Step Configuration
struct StepConfig {
    let showBackButton: Bool
    let showCloseButton: Bool
    let showHelpButton: Bool
    let showSkipButton: Bool
    let ctaTitle: String
    let ctaSubtitle: String
    
    init(for step: OnboardingStep) {
        switch step {
        case .identityWarning:
            self.showBackButton = false
            self.showCloseButton = true
            self.showHelpButton = true
            self.showSkipButton = false
            self.ctaTitle = "I Understand"
            self.ctaSubtitle = "Proceeding implies absolute commitment"
            
        case .failureLoop:
            self.showBackButton = true
            self.showCloseButton = false
            self.showHelpButton = false
            self.showSkipButton = true
            self.ctaTitle = "Break the cycle"
            self.ctaSubtitle = "Momento Mori"
            
        case .userHistory:
            self.showBackButton = true
            self.showCloseButton = false
            self.showHelpButton = false
            self.showSkipButton = true
            self.ctaTitle = "Continue"
            self.ctaSubtitle = "The Dichotomy of Control"
            
        case .coreDifferentiation:
            self.showBackButton = true
            self.showCloseButton = false
            self.showHelpButton = false
            self.showSkipButton = true
            self.ctaTitle = "I Understand"
            self.ctaSubtitle = "No man is free who is not master of himself"
            
        case .nonNegotiables:
            self.showBackButton = true
            self.showCloseButton = false
            self.showHelpButton = false
            self.showSkipButton = true
            self.ctaTitle = "Continue"
            self.ctaSubtitle = "Locked In: discipline over motivation"
            
        case .createNonNegotiable:
            self.showBackButton = true
            self.showCloseButton = false
            self.showHelpButton = false
            self.showSkipButton = true
            self.ctaTitle = "Lock in"
            self.ctaSubtitle = ""
            
        case .aiRegulator:
            self.showBackButton = true
            self.showCloseButton = false
            self.showHelpButton = false
            self.showSkipButton = false
            self.ctaTitle = "Accept Regulation"
            self.ctaSubtitle = "Authority verified by Locked In protocol"
            
        case .commitmentAgreement:
            self.showBackButton = true
            self.showCloseButton = false
            self.showHelpButton = false
            self.showSkipButton = false
            self.ctaTitle = "Sign & Lock In"
            self.ctaSubtitle = "Your commitment begins now"
        }
    }
}
