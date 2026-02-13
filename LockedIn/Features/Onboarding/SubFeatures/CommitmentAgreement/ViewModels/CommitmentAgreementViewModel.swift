//
//  CommitmentAgreementViewModel.swift
//  LockedIn
//
//  ViewModel for Commitment Agreement screen (Screen 8 of 7)
//  Manages commitment and signature state
//

import Foundation
import Combine

final class CommitmentAgreementViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var hasAcceptedTerms: Bool = false
    @Published var fullName: String = ""
    @Published var showValidationError: Bool = false
    
    // MARK: - Output
    var isValid: Bool {
        hasAcceptedTerms && !fullName.isEmpty
    }
    
    // MARK: - Actions
    func toggleTermsAccepted() {
        hasAcceptedTerms.toggle()
        showValidationError = false
    }
    
    func updateFullName(_ value: String) {
        fullName = value
        showValidationError = false
    }
    
    /// Export data for parent ViewModel
    func exportData() -> (hasAcceptedTerms: Bool, fullName: String) {
        (hasAcceptedTerms, fullName)
    }
}
