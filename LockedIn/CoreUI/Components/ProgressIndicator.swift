//
//  ProgressIndicator.swift
//  LockedIn
//
//  Segmented step progress bar — one capsule pill per onboarding step.
//  Segment completion animates with the same spring as the screen transition
//  so both move in perfect sync.
//

import SwiftUI

struct ProgressIndicator: View {
    let totalSteps: Int
    let currentStep: Int
    var activeColor: Color = Theme.Colors.progressActive

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { index in
                ProgressSegmentView(
                    isComplete: index < currentStep,
                    activeColor: activeColor
                )
            }
        }
        .frame(height: 5)
    }
}

// MARK: - Single Segment

private struct ProgressSegmentView: View {
    let isComplete: Bool
    let activeColor: Color

    var body: some View {
        ZStack {
            // Track
            Capsule()
                .fill(Color.white.opacity(0.08))

            // Fill — scales in from leading edge when segment completes
            if isComplete {
                Capsule()
                    .fill(activeColor)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0, anchor: .leading).combined(with: .opacity),
                            removal:   .scale(scale: 0, anchor: .trailing).combined(with: .opacity)
                        )
                    )
                    // Soft glow under active segments
                    .shadow(color: activeColor.opacity(0.45), radius: 5, y: 1)
            }
        }
        .frame(height: 5)
        // Same spring as the screen transition — they animate in lock-step
        .animation(.spring(response: 0.3, dampingFraction: 0.92), value: isComplete)
    }
}

// MARK: - Preview

struct ProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Theme.Spacing.xl) {
            ProgressIndicator(totalSteps: 8, currentStep: 1)
            ProgressIndicator(totalSteps: 8, currentStep: 3)
            ProgressIndicator(totalSteps: 8, currentStep: 6)
            ProgressIndicator(totalSteps: 8, currentStep: 8)
        }
        .padding(Theme.Spacing.xl)
        .background(Color(hex: "#020617"))
        .previewLayout(.sizeThatFits)
    }
}
