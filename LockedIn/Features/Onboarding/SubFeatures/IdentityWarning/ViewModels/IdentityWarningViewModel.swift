//
//  IdentityWarningViewModel.swift
//  LockedIn
//
//  ViewModel for the Identity & Warning onboarding screen (Screen 1 of 7)
//  Design sourced from Google Stitch MCP
//

import Foundation
import Combine

final class IdentityWarningViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var headline: String
    @Published private(set) var highlightedWord: String
    @Published private(set) var bodyText: String
    @Published private(set) var secondaryText: String
    @Published private(set) var ctaTitle: String
    @Published private(set) var ctaSubtitle: String
    @Published private(set) var currentStep: Int
    @Published private(set) var totalSteps: Int
    @Published private(set) var stepLabel: String
    
    // MARK: - Navigation
    private let onContinue: () -> Void
    
    // MARK: - Initialization
    init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
        
        // Screen content — sourced from Google Stitch design
        self.headline = "Locked In is "
        self.highlightedWord = "not"
        self.bodyText = "This app enforces discipline through constraints. It removes flexibility instead of adding motivation."
        self.secondaryText = "If you want streaks, encouragement, or flexibility — this app is not for you."
        self.ctaTitle = "I Understand"
        self.ctaSubtitle = "Proceeding implies absolute commitment"
        self.currentStep = 1
        self.totalSteps = 7
        self.stepLabel = "Step 01 / 07"
    }
    
    // MARK: - Computed Properties
    var headlineSuffix: String {
        " a habit tracker."
    }
    
    // MARK: - Actions
    func didTapContinue() {
        onContinue()
    }
}

