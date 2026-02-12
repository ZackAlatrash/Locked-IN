//
//  LockedInApp.swift
//  LockedIn
//
//  App configuration helper — integrates with existing Locked_INApp.swift
//  The @main entry point lives in Locked IN/Locked_INApp.swift
//

import SwiftUI

/// Root view factory for the LockedIn app
/// Used by the existing @main entry point to bootstrap the onboarding flow
enum LockedInAppRoot {
    
    /// Creates the root onboarding flow view
    /// - Returns: The onboarding shell view configured with dark mode
    @ViewBuilder
    static func makeRootView() -> some View {
        OnboardingShellView()
            .preferredColorScheme(.dark)
    }
}
