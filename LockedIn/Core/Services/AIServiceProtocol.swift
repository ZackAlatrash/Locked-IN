//
//  AIServiceProtocol.swift
//  LockedIn
//
//  Service boundary for future AI integration
//  Protocol only - no implementation yet
//

import Foundation

/// Protocol for AI-powered features
/// Implementations will handle network calls to AI services
protocol AIServiceProtocol {
    
    /// Parses a natural language description into a structured non-negotiable
    /// - Parameters:
    ///   - text: User's natural language input (e.g., "Work out 3 times a week")
    /// - Returns: Structured non-negotiable components
    func parseNonNegotiable(from text: String) async throws -> NonNegotiableParseResult
    
    /// Explains why a system decision was made
    /// - Parameters:
    ///   - decision: The decision type to explain
    ///   - context: Additional context for the explanation
    /// - Returns: Human-readable explanation
    func explainDecision(_ decision: SystemDecision, context: DecisionContext) async throws -> String
    
    /// Generates personalized coaching message based on user history
    /// - Parameters:
    ///   - history: User's past behavior data
    ///   - currentStep: Current onboarding step
    /// - Returns: Personalized coaching text
    func generateCoachingMessage(for history: UserHistory, at step: OnboardingStep) async throws -> String
}

// MARK: - Result Types

struct NonNegotiableParseResult {
    let action: String
    let frequency: String
    let minimumRequirement: String
    let confidence: Double
}

enum SystemDecision {
    case validationFailed(reason: String)
    case stepGated(step: OnboardingStep)
    case recommendationGenerated
}

struct DecisionContext {
    let userData: OnboardingData
    let currentStep: OnboardingStep
    let additionalInfo: [String: String]
}

struct UserHistory {
    let selectedOption: String?
    let previousAttempts: [String]
    let patterns: [String]
}

// MARK: - Placeholder Implementation (for compilation)

/// Placeholder implementation until real AI service is integrated
final class PlaceholderAIService: AIServiceProtocol {
    func parseNonNegotiable(from text: String) async throws -> NonNegotiableParseResult {
        // Return basic parsing for now
        return NonNegotiableParseResult(
            action: text,
            frequency: "Every Day",
            minimumRequirement: "5 minutes",
            confidence: 0.5
        )
    }
    
    func explainDecision(_ decision: SystemDecision, context: DecisionContext) async throws -> String {
        return "This decision was made based on your onboarding progress."
    }
    
    func generateCoachingMessage(for history: UserHistory, at step: OnboardingStep) async throws -> String {
        return "Stay committed to your goals."
    }
}
