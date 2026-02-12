//
//  FailureLoopViewModel.swift
//  LockedIn
//
//  ViewModel for the Failure Loop onboarding screen (Screen 2 of 7)
//  Design sourced from Google Stitch MCP
//

import Foundation
import Combine

final class FailureLoopViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var headline: String
    @Published private(set) var highlightedWord: String
    @Published private(set) var footerText: String
    @Published private(set) var ctaTitle: String
    @Published private(set) var ctaSubtitle: String
    @Published private(set) var stepLabel: String
    @Published private(set) var currentStep: Int
    @Published private(set) var totalSteps: Int
    @Published private(set) var loopSteps: [LoopStep]
    
    // MARK: - Navigation
    private let onContinue: () -> Void
    private let onBack: (() -> Void)?
    private let onSkip: (() -> Void)?
    
    // MARK: - Loop Step Model
    struct LoopStep: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let isHighlighted: Bool
        let textColor: TextColorStyle
        
        enum TextColorStyle {
            case primary    // white, bold
            case secondary  // gray-400
            case tertiary   // gray-500
        }
    }
    
    // MARK: - Initialization
    init(
        onContinue: @escaping () -> Void,
        onBack: (() -> Void)? = nil,
        onSkip: (() -> Void)? = nil
    ) {
        self.onContinue = onContinue
        self.onBack = onBack
        self.onSkip = onSkip
        
        // Screen content — sourced from Google Stitch design
        self.headline = "Most people fail from "
        self.highlightedWord = "overcommitment"
        self.footerText = "Planning is easy. Follow-through breaks when everything stays optional."
        self.ctaTitle = "Show Me How"
        self.ctaSubtitle = "See how Locked In breaks the cycle"
        self.stepLabel = "Step 02 / 07"
        self.currentStep = 2
        self.totalSteps = 7
        
        // The failure loop steps
        self.loopSteps = [
            LoopStep(icon: "rocket_launch", label: "Ambition", isHighlighted: false, textColor: .secondary),
            LoopStep(icon: "edit_calendar", label: "Overcommitment", isHighlighted: true, textColor: .primary),
            LoopStep(icon: "link_off", label: "Missed day", isHighlighted: false, textColor: .tertiary),
            LoopStep(icon: "sentiment_dissatisfied", label: "Shame", isHighlighted: false, textColor: .tertiary),
            LoopStep(icon: "door_open", label: "Quit", isHighlighted: false, textColor: .tertiary)
        ]
    }
    
    // MARK: - Computed Properties
    var headlineSuffix: String {
        "."
    }
    
    var canGoBack: Bool {
        onBack != nil
    }
    
    var canSkip: Bool {
        onSkip != nil
    }
    
    // MARK: - Actions
    func didTapContinue() {
        onContinue()
    }
    
    func didTapBack() {
        onBack?()
    }
    
    func didTapSkip() {
        onSkip?()
    }
}
