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
    var initialStep: OnboardingStep { .welcome }

    func nextStep(after step: OnboardingStep, data: OnboardingData) -> OnboardingStep? {
        switch step {
        case .welcome:              return .identityWarning
        case .identityWarning:      return .failureLoop
        case .failureLoop:          return .coreDifferentiation
        case .coreDifferentiation:  return .commitmentAgreement
        case .commitmentAgreement:  return nil
        }
    }

    func previousStep(before step: OnboardingStep) -> OnboardingStep? {
        switch step {
        case .welcome:              return nil
        case .identityWarning:      return .welcome
        case .failureLoop:          return .identityWarning
        case .coreDifferentiation:  return .failureLoop
        case .commitmentAgreement:  return .coreDifferentiation
        }
    }

    func skip(from step: OnboardingStep, data: OnboardingData) -> OnboardingStep? {
        switch step {
        case .failureLoop, .coreDifferentiation:
            return .commitmentAgreement
        case .welcome, .identityWarning, .commitmentAgreement:
            return nil
        }
    }
}
