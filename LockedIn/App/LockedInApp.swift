//
//  LockedInApp.swift
//  LockedIn
//
//  App configuration helper — integrates with existing Locked_INApp.swift
//  The @main entry point lives in Locked IN/Locked_INApp.swift
//

import SwiftUI

/// Placeholder main app view shown after onboarding completes
struct MainAppView: View {
    var body: some View {
        Text("Welcome to LockedIn")
            .font(.largeTitle)
            .preferredColorScheme(.dark)
    }
}

/// Root view factory for the LockedIn app
/// Used by the existing @main entry point to bootstrap the onboarding flow
struct LockedInAppRoot: View {
    @State private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainAppView()
            } else {
                OnboardingShellView(onComplete: {
                    hasCompletedOnboarding = true
                })
                .preferredColorScheme(.dark)
            }
        }
    }
}
