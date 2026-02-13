//
//  CreateNonNegotiableViewModel.swift
//  LockedIn
//
//  ViewModel for Create Non-Negotiable screen (Screen 6 of 7)
//  Manages non-negotiable creation state
//

import Foundation
import Combine

final class CreateNonNegotiableViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var action: String = ""
    @Published var frequency: String = "Every Day"
    @Published var minimum: String = ""
    
    // MARK: - Output
    var isValid: Bool {
        !action.isEmpty && !minimum.isEmpty
    }
    
    // MARK: - Actions
    func updateAction(_ value: String) {
        action = value
    }
    
    func updateFrequency(_ value: String) {
        frequency = value
    }
    
    func updateMinimum(_ value: String) {
        minimum = value
    }
    
    /// Export data for parent ViewModel
    func exportData() -> (action: String, frequency: String, minimum: String) {
        (action, frequency, minimum)
    }
}
