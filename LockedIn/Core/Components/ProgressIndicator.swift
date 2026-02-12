//
//  ProgressIndicator.swift
//  LockedIn
//
//  Reusable segmented progress indicator component
//  Design sourced from Google Stitch MCP
//
//  Stitch CSS:
//    flex gap-1.5 h-1 w-full
//    flex-1 rounded-full bg-primary shadow-[0_0_10px_rgba(234,42,51,0.5)]
//    flex-1 rounded-full bg-white/10
//

import SwiftUI

struct ProgressIndicator: View {
    let totalSteps: Int
    let currentStep: Int
    /// 0 to 1 — animates the NEXT segment filling (loading effect)
    var animatingProgress: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 6) { // gap-1.5 = 6px
            ForEach(0..<totalSteps, id: \.self) { index in
                if index == currentStep && animatingProgress > 0 {
                    // The segment currently being filled (loading animation)
                    ProgressSegmentAnimating(progress: animatingProgress)
                } else {
                    ProgressSegment(isActive: index < currentStep)
                }
            }
        }
        .frame(height: 4) // h-1 = 4px
    }
}

// MARK: - Progress Segment (Static)
private struct ProgressSegment: View {
    let isActive: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.full) // rounded-full
            .fill(isActive ? Theme.Colors.progressActive : Theme.Colors.progressInactive)
            .frame(height: 4)
            .shadow(
                color: isActive ? Theme.Colors.authority.opacity(0.5) : .clear,
                radius: isActive ? 10 : 0
            )
            .animation(.easeInOut(duration: Theme.Animation.defaultDuration), value: isActive)
    }
}

// MARK: - Progress Segment (Animating — loading fill effect)
private struct ProgressSegmentAnimating: View {
    let progress: CGFloat // 0 to 1
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Inactive background
                RoundedRectangle(cornerRadius: Theme.CornerRadius.full)
                    .fill(Theme.Colors.progressInactive)
                
                // Active fill (animates width from 0 to full)
                RoundedRectangle(cornerRadius: Theme.CornerRadius.full)
                    .fill(Theme.Colors.progressActive)
                    .frame(width: geo.size.width * progress)
                    .shadow(
                        color: Theme.Colors.authority.opacity(0.5),
                        radius: 10
                    )
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Preview
struct ProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Theme.Spacing.xl) {
            ProgressIndicator(totalSteps: 7, currentStep: 1)
            ProgressIndicator(totalSteps: 7, currentStep: 3)
            ProgressIndicator(totalSteps: 7, currentStep: 7)
        }
        .padding()
        .background(Theme.Colors.backgroundPrimary)
        .previewLayout(.sizeThatFits)
    }
}
