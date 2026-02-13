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
struct LockedInAppRoot: View {
    @State private var showPaywall = false
    
    var body: some View {
        Group {
            if showPaywall {
                PaywallContentView()
                    .preferredColorScheme(.dark)
            } else {
                OnboardingShellView(onComplete: {
                    showPaywall = true
                })
                .preferredColorScheme(.dark)
            }
        }
    }
}
