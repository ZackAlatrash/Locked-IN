//
//  NonNegotiablesContentView.swift
//  LockedIn
//
//  Content-only view for Screen 5 (Non-Negotiables)
//  Used inside OnboardingShellView — FULL SCREEN, no header or footer
//  Design sourced from Google Stitch MCP — EXACT MATCH
//

import SwiftUI

struct NonNegotiablesContentView: View {
    
    var body: some View {
        ZStack {
            // Full-screen background
            Theme.Colors.backgroundPrimary
            
            // Background decorative elements
            backgroundDecorations
            
            // Main content
            VStack(spacing: 0) {
                // Space for header overlay
                Spacer().frame(height: 180)
                
                // Content
                VStack(spacing: Theme.Spacing.xl) {
                    // Visual Hero Card - using reusable component
                    NonNegotiableCard(
                        title: "Gym",
                        frequency: "3× per week",
                        lockDurationDays: 28,
                        startDate: Date()
                    )
                    
                    // Instructional Text
                    instructionalText
                }
                .padding(.horizontal, Theme.Spacing.xl)
                
                Spacer()
                
                // Space for CTA button
                Spacer().frame(height: 160)
            }
        }
    }
}

// MARK: - Background Decorations
private extension NonNegotiablesContentView {
    var backgroundDecorations: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                // Top right glow
                Circle()
                    .fill(Theme.Colors.authority.opacity(0.1))
                    .frame(width: 320, height: 320)
                    .blur(radius: 120)
                    .offset(x: width * 0.3, y: -height * 0.1)

                // Bottom left glow
                Circle()
                    .fill(Theme.Colors.authority.opacity(0.05))
                    .frame(width: 384, height: 384)
                    .blur(radius: 150)
                    .offset(x: -width * 0.3, y: height * 0.3)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Instructional Text
private extension NonNegotiablesContentView {
    var instructionalText: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Headline
            VStack(alignment: .leading, spacing: 0) {
                Text("Non-negotiables")
                    .foregroundColor(Theme.Colors.textPrimary)
                Text("cannot be edited.")
                    .foregroundColor(Theme.Colors.authority)
            }
            .font(.system(size: 30, weight: .heavy))
            .tracking(-0.5)
            .lineSpacing(2)
            
            // Body text
            Text("They can only be completed, rescheduled within limits, or violated. Use them for your most critical habits.")
                .font(.system(size: 17))
                .foregroundColor(Theme.Colors.textSecondary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview
struct NonNegotiablesContentView_Previews: PreviewProvider {
    static var previews: some View {
        NonNegotiablesContentView()
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
    }
}
