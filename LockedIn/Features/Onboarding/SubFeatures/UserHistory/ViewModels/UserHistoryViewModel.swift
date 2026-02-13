//
//  UserHistoryViewModel.swift
//  LockedIn
//
//  ViewModel for User History screen (Screen 3 of 7)
//  Manages user selection state
//

import Foundation
import Combine

final class UserHistoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedOption: String?
    
    // MARK: - Output
    var isValid: Bool {
        selectedOption != nil
    }
    
    // MARK: - Actions
    func selectOption(_ option: String) {
        selectedOption = option
    }
    
    /// Export data for parent ViewModel
    func exportData() -> String? {
        selectedOption
    }
}
